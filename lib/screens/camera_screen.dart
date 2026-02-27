import 'dart:async';
<<<<<<< Updated upstream
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
=======
import 'dart:io';
import 'package:agromotion/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/wrapper/keyboard_listener_wrapper.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/services/storage_service.dart';
import 'package:agromotion/components/glass_container.dart';

>>>>>>> Stashed changes
import 'package:agromotion/components/camera/camera_status_view.dart';
import 'package:agromotion/components/camera/video_feed_display.dart';
import 'package:agromotion/components/camera/stream_debug_panel.dart';
import 'package:agromotion/components/controls/joystick_overlay.dart';
import 'package:agromotion/components/camera/camera_control.dart';
import 'package:agromotion/screens/map_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final StorageService _storageService = StorageService();
  WebRTCService? _webrtcService;
  StreamSubscription? _telemetrySubscription;

  // Estados de Interface
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDebug = false;

  // Estados de Transmissão
  String _currentQuality = 'auto';
<<<<<<< Updated upstream
  int _recordDuration = 0;
  Timer? _recordTimer;

  // Mapa de Estatísticas Reais
  final Map<String, dynamic> _streamStats = {
=======
  bool _joystickSwap = false;
  String get _robotId => AppConfig.robotId;

  // Track raw joystick coordinates for the heartbeat
  double _joyX = 0.0;
  double _joyY = 0.0;
  Timer? _movementHeartbeat;

  Map<String, dynamic> _streamStats = {
>>>>>>> Stashed changes
    'fps': 0.0,
    'loss': 0.0,
    'res': '---',
    'latency': '---',
    'cpu': '---',
    'temp': '---',
    'battery': '0%',
  };

  @override
  void initState() {
    super.initState();
    _loadJoystickPreference();
    _initializeWebRTC();
<<<<<<< Updated upstream
  }

  /// Inicializa a ligação e mapeia os serviços
=======
    _listenToFirestoreTelemetry();
    _startMovementHeartbeat();
  }

  Future<void> _loadJoystickPreference() async {
    final swap = await _storageService.getJoystickSwap();
    setState(() => _joystickSwap = swap);
  }

  /// Listen to Firestore for slow-moving telemetry (Battery, Temp, CPU)
  void _listenToFirestoreTelemetry() {
    _telemetrySubscription = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (snap.exists && mounted) {
            final data = snap.data()!;
            final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};
            setState(() {
              _streamStats['cpu'] = "${telemetry['system_cpu'] ?? 0}%";
              _streamStats['temp'] =
                  "${telemetry['system_temperature'] ?? 0}°C";
              _streamStats['battery'] =
                  "${telemetry['battery_percentage'] ?? 0}%";
            });
          }
        });
  }

  /// Heartbeat sends the CURRENT joystick state every 100ms via P2P DataChannel
  void _startMovementHeartbeat() {
    _movementHeartbeat = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_webrtcService != null && _webrtcService!.isConnected) {
        // Send raw coordinates (x, y) directly to Pi's memory
        _webrtcService!.sendJoystick(_joyX, _joyY);
      }
    });
  }

>>>>>>> Stashed changes
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

<<<<<<< Updated upstream
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
=======
      await _webrtcService!.connect().timeout(const Duration(seconds: 20));

      if (mounted) setState(() => _isLoading = false);
