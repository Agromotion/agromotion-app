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

  Timer? _sendLoop;
  double? _pendingX;
  double? _pendingY;
  double? _pendingDrum;

  String get robotId => AppConfig.robotId;
  String? get userEmail => _authService.currentUser?.email;

  StreamSubscription? _signalingSubscription;
  bool _isDisposed = false;
  bool _answerSet = false;
  bool _isConnecting = false;

  Timer? _heartbeatTimer;
  Timer? _statsTimer;
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  final Set<String> _processedCandidates = {};
  final List<RTCIceCandidate> _pendingRobotCandidates = [];

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;

  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  void _startSendLoop() {
    _sendLoop ??= Timer.periodic(const Duration(milliseconds: 30), (_) {
      if (!isConnected || _dataChannel == null) return;

      if (_pendingX == null && _pendingY == null && _pendingDrum == null) {
        return;
      }

      try {
        if (_pendingDrum != null) {
          _dataChannel!.send(RTCDataChannelMessage(jsonEncode({
            "drum": _pendingDrum,
          })));
          _pendingDrum = null;
          return;
        }

        if (_pendingX != null || _pendingY != null) {
          _dataChannel!.send(RTCDataChannelMessage(jsonEncode({
            "x": double.parse((_pendingX ?? 0).toStringAsFixed(2)),
            "y": double.parse((_pendingY ?? 0).toStringAsFixed(2)),
          })));

          _pendingX = null;
          _pendingY = null;
        }
      } catch (e) {
        debugPrint("[DataChannel] send loop error: $e");
      }
    });
  }

  Future<void> connect() async {
    debugPrint("TESTE NOVO WEBRTC SERVICE 123");
    if (_isDisposed || _isConnecting || isConnected) return;

    _isConnecting = true;
    _answerSet = false;
    _processedCandidates.clear();
    _pendingRobotCandidates.clear();

    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
        {"urls": "stun:openrelay.metered.ca:80"},
        {
          "urls": [
            "turn:openrelay.metered.ca:80",
            "turn:openrelay.metered.ca:443",
            "turn:openrelay.metered.ca:443?transport=tcp"
          ],
          "username": "openrelayproject",
          "credential": "openrelayproject"
        }
      ],
      "sdpSemantics": "unified-plan",
      "iceCandidatePoolSize": 10,
      "iceTransportPolicy": "all"
    };

    try {
      _peerConnection = await createPeerConnection(configuration);

      RTCDataChannelInit dcInit = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 0;

      _dataChannel =
          await _peerConnection!.createDataChannel("commands", dcInit);

      _peerConnection!.onTrack = (event) {
        debugPrint("[WebRTC] Track de video recebida do robo");
        if (event.track.kind == 'video' && !_isDisposed) {
          remoteRenderer.srcObject = event.streams[0];
        }
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint("[WebRTC] Connection State alterado para: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _requestControl();
          _startStatsCollection();
        }
      };

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

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      final offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);

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

      debugPrint("[WebRTC] Offer publicada com sucesso no Firestore");

      _signalingSubscription = _db
          .collection('robots')
          .doc(robotId)
          .snapshots()
          .listen((snapshot) async {
        if (!snapshot.exists || _isDisposed) return;

        final data = snapshot.data()!;
        final session = data['webrtc_session'];

        if (session != null && session['answer'] != null && !_answerSet) {
          _answerSet = true;
          debugPrint("[WebRTC] Answer do robo detetada");

          try {
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                session['answer']['sdp'],
                session['answer']['type'],
              ),
            );

            debugPrint("[WebRTC] RemoteDescription definida");
            await _flushPendingRobotCandidates();
          } catch (e) {
            debugPrint("[WebRTC] Erro ao aplicar RemoteDescription: $e");
            _answerSet = false;
          }
        }

        final List? robotCandidates = data['robot_candidates'];
        if (robotCandidates != null) {
          for (var c in robotCandidates) {
            String candidateStr = c['candidate'] ?? '';

            if (candidateStr.isNotEmpty &&
                !_processedCandidates.contains(candidateStr)) {
              _processedCandidates.add(candidateStr);

              RTCIceCandidate iceCandidate = RTCIceCandidate(
                candidateStr,
                c['sdpMid'] ?? '0',
                c['sdpMLineIndex'] ?? 0,
              );

              if (_answerSet &&
                  _peerConnection?.getRemoteDescription() != null) {
                await _peerConnection!.addCandidate(iceCandidate);
              } else {
                _pendingRobotCandidates.add(iceCandidate);
              }
            }
          }
        }
      });
    } catch (e) {
      debugPrint("[WebRTC] Erro na conexao: $e");
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> _flushPendingRobotCandidates() async {
    if (_pendingRobotCandidates.isEmpty) return;

    debugPrint(
      "[WebRTC] A inserir ${_pendingRobotCandidates.length} candidatos pendentes",
    );

    for (var candidate in _pendingRobotCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        debugPrint("[WebRTC] Erro ao inserir candidato pendente: $e");
      }
    }

    _pendingRobotCandidates.clear();
  }

  void _requestControl() {
    debugPrint("[WebRTC] Controlo obtido. Conexao WebRTC operacional");
  }

  void sendJoystick(double x, double y) {
    _pendingX = x;
    _pendingY = y;

    if (_sendLoop == null) {
      _startSendLoop();
    }
  }

  void sendDrum(double value) {
    _pendingDrum = value;

    if (_sendLoop == null) {
      _startSendLoop();
    }
  }

  void _startStatsCollection() {
    _statsTimer?.cancel();

    _statsTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isDisposed || _peerConnection == null) return;

      try {
        final stats = await _peerConnection!.getStats();

        double? fps;
        double? jitter;
        double? loss;
        int? w;
        int? h;

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

            if (received + lost > 0) {
              loss = (lost / (received + lost)) * 100;
            }
          }
        }

        if (!_statsController.isClosed) {
          _statsController.add({
            'frameRate': fps != null ? '${fps.toStringAsFixed(1)} fps' : '---',
            'resolution': (w != null && h != null) ? '${w}x$h' : '---',
            'latency':
                jitter != null ? '${(jitter * 1000).toStringAsFixed(0)} ms' : '---',
            'packetLoss':
                loss != null ? '${loss.toStringAsFixed(1)}%' : '---',
          });
        }
      } catch (e) {
        debugPrint("[WebRTC] Stats error: $e");
      }
    });
  }

  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _isConnecting = false;

    _heartbeatTimer?.cancel();
    _statsTimer?.cancel();
    _sendLoop?.cancel();
    _signalingSubscription?.cancel();

    _dataChannel?.close();
    _peerConnection?.dispose();

    if (!_statsController.isClosed) {
      _statsController.close();
    }

    remoteRenderer.srcObject = null;
    _processedCandidates.clear();
    _pendingRobotCandidates.clear();

    debugPrint("[WebRTCService] Recursos libertados com sucesso");
  }
}