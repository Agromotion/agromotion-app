import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Utils & Services
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/components/agro_snackbar.dart';

// Componentes Modularizados
import 'package:agromotion/components/camera/recording_badge.dart';
import 'package:agromotion/components/camera/video_feed_display.dart';
import 'package:agromotion/components/camera/camera_status_view.dart';
import 'package:agromotion/components/camera/camera_control.dart';
import 'package:agromotion/components/camera/quality_selector.dart';
import 'package:agromotion/components/agro_appbar.dart';
import 'package:agromotion/theme/app_theme.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  WebRTCService? _webrtcService;

  bool _isLoading = true;
  String? _errorMessage;
  Timer? _recordTimer;
  int _recordDuration = 0;
  String _currentQuality = 'auto';

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  /// Inicializa a stream e configura os serviços
  Future<void> _initializeWebRTC() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _remoteRenderer.initialize();

      // Limpeza de instância anterior se houver (para o botão Flip/Retry)
      _webrtcService?.dispose();

      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);

      // Conexão ao Simulador/Robô
      await _webrtcService!.connect("https://j2srtf27-8080.usw3.devtunnels.ms");

      if (mounted) {
        setState(() => _isLoading = false);
        _setupQualityLogic();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Falha na ligação ao Robô.";
        });
      }
    }
  }

  /// Configura o monitor de rede se estiver em modo automático
  void _setupQualityLogic() {
    if (_currentQuality == 'auto') {
      _webrtcService?.startAutoQualityMonitor((quality) {
        debugPrint("Rede ajustada automaticamente para: $quality");
      });
    }
  }

  /// Altera a qualidade manualmente ou ativa o modo auto
  void _handleQualityChange(String quality) {
    setState(() => _currentQuality = quality);

    if (quality == 'auto') {
      _setupQualityLogic();
    } else {
      _webrtcService?.stopAutoQualityMonitor();
      _webrtcService?.setVideoQuality(quality);
    }

    AgroSnackbar.show(
      context,
      message: "Modo: ${quality == 'auto' ? 'Automático' : quality + 'p'}",
    );
  }

  /// Gere o início e fim da gravação de vídeo
  void _handleToggleRecording() async {
    if (_webrtcService == null) return;

    if (_webrtcService!.isRecording) {
      _recordTimer?.cancel();
      await _webrtcService!.stopRecording();
      if (mounted) {
        setState(() => _recordDuration = 0);
        AgroSnackbar.show(context, message: "Gravação guardada na galeria!");
      }
    } else {
      try {
        await _webrtcService!.startRecording();
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          setState(() => _recordDuration++);
        });
      } catch (e) {
        if (mounted) {
          AgroSnackbar.show(
            context,
            message: "Erro ao iniciar gravação",
            isError: true,
          );
        }
      }
    }
  }

  /// Captura de Foto (Screenshot)
  Future<void> _handleCapture() async {
    try {
      await _webrtcService?.captureScreenshot();
      if (mounted) {
        AgroSnackbar.show(context, message: "Foto capturada e guardada!");
      }
    } catch (e) {
      if (mounted) {
        AgroSnackbar.show(
          context,
          message: "Erro ao capturar foto",
          isError: true,
        );
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
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorsExtension>()!;

    return Stack(
      children: [
        // Fundo com Gradiente
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),

        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              const AgroAppBar(title: 'Vista do Robô'),

              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: context.isSmall
                        ? 100
                        : 140, // Padding para a NavBar customizada
                  ),
                  child: Column(
                    children: [
                      // Área do Vídeo
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Estado da Transmissão
                              if (_isLoading || _errorMessage != null)
                                CameraStatusView(
                                  isLoading: _isLoading,
                                  errorMessage: _errorMessage,
                                  onRetry: _initializeWebRTC,
                                )
                              else
                                VideoFeedDisplay(renderer: _remoteRenderer),

                              // Seletor de Qualidade (Canto Superior Esquerdo)
                              if (!_isLoading && _errorMessage == null)
                                Positioned(
                                  top: 16,
                                  left: 16,
                                  child: QualitySelector(
                                    currentQuality: _currentQuality,
                                    onQualityChanged: _handleQualityChange,
                                  ),
                                ),

                              // Badge de Gravação (Canto Superior Direito)
                              if (_webrtcService?.isRecording ?? false)
                                Positioned(
                                  top: 16,
                                  right: 16,
                                  child: RecordingBadge(
                                    duration: _recordDuration,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Controlos da Câmara (Captura, Record, Retry)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: CameraControl(
                          onCapturePressed: _handleCapture,
                          onRecordPressed: _handleToggleRecording,
                          onRetryPressed: _initializeWebRTC, // Reinicia a stream
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
