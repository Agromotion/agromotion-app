import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/services/storage_service.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/agro_snackbar.dart';
import 'package:agromotion/widgets/camera/camera_status_view.dart';
import 'package:agromotion/widgets/camera/video_feed_display.dart';
import 'package:agromotion/widgets/camera/stream_debug_panel.dart';
import 'package:agromotion/widgets/controls/joystick_overlay.dart';
import 'package:agromotion/widgets/camera/camera_control.dart';
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

  bool _isLoading = true;
  String? _errorMessage;
  bool _showDebug = false;
  bool _isFullScreen = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  bool _joystickSwap = false;
  String get _robotId => AppConfig.robotId;

  double _joyX = 0.0;
  double _joyY = 0.0;
  Timer? _movementHeartbeat;

  final Map<String, dynamic> _streamStats = {
    'cpu': '---',
    'temp': '---',
    'battery': '0%',
    'status': 'Desconectado',
  };

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _loadJoystickPreference();
    _initializeWebRTC();
    _listenToFirestoreTelemetry();
    _startMovementHeartbeat();
  }

  Future<void> _initRenderer() async => await _remoteRenderer.initialize();

  Future<void> _loadJoystickPreference() async {
    final swap = await _storageService.getJoystickSwap();
    if (mounted) setState(() => _joystickSwap = swap);
  }

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
              _streamStats['status'] = _webrtcService?.isConnected ?? false
                  ? 'Online'
                  : 'Conectando...';
            });
          }
        });
  }

  void _startMovementHeartbeat() {
    _movementHeartbeat = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (_webrtcService != null && _webrtcService!.isConnected) {
        _webrtcService!.sendJoystick(_joyX, _joyY);
      }
    });
  }

  Future<void> _initializeWebRTC() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      _webrtcService?.dispose();
      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);
      await _webrtcService!.connect().timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) setState(() => _errorMessage = "O robô não respondeu.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    }
  }

  void _handleJoystickUpdate(double x, double y, {required bool isLeft}) {
    setState(() {
      if (!_joystickSwap) {
        if (isLeft) {
          _joyX = x;
          _joyY = -y;
        } else {
          _joyX = x;
        }
      } else {
        if (isLeft) {
          _joyX = x;
        } else {
          _joyX = x;
          _joyY = -y;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isFullScreen) _toggleFullScreen();
      },
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: customColors.backgroundGradient,
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top,
                  child: _isFullScreen
                      ? _buildFullScreenLayout()
                      : _buildStandardLayout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandardLayout() {
    return Column(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
                        isFullScreen: false,
                      ),
                if (_showDebug)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: StreamDebugPanel(stats: _streamStats),
                  ),
              ],
            ),
          ),
        ),
        if (!_isDesktop)
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: JoystickOverlay(
              transparent: false,
              swapJoysticks: _joystickSwap,
              onMoveLeft: (x, y) => _handleJoystickUpdate(x, y, isLeft: true),
              onMoveRight: (x, y) => _handleJoystickUpdate(x, y, isLeft: false),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: CameraControl(
            isDebugVisible: _showDebug,
            onToggleFullScreen: _toggleFullScreen,
            onToggleDebug: () => setState(() => _showDebug = !_showDebug),
            onMapPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MapScreen()),
            ),
            currentQuality: 'auto',
            onQualityChanged: (v) {},
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenLayout() {
    return Stack(
      children: [
        Positioned.fill(
          child: VideoFeedDisplay(
            renderer: _remoteRenderer,
            isFullScreen: true,
          ),
        ),

        // JOYSTICKS
        if (!_isDesktop)
          Positioned(
            left: 0,
            right: 0,
            bottom: 60,
            child: JoystickOverlay(
              transparent: true,
              isFullScreen: true,
              swapJoysticks: _joystickSwap,
              onMoveLeft: (x, y) => _handleJoystickUpdate(x, y, isLeft: true),
              onMoveRight: (x, y) => _handleJoystickUpdate(x, y, isLeft: false),
            ),
          ),

        // HUD SUPERIOR - Corrigido para evitar Overflow
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            children: [
              // Lado Esquerdo - Flex 1
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildGlassButton(
                    Icons.arrow_back_ios_new,
                    _toggleFullScreen,
                  ),
                ),
              ),

              // CENTRO - Bateria (Não expande mais do que o necessário)
              _buildBatteryWidget(),

              // Lado Direito - Flex 1 (Garante o equilíbrio com a esquerda)
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildGlassButton(
                      _showDebug ? Icons.bug_report : Icons.bug_report_outlined,
                      () => setState(() => _showDebug = !_showDebug),
                      active: _showDebug,
                    ),
                    const SizedBox(width: 12),
                    _buildGlassButton(Icons.map_rounded, () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MapScreen(),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // HUD INFERIOR CENTRALIZADO
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassButton(
                  Icons.camera_alt_rounded,
                  () => AgroSnackbar.show(context, message: "Foto capturada!"),
                ),
                const SizedBox(width: 20),
                _buildGlassButton(
                  Icons.fullscreen_exit_rounded,
                  _toggleFullScreen,
                ),
              ],
            ),
          ),
        ),

        if (_showDebug)
          Positioned(
            top: 90,
            left: 20,
            child: StreamDebugPanel(stats: _streamStats),
          ),
      ],
    );
  }

  Widget _buildBatteryWidget() {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.battery_std, color: colorScheme.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            _streamStats['battery'],
            style: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassButton(
    IconData icon,
    VoidCallback onTap, {
    bool active = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 50,
        child: Icon(
          icon,
          color: active
              ? colorScheme.primary
              : colorScheme.onSurface.withAlpha(90),
          size: 24,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _telemetrySubscription?.cancel();
    _movementHeartbeat?.cancel();
    _webrtcService?.dispose();
    _remoteRenderer.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
