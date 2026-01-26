import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

// Utils & Services
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/components/agro_snackbar.dart';

// Componentes Separados
import 'package:agromotion/components/camera/recording_badge.dart';
import 'package:agromotion/components/camera/video_feed_display.dart';
import 'package:agromotion/components/camera/camera_status_view.dart';
import 'package:agromotion/components/camera/camera_control.dart';
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
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebRTC();
  }

  Future<void> _initializeWebRTC() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      await _remoteRenderer.initialize();
      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);

      _remoteRenderer.onResize = () {
        if (mounted) setState(() {});
      };

      await _webrtcService!.connect("server_address_here");
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Falha na ligação ao Robô.";
        });
      }
    }
  }

  void _handleToggleRecording() async {
    if (_webrtcService == null) return;

    if (_webrtcService!.isRecording) {
      _timer?.cancel();
      await _webrtcService!.stopRecording();
      if (mounted) {
        setState(() => _recordDuration = 0);
        AgroSnackbar.show(context, message: "Gravação guardada na galeria!");
      }
    } else {
      try {
        await _webrtcService!.startRecording();
        _timer = Timer.periodic(const Duration(seconds: 1), (t) {
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
    setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _webrtcService?.dispose();
    Future.microtask(() => _remoteRenderer.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const AgroAppBar(title: 'Vista do Robô'),
              SliverFillRemaining(
                child: Padding(
                  padding: EdgeInsets.only(bottom: context.isSmall ? 80 : 120),
                  child: Column(
                    children: [
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isLoading || _errorMessage != null)
                              CameraStatusView(
                                isLoading: _isLoading,
                                errorMessage: _errorMessage,
                                onRetry: _initializeWebRTC,
                              )
                            else
                              VideoFeedDisplay(renderer: _remoteRenderer),

                            if (_webrtcService?.isRecording ?? false)
                              Positioned(
                                top: 32,
                                right: 32,
                                child: RecordingBadge(
                                  duration: _recordDuration,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: CameraControl(
                          onCapturePressed: () async {
                            try {
                              await _webrtcService?.captureScreenshot();
                              if (mounted) {
                                AgroSnackbar.show(
                                  context,
                                  message: "Foto capturada!",
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                AgroSnackbar.show(
                                  context,
                                  message: "Erro na captura",
                                  isError: true,
                                );
                              }
                            }
                          },
                          onRecordPressed: _handleToggleRecording,
                          onFlipPressed: _initializeWebRTC,
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
