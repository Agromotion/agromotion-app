import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Utils & Theme
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/theme/app_theme.dart';

// Services
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/components/agro_snackbar.dart';

// Componentes HUD & Controlos
import 'package:agromotion/components/camera/recording_badge.dart';
import 'package:agromotion/components/camera/video_feed_display.dart';
import 'package:agromotion/components/camera/camera_status_view.dart';
import 'package:agromotion/components/camera/camera_control.dart';
import 'package:agromotion/components/camera/stream_debug_panel.dart';
import 'package:agromotion/components/agro_appbar.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  WebRTCService? _webrtcService;

  // Estados de Interface
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDebug = false;

  // Estados de Transmissão
  String _currentQuality = 'auto';
  int _recordDuration = 0;
  Timer? _recordTimer;

  // Mapa de Estatísticas Reais
  final Map<String, dynamic> _streamStats = {
    'fps': 0.0,
    'loss': 0.0,
    'res': '0x0',
    'latency': '---',
    'cpu': '---',
    'temp': '---',
  };

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  /// Inicializa a ligação e mapeia os serviços
  Future<void> _initializeWebRTC() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _remoteRenderer.initialize();
      _webrtcService?.dispose();

      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);

      // --- CONFIGURAÇÃO DE LISTENERS ---
      // 1. Ouvinte de Telemetria (FPS, Res, CPU, Temp)
      _webrtcService!.telemetry.onTelemetryReceived = (data) {
        if (mounted) {
          setState(() {
            _streamStats['fps'] = data['fps']?.toDouble() ?? 0.0;
            _streamStats['res'] = data['res'] ?? 'Unknown';
            _streamStats['cpu'] = "${data['cpu']}%";
            _streamStats['temp'] = "${data['temp']}°C";
          });
        }
      };

      // 2. Ouvinte de Latência (Ping)
      _webrtcService!.telemetry.onLatencyMeasured = (latency) {
        if (mounted) setState(() => _streamStats['latency'] = latency);
      };

      // 3. Ouvinte de Interrupção de Ligação
      _webrtcService!.onConnectionLost = () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "A ligação ao robô foi interrompida.";
          });

          // Feedback visual
          AgroSnackbar.show(
            context,
            message: "Ligação perdida. Verifique o sinal do robô.",
            isError: true,
          );
        }
      };

      // 4. Conectar
      await _webrtcService!.connect().timeout(const Duration(seconds: 30));

      if (mounted) {
        setState(() => _isLoading = false);
        _setupQualityLogic();
        _startPacketLossMonitor();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is TimeoutException
              ? "O robô não respondeu à offer."
              : "Erro na ligação.";
        });
      }
    }
  }

  /// Monitoriza a perda de pacotes local
  void _startPacketLossMonitor() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      if (_webrtcService == null ||
          !mounted ||
          _isLoading ||
          _errorMessage != null) {
        timer.cancel();
        return;
      }
      final loss = await _webrtcService!.getConnectionLoss();
      if (mounted) setState(() => _streamStats['loss'] = loss);
    });
  }

  void _setupQualityLogic() {
    if (_currentQuality == 'auto') {
      _webrtcService?.startAutoQualityMonitor((q) => debugPrint("Auto: $q"));
    }
  }

  void _handleQualityChange(String quality) {
    setState(() => _currentQuality = quality);
    if (quality == 'auto') {
      _setupQualityLogic();
    } else {
      _webrtcService?.stopAutoQualityMonitor();
      _webrtcService?.telemetry.sendCommand("SET_QUALITY", quality);
    }
    AgroSnackbar.show(context, message: "Modo: ${quality.toUpperCase()}");
  }

  void _handleToggleRecording() async {
    if (_webrtcService == null) return;

    if (_webrtcService!.media.isRecording) {
      _recordTimer?.cancel();
      await _webrtcService!.media.stopRecording();
      setState(() => _recordDuration = 0);
      AgroSnackbar.show(context, message: "Gravação guardada!");
    } else {
      try {
        await _webrtcService!.media.startRecording(_remoteRenderer.srcObject);
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _recordDuration++);
        });
      } catch (e) {
        AgroSnackbar.show(context, message: "Erro na gravação", isError: true);
      }
    }
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _webrtcService?.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;
    final isSmall = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const AgroAppBar(title: 'Monitorização Robô'),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(bottom: isSmall ? 100 : 120),
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // AQUI: Se houver erro ou carregamento, o vídeo é removido da árvore
                              // Isto evita os erros de Context Lost (EGL) no Windows
                              if (_isLoading || _errorMessage != null)
                                CameraStatusView(
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  onRetry: _initializeWebRTC,
                                )
                              else ...[
                                VideoFeedDisplay(renderer: _remoteRenderer),
                                if (_showDebug)
                                  Positioned(
                                    top: 20,
                                    left: 20,
                                    child: StreamDebugPanel(
                                      stats: _streamStats,
                                    ),
                                  ),
                                if (_webrtcService?.media.isRecording ?? false)
                                  Positioned(
                                    top: 20,
                                    right: 20,
                                    child: RecordingBadge(
                                      duration: _recordDuration,
                                    ),
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: CameraControl(
                          isDebugVisible: _showDebug,
                          isRecording:
                              _webrtcService?.media.isRecording ?? false,
                          currentQuality: _currentQuality,
                          onToggleDebug: () =>
                              setState(() => _showDebug = !_showDebug),
                          onQualityChanged: _handleQualityChange,
                          onCapturePressed: () => _webrtcService?.media
                              .captureScreenshot(_remoteRenderer.srcObject),
                          onRecordPressed: _handleToggleRecording,
                          onRetryPressed: _initializeWebRTC,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
