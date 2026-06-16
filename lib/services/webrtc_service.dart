import 'dart:async';
import 'dart:convert';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/utils/app_logger.dart';
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
          _dataChannel!.send(
            RTCDataChannelMessage(jsonEncode({"drum": _pendingDrum})),
          );
          _pendingDrum = null;
          return;
        }

        if (_pendingX != null || _pendingY != null) {
          _dataChannel!.send(
            RTCDataChannelMessage(
              jsonEncode({
                "x": double.parse((_pendingX ?? 0).toStringAsFixed(2)),
                "y": double.parse((_pendingY ?? 0).toStringAsFixed(2)),
              }),
            ),
          );

          _pendingX = null;
          _pendingY = null;
        }
      } catch (e) {
        AppLogger.error("[DataChannel] send loop error", e);
      }
    });
  }

  /// Liga ao robô e só termina quando a PeerConnection chegar a
  /// RTCPeerConnectionStateConnected, falhar, ou expirar o timeout interno.
  /// Em caso de falha, lança uma excepção (em vez de engolir o erro), para
  /// que o chamador (CameraScreen) saiba mesmo que precisa de tentar de novo.
  Future<void> connect() async {
    AppLogger.info("A INICIAR WEBRTC SERVICE...");
    if (_isDisposed || _isConnecting || isConnected) return;

    _isConnecting = true;
    _answerSet = false;
    _processedCandidates.clear();
    _pendingRobotCandidates.clear();

    // Completer que só resolve quando a ligação P2P está mesmo operacional
    // (ou falha/expira). É isto que dá significado real ao timeout externo.
    final completer = Completer<void>();

    Map<String, dynamic> configuration = {
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
        {"urls": "stun:stun1.l.google.com:19302"},
        {"urls": "stun:openrelay.metered.ca:80"},
        {
          "urls": [
            "turn:openrelay.metered.ca:80",
            "turn:openrelay.metered.ca:443",
            "turn:openrelay.metered.ca:443?transport=tcp",
          ],
          "username": "openrelayproject",
          "credential": "openrelayproject",
        },
      ],
      "sdpSemantics": "unified-plan",
      "iceCandidatePoolSize": 10,
      "iceTransportPolicy": "all",
    };

    try {
      _peerConnection = await createPeerConnection(configuration);

      RTCDataChannelInit dcInit = RTCDataChannelInit()
        ..ordered = false
        ..maxRetransmits = 0;

      _dataChannel = await _peerConnection!.createDataChannel(
        "commands",
        dcInit,
      );

      _peerConnection!.onTrack = (event) async {
        debugPrint("[WebRTC] Track de video recebida do robo");
        if (event.track.kind == 'video' && !_isDisposed) {
          if (event.streams.isNotEmpty) {
            remoteRenderer.srcObject = event.streams[0];
          } else {
            // Fallback obrigatório para Web, onde event.streams ocasionalmente vem vazio
            debugPrint(
              "[WebRTC] event.streams vazio. A aplicar fallback stream.",
            );
            final fallbackStream =
                remoteRenderer.srcObject ??
                await createLocalMediaStream('remote_video_fallback');
            fallbackStream.addTrack(event.track);
            remoteRenderer.srcObject =
                fallbackStream; // Reatribuir força o renderer Web a atualizar a tag <video>
          }
        }
      };

      _peerConnection!.onConnectionState = (state) {
        if (_isDisposed) return;

        AppLogger.info("[WebRTC] Connection State alterado para: $state");

        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _requestControl();
          _startStatsCollection();
          // Só importa na primeira vez (handshake inicial). Reconexões
          // posteriores ao mesmo estado não afetam um completer já resolvido.
          if (!completer.isCompleted) completer.complete();
        } else if (state ==
                RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          AppLogger.warning("[WebRTC] Conexão perdida: $state");
          _cleanupFirebaseSession();
          // Se isto aconteceu ANTES de alguma vez chegarmos a Connected,
          // o connect() deve falhar em vez de ficar pendurado para sempre.
          if (!completer.isCompleted) {
            completer.completeError(
              Exception('Ligação WebRTC falhou durante o handshake: $state'),
            );
          }
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

      final docRef = _db.collection('robots').doc(robotId);
      final viewerRef = docRef
          .collection('viewers')
          .doc(userEmail ?? 'unknown');

      // 1. Limpar candidatos antigos ANTES de gerar a nova offer para evitar race conditions.
      await viewerRef.set({
        'app_candidates': [],
        'robot_candidates': [],
        'last_handshake': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Criar offer e definir local description (inicia a recolha de ICE candidates imediatamente)
      final offer = await _peerConnection!.createOffer({
        'offerToReceiveVideo': 1,
      });
      await _peerConnection!.setLocalDescription(offer);

      // 3. Atualizar a nova offer e o email em simultâneo para o robô processar a ligação
      await viewerRef.update({
        'webrtc_session': {
          'offer': {'sdp': offer.sdp, 'type': offer.type},
          'answer': null,
        },
      });

      AppLogger.info("[WebRTC] Offer publicada com sucesso no Firestore");

      _signalingSubscription = viewerRef.snapshots().listen((snapshot) async {
        if (!snapshot.exists || _isDisposed) return;

        final data = snapshot.data()!;
        final session = data['webrtc_session'];

        if (session != null && session['answer'] != null && !_answerSet) {
          _answerSet = true;
          AppLogger.info("[WebRTC] Answer do robô detetada");

          try {
            await _peerConnection!.setRemoteDescription(
              RTCSessionDescription(
                session['answer']['sdp'],
                session['answer']['type'],
              ),
            );

            AppLogger.info("[WebRTC] RemoteDescription definida");
            await _flushPendingRobotCandidates();
          } catch (e) {
            AppLogger.error("[WebRTC] Erro ao aplicar RemoteDescription", e);
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

      // Só agora esperamos mesmo pela ligação ficar operacional.
      // Isto é o que dá significado real ao timeout: antes, o Future de
      // connect() resolvia logo após publicar a offer, sem nunca confirmar
      // que a ligação P2P chegou a existir.
      await completer.future.timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
            'Timeout a aguardar ligação WebRTC (15s sem Connected)',
          );
        },
      );

      AppLogger.info("[WebRTC] Ligação estabelecida com sucesso");
    } catch (e, stackTrace) {
      AppLogger.error("[WebRTC] Erro na conexão", e);
      await _teardownAfterFailedAttempt();
      // Propaga o erro: sem isto, quem chama connect() nunca sabe que falhou.
      Error.throwWithStackTrace(e, stackTrace);
    } finally {
      _isConnecting = false;
    }
  }

  /// Limpa tudo o que foi criado nesta tentativa falhada, para que a
  /// próxima chamada a connect() comece de um estado limpo (sem timers,
  /// subscriptions ou PeerConnections "zombie" presos em memória).
  Future<void> _teardownAfterFailedAttempt() async {
    try {
      await _signalingSubscription?.cancel();
    } catch (_) {}
    _signalingSubscription = null;

    try {
      _dataChannel?.close();
    } catch (_) {}
    _dataChannel = null;

    try {
      await _peerConnection?.close();
    } catch (_) {}
    try {
      _peerConnection?.dispose();
    } catch (_) {}
    _peerConnection = null;

    _statsTimer?.cancel();
    _statsTimer = null;

    _answerSet = false;
    _processedCandidates.clear();
    _pendingRobotCandidates.clear();

    try {
      if (userEmail != null) {
        await _db
            .collection('robots')
            .doc(robotId)
            .collection('viewers')
            .doc(userEmail)
            .delete();
      }
    } catch (_) {}
  }

  Future<void> _flushPendingRobotCandidates() async {
    if (_pendingRobotCandidates.isEmpty) return;

    AppLogger.info(
      "[WebRTC] A inserir ${_pendingRobotCandidates.length} candidatos pendentes",
    );

    for (var candidate in _pendingRobotCandidates) {
      try {
        await _peerConnection!.addCandidate(candidate);
      } catch (e) {
        AppLogger.error("[WebRTC] Erro ao inserir candidato pendente", e);
      }
    }

    _pendingRobotCandidates.clear();
  }

  void _requestControl() {
    AppLogger.info("[WebRTC] Controlo obtido. Conexão WebRTC operacional");
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
            'latency': jitter != null
                ? '${(jitter * 1000).toStringAsFixed(0)} ms'
                : '---',
            'packetLoss': loss != null ? '${loss.toStringAsFixed(1)}%' : '---',
          });
        }
      } catch (e) {
        AppLogger.error("[WebRTC] Stats error", e);
      }
    });
  }

  Future<void> _cleanupFirebaseSession() async {
    try {
      final email = userEmail;
      if (email == null) return;

      // Remove a sessão de WebRTC específica do utilizador
      await _db
          .collection('robots')
          .doc(robotId)
          .collection('viewers')
          .doc(email)
          .delete();

      // Apenas removemos o espectador da fila.
      // NÃO limpamos a webrtc_session global para não interromper o handshake de outros utilizadores!
      // (A libertação do active_controller já é feita no _cleanupConnection do CameraScreen)
      await _db.collection('robots').doc(robotId).update({
        // Remove viewer from queue
        'control.viewer_queue': FieldValue.arrayRemove([email]),
      });

      AppLogger.info(
        "[WebRTC] Utilizador $email removido da fila de espectadores",
      );
    } catch (e) {
      AppLogger.error("[WebRTC] Erro ao limpar session Firebase", e);
    }
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

    // Cleanup Firebase ANTES de terminar completamente
    _cleanupFirebaseSession();

    AppLogger.info("[WebRTCService] Recursos libertados com sucesso");
  }
}
