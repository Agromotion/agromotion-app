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
  MediaStream? get remoteStream => remoteRenderer.srcObject;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  String get robotId => AppConfig.robotId;
  // Resolve o erro do userEmail pegando do AuthService
  String? get userEmail => _authService.currentUser?.email;

  StreamSubscription? _signalingSubscription;
  bool _isDisposed = false;

  // Heartbeat e Stats
  Timer? _heartbeatTimer;
  Timer? _statsTimer;
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  final Set<String> _processedCandidates = {};

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  Future<void> connect() async {
    if (_isDisposed) return;

    // 1. Configuração ICE Servers
    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.relay.metered.ca:80"},
        {
          "urls": [
            "turn:global.relay.metered.ca:80",
            "turn:global.relay.metered.ca:443",
            "turn:global.relay.metered.ca:443?transport=tcp",
            "turns:global.relay.metered.ca:443?transport=tcp",
          ],
          "username": "9d0023ef27dece71a035b9a1",
          "password": "6UHvICJX+38sLhye",
        },
      ],
      "sdpSemantics": "unified-plan",
      "iceCandidatePoolSize": 10,
    };

    _peerConnection = await createPeerConnection(configuration);

    // 2. Setup DataChannel (Baixa latência para comandos)
    RTCDataChannelInit dcInit = RTCDataChannelInit()
      ..ordered = false
      ..maxRetransmits = 0;

    _dataChannel = await _peerConnection!.createDataChannel("commands", dcInit);

    // 3. Handlers de Track e Connection State
    _peerConnection!.onTrack = (event) {
      if (event.track.kind == 'video' && !_isDisposed) {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint("WebRTC Connection State: $state");
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _requestControl();
        _startStatsCollection();
      }
    };

    // 4. Handle ICE Candidates (App -> Robot)
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

    // 5. Preparar Transceiver para Vídeo
    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    // 6. Criar e Publicar Offer
    final offer = await _peerConnection!.createOffer({});
    await _peerConnection!.setLocalDescription(offer);

    try {
      final docRef = _db.collection('robots').doc(robotId);

      await docRef.update({
        'webrtc_session': {
          'offer': {'sdp': offer.sdp, 'type': offer.type},
          'answer': null,
        },
        'control.last_handshake_email': userEmail ?? 'unknown',
        'app_candidates': [],
        'robot_candidates': [],
        'last_handshake': FieldValue.serverTimestamp(),
      });
      debugPrint("DEBUG: Offer escrita no Firestore.");
    } catch (e) {
      debugPrint("DEBUG ERROR: Erro ao escrever no Firebase: $e");
    }

    // 7. Ouvir Answer e Candidates do Robô
    _signalingSubscription = _db
        .collection('robots')
        .doc(robotId)
        .snapshots()
        .listen((snapshot) async {
          if (!snapshot.exists || _isDisposed) return;
          final data = snapshot.data()!;

          // Processar Answer
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

          // Processar Candidates do Robô
          final List? robotCandidates = data['robot_candidates'];
          if (robotCandidates != null) {
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

  void _requestControl() {
    // Implementação da lógica de pedido de controle se necessário
    debugPrint("Solicitando controle do robô...");
  }

  void sendJoystick(double x, double y) {
    if (isConnected && !_isDisposed) {
      final msg = jsonEncode({
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

  void sendDrum(double value) {
    if (isConnected && !_isDisposed) {
      final msg = jsonEncode({
        "drum": value,
      });
      try {
        _dataChannel!.send(RTCDataChannelMessage(msg));
      } catch (e) {
        debugPrint("Erro Drum: $e");
      }
    }
  }

  void _startStatsCollection() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed || _peerConnection == null) return;
      try {
        final stats = await _peerConnection!.getStats();
        double? fps, jitter, loss;
        int? w, h;

        for (final report in stats) {
          if (report.type == 'inbound-rtp' &&
              report.values['kind'] == 'video') {
            fps = (report.values['framesPerSecond'] as num?)?.toDouble();
            w = (report.values['frameWidth'] as num?)?.toInt();
            h = (report.values['frameHeight'] as num?)?.toInt();
            jitter = (report.values['jitter'] as num?)?.toDouble();

            final lost =
                (report.values['packetsLost'] as num?)?.toDouble() ?? 0;
            final received =
                (report.values['packetsReceived'] as num?)?.toDouble() ?? 0;
            if (received + lost > 0) loss = (lost / (received + lost)) * 100;
          }
        }

        if (!_statsController.isClosed) {
          _statsController.add({
            'frameRate': fps != null ? '${fps.toStringAsFixed(1)} fps' : '---',
            'resolution': (w != null && h != null) ? '${w}x${h}' : '---',
            'latency': jitter != null
                ? '${(jitter * 1000).toStringAsFixed(0)} ms'
                : '---',
            'packetLoss': loss != null ? '${loss.toStringAsFixed(1)}%' : '---',
          });
        }
      } catch (e) {
        debugPrint("Stats error: $e");
      }
    });
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;

    _heartbeatTimer?.cancel();
    _statsTimer?.cancel();
    _signalingSubscription?.cancel();

    _dataChannel?.close();
    _peerConnection?.dispose();

    if (!_statsController.isClosed) _statsController.close();
    remoteRenderer.srcObject = null;
    _processedCandidates.clear();

    debugPrint("WebRTCService Disposed.");
  }
}
