import 'dart:async';
import 'dart:convert';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;
  final RTCVideoRenderer remoteRenderer;

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get robotId => AppConfig.robotId;

  StreamSubscription? _signalingSubscription;
  bool _isDisposed = false;
  
  // --- HEARTBEAT & STATS ---
  Timer? _heartbeatTimer;
  Timer? _statsTimer;
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  final Set<String> _processedCandidates = {};

  Future<void> connect() async {
    if (_isDisposed) return;

    // 1. Peer Connection Configuration (Metered.ca para acesso remoto)
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.relay.metered.ca:80"},
        {
          "urls": [
            "turn:global.relay.metered.ca:80",
            "turn:global.relay.metered.ca:443",
            "turn:global.relay.metered.ca:443?transport=tcp",
            "turns:global.relay.metered.ca:443?transport=tcp"
          ],
          "username": "aaaaa",
          "password": "aaaaa",
        },
      ],
      "sdpSemantics": "unified-plan",
      "iceCandidatePoolSize": 10,
    };

    _peerConnection = await createPeerConnection(configuration);

    // 2. Setup DataChannel
    RTCDataChannelInit dcInit = RTCDataChannelInit()
      ..ordered = false
      ..maxRetransmits = 0;

    _dataChannel = await _peerConnection!.createDataChannel("commands", dcInit);

    // Gerir Heartbeat conforme o estado do canal
    _dataChannel!.onDataChannelState = (state) {
      debugPrint("DataChannel State: $state");
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _startHeartbeat();
      } else {
        _heartbeatTimer?.cancel();
      }
    };

    // 3. Handle Remote Video Track
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && !_isDisposed) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    // 4. Handle ICE Candidates
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate.candidate != null) {
        _db.collection('robots').doc(robotId).update({
          'app_candidates': FieldValue.arrayUnion([
            {
              'candidate': candidate.candidate,
              'sdpMid': candidate.sdpMid ?? "0",
              'sdpMLineIndex': candidate.sdpMLineIndex ?? 0,
            },
          ]),
        });
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint("WebRTC Connection State: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _startStatsCollection();
      }
    };

    // 5. Create WebRTC Offer
    // Adicionamos transceivers para garantir o recebimento de vídeo
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    RTCSessionDescription offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    // 6. Push Offer to Firestore
    final userEmail = _authService.currentUser?.email ?? "unknown";
    
    try {
      final docRef = _db.collection('robots').doc(robotId);
      
      await docRef.update({
        'webrtc_session': {
          'offer': {'sdp': offer.sdp, 'type': offer.type},
          'answer': null,
        },
        'control.last_handshake_email': userEmail,
        'app_candidates': [], 
        'robot_candidates': [],
        'last_handshake': FieldValue.serverTimestamp(),
      });
      debugPrint("DEBUG: Offer publicada para $userEmail");
    } catch (e) {
      debugPrint("DEBUG ERROR: Falha ao publicar offer: $e");
    }
    
    // 7. Listen for Answer and ICE Candidates
    _signalingSubscription = _db
        .collection('robots')
        .doc(robotId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists || _isDisposed) return;
          final data = snapshot.data()!;

          final session = data['webrtc_session'];
          if (session != null &&
              session['answer'] != null &&
              _peerConnection?.getRemoteDescription() == null) {
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                session['answer']['sdp'],
                session['answer']['type'],
              ),
            );
          }

          final List? robotCandidates = data['robot_candidates'];
          if (robotCandidates != null && robotCandidates.isNotEmpty) {
            for (var c in robotCandidates) {
              String candidateStr = c['candidate'];
              if (!_processedCandidates.contains(candidateStr)) {
                await _peerConnection!.addCandidate(
                  RTCIceCandidate(
                    candidateStr,
                    c['sdpMid'],
                    c['sdpMLineIndex'],
                  ),
                );
                _processedCandidates.add(candidateStr);
              }
            }
          }
        });
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (isConnected && !_isDisposed) {
        sendJoystick(0.0, 0.0);
      } else {
        timer.cancel();
      }
    });
  }

  void sendJoystick(double x, double y) {
    if (isConnected && !_isDisposed) {
      final String msg = jsonEncode({
        "x": double.parse(x.toStringAsFixed(2)),
        "y": double.parse(y.toStringAsFixed(2)),
      });
      try {
        _dataChannel!.send(RTCDataChannelMessage(msg));
      } catch (e) {
        debugPrint("Erro DataChannel: $e");
      }
    }
  }

  void _startStatsCollection() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed || _peerConnection == null) return;
      try {
        final stats = await _peerConnection!.getStats();
        double? frameRate;
        int? frameWidth;
        int? frameHeight;
        double? jitterMs;
        double? packetsLostPercent;

        for (final report in stats) {
          if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
            final fps = report.values['framesPerSecond'];
            if (fps != null) frameRate = (fps as num).toDouble();

            final width = report.values['frameWidth'];
            final height = report.values['frameHeight'];
            if (width != null) frameWidth = (width as num).toInt();
            if (height != null) frameHeight = (height as num).toInt();

            final jitter = report.values['jitter'];
            if (jitter != null) jitterMs = (jitter as num).toDouble() * 1000;

            final lost = report.values['packetsLost'];
            final received = report.values['packetsReceived'];
            if (lost != null && received != null) {
              final total = (received as num).toDouble() + (lost as num).toDouble();
              packetsLostPercent = total > 0 ? ((lost as num) / total * 100) : 0.0;
            }
          }
        }

        if (!_statsController.isClosed) {
          _statsController.add({
            'frameRate': frameRate != null ? '${frameRate.toStringAsFixed(1)} fps' : '---',
            'resolution': (frameWidth != null && frameHeight != null) ? '${frameWidth}x${frameHeight}' : '---',
            'latency': jitterMs != null ? '${jitterMs.toStringAsFixed(0)} ms' : '---',
            'packetLoss': packetsLostPercent != null ? '${packetsLostPercent.toStringAsFixed(1)}%' : '---',
          });
        }
      } catch (e) {
        debugPrint("WebRTC Stats error: $e");
      }
    });
  }

  void dispose() {
    _isDisposed = true;
    _heartbeatTimer?.cancel();
    _statsTimer?.cancel();
    _signalingSubscription?.cancel();
    _dataChannel?.close();
    _peerConnection?.dispose();
    if (!_statsController.isClosed) _statsController.close();
    remoteRenderer.srcObject = null;
    _processedCandidates.clear();
  }
}