>>>>>>> Stashed changes
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
<<<<<<< Updated upstream
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
=======
          _errorMessage = "Erro de Ligação P2P";
        });
      }
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      if (!_isDesktop) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      if (!_isDesktop) {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;
    return KeyboardListenerWrapper(
      onKeysChanged: (keys) {
        // Support for keyboard driving (Desktop/Web)
        double x = 0, y = 0;
        if (keys.contains(LogicalKeyboardKey.keyW)) y += 1;
        if (keys.contains(LogicalKeyboardKey.keyS)) y -= 1;
        if (keys.contains(LogicalKeyboardKey.keyA)) x -= 1;
        if (keys.contains(LogicalKeyboardKey.keyD)) x += 1;
        _joyX = x;
        _joyY = y;
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
          child: Stack(
            children: [
              _buildVideoLayer(),
              if (!_isDesktop) _buildMobileJoysticks(),
              _buildHUD(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoLayer() {
    return Positioned.fill(
      child: Column(
        children: [
          Expanded(
            flex: _isFullScreen ? 1 : 11,
            child: Stack(
              children: [
                _isLoading || _errorMessage != null
                    ? CameraStatusView(
                        isLoading: _isLoading,
                        errorMessage: _errorMessage,
                        onRetry: _initializeWebRTC,
                      )
                    : VideoFeedDisplay(
                        renderer: _remoteRenderer,
                        isFullScreen: _isFullScreen,
                      ),
              ],
            ),
          ),
          if (!_isFullScreen) const Spacer(flex: 9),
        ],
      ),
    );
  }

  Widget _buildMobileJoysticks() {
    return Positioned(
      bottom: _isFullScreen ? 60 : 180,
      left: 0,
      right: 0,
      child: JoystickOverlay(
        transparent: true,
        isFullScreen: _isFullScreen,
        swapJoysticks: _joystickSwap,
        onMoveLeft: (x, y) => _handleJoystickUpdate(x, y, isLeft: true),
        onMoveRight: (x, y) => _handleJoystickUpdate(x, y, isLeft: false),
      ),
    );
  }

  /// Updated to handle raw coordinates
  void _handleJoystickUpdate(double x, double y, {required bool isLeft}) {
    // If not swapped: Left stick (WASD) = x/y, Right stick (Rotation) = x only
    // This allows the Pi firmware to receive standard coordinates
    if (!_joystickSwap) {
      if (isLeft) {
        _joyX = x;
        _joyY = -y; // Invert Y for standard math (Up = Positive)
      } else {
        // Rotation usually only needs X axis
        // We can mix rotation into _joyX or handle it via a separate field
        // For your firmware.py process_joystick, it expects one set of X/Y
        _joyX = x;
      }
    } else {
      // Swapped logic
      if (isLeft) {
        _joyX = x;
      } else {
        _joyX = x;
        _joyY = -y;
      }
    }
  }

  Widget _buildHUD(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 20,
            child: _buildGlassButton(
              Icons.chevron_left_rounded,
              () => Navigator.pop(context),
            ),
          ),
          if (_showDebug)
            Positioned(
              top: 70,
              left: 20,
              child: StreamDebugPanel(stats: _streamStats),
            ),
          _buildContextualControls(),
        ],
      ),
    );
  }

  Widget _buildContextualControls() {
    if (_isFullScreen) {
      return Stack(
        children: [
          Positioned(
            top: 10,
            right: 20,
            child: Row(
              children: [
                _buildGlassButton(
                  _showDebug ? Icons.info_rounded : Icons.info_outline_rounded,
                  () => setState(() => _showDebug = !_showDebug),
                  active: _showDebug,
                ),
                const SizedBox(width: 12),
                _buildGlassButton(
                  Icons.fullscreen_exit_rounded,
                  _toggleFullScreen,
                ),
              ],
            ),
          ),
          Positioned(bottom: 20, left: 20, child: _buildBatteryWidget()),
          Positioned(
            bottom: 20,
            right: 20,
            child: Row(
              children: [
                _buildQualityDropdown(),
                const SizedBox(width: 12),
                _buildGlassButton(Icons.map_rounded, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MapScreen()),
                  );
                }),
                const SizedBox(width: 12),
                _buildGlassButton(Icons.camera_alt_rounded, () {}),
              ],
            ),
          ),
        ],
      );
    } else {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildBatteryWidget(),
              const SizedBox(height: 12),
              CameraControl(
                isFullScreen: _isFullScreen,
                isDebugVisible: _showDebug,
                currentQuality: _currentQuality,
                onToggleFullScreen: _toggleFullScreen,
                onToggleDebug: () => setState(() => _showDebug = !_showDebug),
                onQualityChanged: (q) => setState(() => _currentQuality = q),
                onCapturePressed: () {},
                onMapPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapScreen()),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildQualityDropdown() {
    final theme = Theme.of(context);
    return GlassContainer(
      padding: const EdgeInsets.only(left: 16, right: 8),
      borderRadius: 50,
      child: DropdownButton<String>(
        value: _currentQuality,
        underline: const SizedBox.shrink(),
        dropdownColor: theme.colorScheme.surface.withOpacity(0.9),
        icon: const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          DropdownMenuItem(value: 'auto', child: Text('AUTO')),
          DropdownMenuItem(value: '720', child: Text('HD')),
          DropdownMenuItem(value: '480', child: Text('SD')),
        ],
        onChanged: (val) {
          if (val != null) setState(() => _currentQuality = val);
        },
      ),
    );
  }

  Widget _buildGlassButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 50,
        child: Icon(
          icon,
          color: active ? Theme.of(context).colorScheme.primary : Colors.white,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildBatteryWidget() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.battery_6_bar_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _streamStats['battery'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
>>>>>>> Stashed changes
  }

  @override
  void dispose() {
<<<<<<< Updated upstream
    _recordTimer?.cancel();
=======
    _telemetrySubscription?.cancel();
    _movementHeartbeat?.cancel();
>>>>>>> Stashed changes
    _webrtcService?.dispose();
    _remoteRenderer.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
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
