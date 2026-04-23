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
  // Instância do AuthService para aceder ao user de forma correta
  final AuthService _authService = AuthService();

  String get robotId => AppConfig.robotId;

  StreamSubscription? _signalingSubscription;
  bool _isDisposed = false;
  bool _isConnecting = false;
  bool _offerPublished = false;
  bool _remoteDescriptionSet = false;

  bool get isConnected =>
      _dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen;
  bool get isDisposed => _isDisposed;

  WebRTCService({required this.remoteRenderer});

  final Set<String> _processedCandidates = {};

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
          // CHAMADA DA FUNÇÃO: Quando conecta, pede controlo ou entra na fila
          _requestControl();
        }
      };

      final offer = await _peerConnection!.createOffer({
        'mandatory': {
          'OfferToReceiveVideo': true,
          'OfferToReceiveAudio': false,
        },
        'optional': [],
      });
      await _peerConnection!.setLocalDescription(offer);

      debugPrint("DEBUG: A iniciar handshake com Robô ID: '$robotId'");

      // FIX 1: Acesso correto ao currentUser (removido erro static access)
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

  // FIX 2: Implementada lógica de Transação para a fila FIFO
  Future<void> _requestControl() async {
    final userEmail = _authService.currentUser?.email;
    if (userEmail == null) return;

    final docRef = _db.collection('robots').doc(robotId);

    try {
      await _db.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
        // Aceder corretamente ao mapa aninhado 'control'
        Map<String, dynamic> control = data['control'] ?? {};
        List queue = control['viewer_queue'] ?? [];

        if (!queue.contains(userEmail)) {
          transaction.update(docRef, {
            'control.viewer_queue': FieldValue.arrayUnion([userEmail]),
            'status.video_client_count': FieldValue.increment(1),
          });
          queue.add(userEmail);
        }

        if (queue.isNotEmpty && queue.first == userEmail) {
          transaction.update(docRef, {
            'control.active_controller_email': userEmail,
          });
        }
      });
      debugPrint("WebRTC: Pedido de controlo/fila processado.");
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
  }
}
