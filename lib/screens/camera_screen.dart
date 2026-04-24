import 'dart:async';
import 'dart:io';
import 'package:agromotion/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/services/storage_service.dart';
import 'package:agromotion/services/media_service.dart';
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
  // — Renderers & Services —
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final StorageService _storageService = StorageService();
  final MediaService _mediaService = MediaService();
  WebRTCService? _webrtcService;
  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _webrtcStatsSubscription;

  // — UI State —
  bool _isLoading = true;
  String? _errorMessage;
  bool _showDebug = false;
  bool _isFullScreen = false;
  bool _hasActiveStream = false;

  int _retryCount = 0;
  static const int _maxAutoRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 3);

  // — Platform —
  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  // — Joystick —
  bool _joystickSwap = false;
  double _joyX = 0.0;
  double _joyY = 0.0;
  Timer? _movementHeartbeat;
  Timer? _streamCheckTimer;

  // — Control —
  bool _canControl = false;
  String? _activeControllerEmail;
  String get _robotId => AppConfig.robotId;

  // — Telemetry —
  final Map<String, dynamic> _streamStats = {
    'cpu': '---',
    'temp': '---',
    'battery': '0%',
    'status': 'Desconectado',
  };

  // ─────────────────────────────────────────
  // Lifecycle
  // ─────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _initRenderer();
    _loadJoystickPreference();
    _initializeWebRTC();
    _listenToFirestoreTelemetry();
    _startMovementHeartbeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeWebRTC());
  }

  void _subscribeToWebRTCStats() {
    _webrtcStatsSubscription?.cancel();
    _webrtcStatsSubscription = _webrtcService?.statsStream.listen((stats) {
      if (!mounted) return;
      setState(() {
        _streamStats['fps'] = stats['frameRate'] ?? '---';
        _streamStats['resolution'] = stats['resolution'] ?? '---';
        _streamStats['latency'] = stats['latency'] ?? '---';
        _streamStats['packetLoss'] = stats['packetLoss'] ?? '---';
      });
    });
  }

  @override
  void dispose() {
    _streamCheckTimer?.cancel();
    _telemetrySubscription?.cancel();
    _movementHeartbeat?.cancel();
    _webrtcService?.dispose();
    _remoteRenderer.dispose();
    _webrtcStatsSubscription?.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  // ─────────────────────────────────────────
  // Initialization
  // ─────────────────────────────────────────

  Future<void> _initRenderer() async {
    await _remoteRenderer.initialize();
    // Backup callback — nem sempre fiável no flutter_webrtc,
    // mantemos como redundância ao polling em _startStreamCheck.
    _remoteRenderer.onFirstFrameRendered = () {
      if (mounted) setState(() => _hasActiveStream = true);
    };
  }

  Future<void> _loadJoystickPreference() async {
    final swap = await _storageService.getJoystickSwap();
    if (mounted) setState(() => _joystickSwap = swap);
  }

  /// Polling a cada 300ms ao renderer para detetar o primeiro frame real.
  /// videoWidth/videoHeight passam de 0 para um valor positivo quando
  /// os primeiros frames chegam — mais fiável que onFirstFrameRendered.
  void _startStreamCheck() {
    _streamCheckTimer?.cancel();
    _streamCheckTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) {
        _streamCheckTimer?.cancel();
        return;
      }
      if (_remoteRenderer.videoWidth > 0 && _remoteRenderer.videoHeight > 0) {
        setState(() => _hasActiveStream = true);
        _streamCheckTimer?.cancel();
      }
    });
  }

  Future<void> _initializeWebRTC({bool isAutoRetry = false}) async {
    _streamCheckTimer?.cancel();

    if (mounted) {
      setState(() {
        _hasActiveStream = false;
        _isLoading = true;
        _errorMessage = null; // Limpa erro anterior sempre que tenta
      });
    }

    // Aguarda o Firestore confirmar que o robô está pronto.
    // Em mobile a ligação pode demorar — tentamos até _maxAutoRetries vezes.
    bool isVideoReady = false;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('robots')
          .doc(_robotId)
          .get()
          .timeout(const Duration(seconds: 10));
      isVideoReady = doc.data()?['status']?['video_ready'] ?? false;
    } on TimeoutException {
      // Firestore não respondeu — trata como "ainda não pronto"
      isVideoReady = false;
    } catch (_) {
      isVideoReady = false;
    }

    if (!isVideoReady) {
      if (_retryCount < _maxAutoRetries) {
        _retryCount++;
        // Retry silencioso: mantém o spinner, não mostra erro
        Future.delayed(_retryDelay, () {
          if (mounted) _initializeWebRTC(isAutoRetry: true);
        });
        return;
      }
      // Esgotou os retries automáticos → mostra mensagem de espera (não erro)
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "A aguardar inicialização da câmara...";
        });
        // Continua a tentar em background com intervalo maior
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            _retryCount = 0;
            _initializeWebRTC();
          }
        });
      }
      return;
    }

    // Firestore confirmou video_ready — tenta WebRTC
    _retryCount = 0;
    try {
      if (!mounted) return;
      _webrtcService?.dispose();
      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);
      await _webrtcService!.connect().timeout(const Duration(seconds: 20));
      if (mounted) {
        setState(() => _isLoading = false);
        _startStreamCheck();
        _subscribeToWebRTCStats();
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "O robô não respondeu. Verifica a ligação.";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Erro ao ligar ao robô.";
        });
      }
    }
  }

  // ─────────────────────────────────────────
  // Firestore & Heartbeat
  // ─────────────────────────────────────────

  void _listenToFirestoreTelemetry() {
    _telemetrySubscription = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;
          final data = snap.data()!;
          final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};
          final control = data['control'] as Map<String, dynamic>? ?? {};
          final activeEmail = control['active_controller_email'] as String?;
          final myEmail = AuthService().currentUser?.email;

          setState(() {
            _activeControllerEmail = activeEmail;
            _canControl = activeEmail == null || activeEmail == myEmail;
            _streamStats['cpu'] = "${telemetry['system_cpu'] ?? 0}%";
            _streamStats['temp'] = "${telemetry['system_temperature'] ?? 0}°C";
            _streamStats['battery'] =
                "${telemetry['battery_percentage'] ?? 0}%";
            _streamStats['status'] = _webrtcService?.isConnected ?? false
                ? 'Online'
                : 'A Conectar...';
          });
        });
  }

  void _startMovementHeartbeat() {
    _movementHeartbeat = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_webrtcService != null &&
          _webrtcService!.isConnected &&
          _canControl) {
        _webrtcService!.sendJoystick(_joyX, _joyY);
      }
    });
  }

  // ─────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────

  void _toggleFullScreen() {
    setState(() => _isFullScreen = !_isFullScreen);
    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.transparent,
        ),
      );
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

  Future<void> _captureScreenshot() async {
    final stream = _webrtcService?.remoteStream;

    if (stream == null || stream.getVideoTracks().isEmpty) {
      AgroSnackbar.show(context, message: "Sem vídeo para capturar.");
      return;
    }

    await _mediaService.captureScreenshot(stream);
    if (mounted) {
      AgroSnackbar.show(context, message: "Foto capturada!");
    }
  }

  // ─────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────

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
            extendBody: true,
            body: _isFullScreen
                ? _buildFullScreenLayout()
                : SafeArea(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height:
                            MediaQuery.of(context).size.height -
                            MediaQuery.of(context).padding.top,
                        child: _buildStandardLayout(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // Layouts
  // ─────────────────────────────────────────

  Widget _buildStandardLayout() {
    return Column(
      children: [
        // Back button
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

        // Video area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Stack(
              children: [
                if (_isLoading || _errorMessage != null)
                  CameraStatusView(
                    isLoading: _isLoading,
                    errorMessage: _errorMessage,
                    onRetry: _initializeWebRTC,
                  )
                else
                  Stack(
                    children: [
                      VideoFeedDisplay(
                        renderer: _remoteRenderer,
                        isFullScreen: false,
                      ),
                      if (!_hasActiveStream) _buildStreamLoadingOverlay(),
                    ],
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

        // Joystick or waiting message
        if (!_isDesktop)
          Container(
            height: 180,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _canControl
                  ? JoystickOverlay(
                      key: const ValueKey("joystick_on"),
                      transparent: false,
                      swapJoysticks: _joystickSwap,
                      onMoveLeft: (x, y) =>
                          _handleJoystickUpdate(x, y, isLeft: true),
                      onMoveRight: (x, y) =>
                          _handleJoystickUpdate(x, y, isLeft: false),
                    )
                  : _buildControlLockedMessage(),
            ),
          ),

        // Bottom controls
        Padding(
          padding: const EdgeInsets.only(bottom: 20, top: 10),
          child: CameraControl(
            isDebugVisible: _showDebug,
            onToggleFullScreen: _toggleFullScreen,
            onToggleDebug: () => setState(() => _showDebug = !_showDebug),
            onMapPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            ),
            onCapturePressed: _captureScreenshot,
          ),
        ),
      ],
    );
  }

  Widget _buildFullScreenLayout() {
    return Stack(
      children: [
        // Video
        Positioned.fill(
          child: VideoFeedDisplay(
            renderer: _remoteRenderer,
            isFullScreen: true,
          ),
        ),

        // Stream loading overlay (fullscreen)
        if (!_hasActiveStream && !_isLoading)
          Positioned.fill(
            child: _buildStreamLoadingOverlay(isFullScreen: true),
          ),

        // Joysticks
        if (!_isDesktop && _canControl)
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

        // Control locked banner (fullscreen)
        if (!_canControl)
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: Center(child: _buildControlLockedBanner()),
          ),

        // Top HUD
        Positioned(
          top: 20,
          left: 20,
          right: 20,
          child: Row(
            children: [
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
              _buildBatteryWidget(),
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
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Bottom HUD
        Positioned(
          bottom: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlassButton(Icons.camera_alt_rounded, _captureScreenshot),
                const SizedBox(width: 20),
                _buildGlassButton(
                  Icons.fullscreen_exit_rounded,
                  _toggleFullScreen,
                ),
              ],
            ),
          ),
        ),

        // Debug panel
        if (_showDebug)
          Positioned(
            top: 90,
            left: 20,
            child: StreamDebugPanel(stats: _streamStats),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // Shared Widgets
  // ─────────────────────────────────────────

  /// Overlay mostrado enquanto o WebRTC está conectado mas ainda não
  /// chegou nenhum frame. Desaparece com fade quando _hasActiveStream = true.
  Widget _buildStreamLoadingOverlay({bool isFullScreen = false}) {
    return AnimatedOpacity(
      opacity: _hasActiveStream ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: isFullScreen
              ? BorderRadius.zero
              : BorderRadius.circular(24),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2),
              SizedBox(height: 16),
              Text(
                "A receber vídeo...",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostrado na área do joystick quando outro utilizador tem controlo.
  Widget _buildControlLockedMessage() {
    return Center(
      key: const ValueKey("joystick_off"),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Colors.orange, size: 16),
          const SizedBox(width: 8),
          Text(
            "Aguarde a sua vez para controlar...",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  /// Banner mostrado em fullscreen quando o controlo está ocupado.
  Widget _buildControlLockedBanner() {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: 15,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Text(
            "Controlo ocupado por: ${_activeControllerEmail ?? 'outro utilizador'}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
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
}
