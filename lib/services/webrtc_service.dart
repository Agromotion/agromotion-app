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
  bool _isConnecting = false;
  bool _offerPublished = false;
  bool _remoteDescriptionSet = false;
  MediaStream? get remoteStream => remoteRenderer.srcObject;

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  final Set<String> _processedCandidates = {};

  Timer? _statsTimer;
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  Future<void> connect() async {
    if (_isDisposed || _isConnecting) return;
    _isConnecting = true;

    try {
      await _cleanup();

      _processedCandidates.clear();
      _remoteDescriptionSet = false;
      _offerPublished = false;

      final configuration = {
        "iceServers": [
          {"urls": "stun:stun.l.google.com:19302"},
          {
            "urls": "turn:openrelay.metered.ca:80",
            "username": "openrelayproject",
            "credential": "openrelayproject",
          },
          {
            "urls": "turn:openrelay.metered.ca:443",
            "username": "openrelayproject",
            "credential": "openrelayproject",
          },
        ],
        "sdpSemantics": "unified-plan",
      };

      _peerConnection = await createPeerConnection(configuration);

      final dcInit = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 0;
      _dataChannel = await _peerConnection!.createDataChannel(
        "commands",
        dcInit,
      );

      _peerConnection!.onTrack = (event) {
        if (event.track.kind == 'video' && !_isDisposed) {
          remoteRenderer.srcObject = event.streams[0];
        }
      };

      _peerConnection!.onIceCandidate = (candidate) {
        if (!_offerPublished) return;
        if (candidate.candidate != null && candidate.candidate!.isNotEmpty) {
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

      // Listener para o estado da conexão para disparar o pedido de controlo/fila
      _peerConnection!.onConnectionState = (state) {
        debugPrint("WebRTC Connection State: $state");
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          // Quando conecta, pede controlo ou entra na fila
          _requestControl();
          _startStatsCollection();
        }
      };

      await _peerConnection!.addTransceiver(
        kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
        init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
      );

      final offer = await _peerConnection!.createOffer({});
      await _peerConnection!.setLocalDescription(offer);

      debugPrint("DEBUG: A iniciar handshake com Robô ID: '$robotId'");

      final userEmail = _authService.currentUser?.email;

      await _db.collection('robots').doc(robotId).update({
        'webrtc_session': {
          'offer': {'sdp': offer.sdp, 'type': offer.type},
          'answer': null,
        },
        'control.last_handshake_email': userEmail,
        'app_candidates': [],
        'robot_candidates': [],
        'last_handshake': FieldValue.serverTimestamp(),
      });

      _offerPublished = true;

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
                !_remoteDescriptionSet) {
              try {
                await _peerConnection!.setRemoteDescription(
                  RTCSessionDescription(
                    session['answer']['sdp'],
                    session['answer']['type'],
                  ),
                );
                _remoteDescriptionSet = true;
                debugPrint("WebRTC: ✓ Answer do robô aplicada com sucesso.");
              } catch (e) {
                debugPrint("WebRTC ERROR: Falha ao aplicar Answer: $e");
              }
            }

            final List? robotCandidates = data['robot_candidates'];
            if (_remoteDescriptionSet &&
                robotCandidates != null &&
                robotCandidates.isNotEmpty) {
              for (var c in robotCandidates) {
                final String candidateStr = c['candidate'] ?? '';
                if (candidateStr.isEmpty) continue;

                if (!_processedCandidates.contains(candidateStr)) {
                  _processedCandidates.add(candidateStr);
                  try {
                    await _peerConnection!.addCandidate(
                      RTCIceCandidate(
                        candidateStr,
                        c['sdpMid'] ?? "0",
                        c['sdpMLineIndex'] ?? 0,
                      ),
                    );
                  } catch (e) {
                    debugPrint(
                      "WebRTC ERROR: Falha ao adicionar candidato: $e",
                    );
                  }
                }
              }
            }
          });
    } finally {
      _isConnecting = false;
    }
  }

  // Implementada lógica de Transação para a fila FIFO
  Future<void> _requestControl() async {
    final userEmail = _authService.currentUser?.email;
    if (userEmail == null) return;

    final docRef = _db.collection('robots').doc(robotId);

    try {
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        // Apenas adicionamos à fila. NÃO alteramos o active_controller_email na App.
        transaction.update(docRef, {
          'control.viewer_queue': FieldValue.arrayUnion([userEmail]),
          'status.video_client_count': FieldValue.increment(1),
        });
      });
      debugPrint("WebRTC: Adicionado à fila de espera.");
    } catch (e) {
      debugPrint("WebRTC Error Transaction: $e");
    }
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
        debugPrint("Erro ao enviar via DataChannel: $e");
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
          // Inbound RTP — vídeo recebido
          if (report.type == 'inbound-rtp' &&
              report.values['kind'] == 'video') {
            final framesDecoded = report.values['framesDecoded'];
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
              final total =
                  (received as num).toDouble() + (lost as num).toDouble();
              packetsLostPercent = total > 0
                  ? ((lost as num) / total * 100)
                  : 0.0;
            }
          }
        }

        if (!_statsController.isClosed) {
          _statsController.add({
            'frameRate': frameRate != null
                ? '${frameRate.toStringAsFixed(1)} fps'
                : '---',
            'resolution': (frameWidth != null && frameHeight != null)
                ? '${frameWidth}x${frameHeight}'
                : '---',
            'latency': jitterMs != null
                ? '${jitterMs.toStringAsFixed(0)} ms'
                : '---',
            'packetLoss': packetsLostPercent != null
                ? '${packetsLostPercent.toStringAsFixed(1)}%'
                : '---',
          });
        }
      } catch (e) {
        debugPrint("WebRTC Stats error: $e");
      }
    });
  }

  Future<void> _cleanup() async {
    _signalingSubscription?.cancel();
    _signalingSubscription = null;
    _dataChannel?.close();
    _dataChannel = null;
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    remoteRenderer.srcObject = null;
    _processedCandidates.clear();
    _statsTimer?.cancel();
    _statsTimer = null;
    if (!_statsController.isClosed) _statsController.close();
  }

  void dispose() {
    _isDisposed = true;
    _remoteDescriptionSet = false;
    _offerPublished = false;
    _signalingSubscription?.cancel();
    _dataChannel?.close();
    _peerConnection?.dispose();
    remoteRenderer.srcObject = null;
    _processedCandidates.clear();
    _statsTimer?.cancel();
    _statsTimer = null;
    if (!_statsController.isClosed) _statsController.close();
  }
}
