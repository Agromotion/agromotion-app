import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:agromotion/services/signaling_service.dart';
import 'telemetry_service.dart';
import 'media_service.dart';

class WebRTCService {
  RTCPeerConnection? _peerConnection;
  RTCVideoRenderer remoteRenderer;
  StreamSubscription? _signalingSubscription;
  Timer? _qualityTimer;
  bool _isDisposed = false;
  String _lastAutoQuality = "";

  VoidCallback? onConnectionLost;

  final SignalingService _signaling = SignalingService();
  final TelemetryService telemetry = TelemetryService();
  final MediaService media = MediaService();

  WebRTCService({required this.remoteRenderer});

  Future<void> connect() async {
    _peerConnection = await createPeerConnection({
      "sdpSemantics": "unified-plan",
      "iceServers": [
        {"urls": "stun:stun.l.google.com:19302"},
      ],
    });

    // Monitorizar estado da ligação para evitar erros de GPU no Windows
    _peerConnection!.onIceConnectionState = (RTCIceConnectionState state) {
      debugPrint("WebRTC: ICE State -> $state");

      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          state == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        // Se a ligação caiu, limpamos o renderer antes de avisar a UI
        _cleanupRenderer();
        onConnectionLost?.call();
      }
    };

    await _peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    RTCDataChannelInit dcInit = RTCDataChannelInit();
    final channel = await _peerConnection!.createDataChannel(
      "commands",
      dcInit,
    );
    telemetry.initialize(channel);

    _peerConnection!.onTrack = (RTCTrackEvent event) {
      if (!_isDisposed && event.track.kind == 'video') {
        remoteRenderer.srcObject = event.streams[0];
      }
    };

    RTCSessionDescription offer = await _peerConnection!.createOffer({
      'offerToReceiveVideo': 1,
    });
    await _peerConnection!.setLocalDescription(offer);
    await _signaling.sendOffer(offer.sdp!, offer.type!);

    Completer<void> connectedCompleter = Completer();
    _signalingSubscription = _signaling.getSignalingStream().listen((
      snapshot,
    ) async {
      if (_isDisposed || !snapshot.exists) return;
      var data = snapshot.data() as Map<String, dynamic>?;
      var answer = data?['answer'];

      if (answer != null && !connectedCompleter.isCompleted) {
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(answer['sdp'], answer['type']),
        );
        telemetry.startPingSequence();
        connectedCompleter.complete();
      }
    });

    try {
      return await connectedCompleter.future.timeout(
        const Duration(seconds: 30),
      );
    } on TimeoutException {
      if (telemetry.isConnected) return;
      rethrow;
    }
  }

  /// Limpa o srcObject para evitar que a GPU tente renderizar frames inexistentes
  void _cleanupRenderer() {
    remoteRenderer.srcObject = null;
  }

  // --- Lógica de Qualidade ---

  void startAutoQualityMonitor(Function(String) onQualityChanged) {
    _qualityTimer?.cancel();
    _qualityTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isDisposed) return;

      double loss = await getConnectionLoss();
      String newQuality = "";

      if (loss > 5.0) {
        newQuality = "480";
      } else if (loss < 1.0) {
        newQuality = "original";
      }

      if (newQuality.isNotEmpty && newQuality != _lastAutoQuality) {
        _lastAutoQuality = newQuality;
        telemetry.sendCommand("SET_QUALITY", newQuality);
        onQualityChanged(newQuality);
      }
    });
  }

  void stopAutoQualityMonitor() {
    _qualityTimer?.cancel();
  }

  // --- Estatísticas de Rede ---

  Future<double> getConnectionLoss() async {
    if (_peerConnection == null) return 0.0;
    try {
      final stats = await _peerConnection!.getStats();
      for (var report in stats) {
        if (report.type == 'inbound-rtp' && report.values['kind'] == 'video') {
          int lost = report.values['packetsLost'] ?? 0;
          int received = report.values['packetsReceived'] ?? 0;
          if ((received + lost) == 0) return 0.0;
          return (lost / (received + lost)) * 100;
        }
      }
    } catch (e) {
      debugPrint("Erro ao obter stats: $e");
    }
    return 0.0;
  }

  void dispose() {
    _isDisposed = true;
    _qualityTimer?.cancel();
    _signalingSubscription?.cancel();
    telemetry.dispose();
    _cleanupRenderer();
    _peerConnection?.dispose();
  }
}
