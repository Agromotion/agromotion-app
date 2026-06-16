import 'dart:async';
import 'package:agromotion/services/auth_service.dart';
import 'package:agromotion/widgets/controls/drum_overlay.dart';
import 'package:agromotion/widgets/glass_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/utils/app_logger.dart';
import 'package:agromotion/services/webrtc_service.dart';
import 'package:agromotion/services/storage_service.dart';
import 'package:agromotion/services/media_service.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/agro_snackbar.dart';
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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // — Renderers & Services —
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  final StorageService _storageService = StorageService();
  final MediaService _mediaService = MediaService();
  WebRTCService? _webrtcService;
  StreamSubscription? _telemetrySubscription;
  StreamSubscription? _webrtcStatsSubscription;
  bool _rendererReady = false;

  // — UI State —
  bool _showDebug = false;
  bool _isFullScreen = false;
  bool _hasActiveStream = false;

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

    WidgetsBinding.instance.addObserver(this);
    _loadJoystickPreference();
    _listenToFirestoreTelemetry();
    _startMovementHeartbeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initRenderer();
      await _initializeWebRTC();
    });
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
    WidgetsBinding.instance.removeObserver(this);
    _cleanupConnection();
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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Garante que o controlo e WebRTC são limpos se o utilizador minimizar ou fechar a app de repente
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      AppLogger.info(
        "[AppLifecycle] App em background/fechada. A limpar conexão...",
      );
      _cleanupConnection();
    }
  }

  Future<void> _cleanupConnection() async {
    try {
      final myEmail = AuthService().currentUser?.email;
      final robotRef = FirebaseFirestore.instance
          .collection('robots')
          .doc(_robotId);

      if (myEmail != null) {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snap = await transaction.get(robotRef);
          if (!snap.exists) return;

          final data = snap.data()!;
          final control = data['control'] as Map<String, dynamic>? ?? {};
          final updates = <String, dynamic>{};
          bool needsUpdate = false;

          if (control['active_controller_email'] == myEmail) {
            updates['control.active_controller_email'] = FieldValue.delete();
            needsUpdate = true;
          }

          final viewerQueue = control['viewer_queue'];
          if (viewerQueue is List && viewerQueue.contains(myEmail)) {
            updates['control.viewer_queue'] = FieldValue.arrayRemove([myEmail]);
            needsUpdate = true;
          }

          if (needsUpdate) {
            transaction.update(robotRef, updates);
          }
        });
      }
    } catch (e) {
      AppLogger.error("Erro ao limpar estado de WebRTC", e);
    }
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
    int attempts = 0;
    _streamCheckTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) {
        _streamCheckTimer?.cancel();
        return;
      }
      attempts++;

      final hasDimensions =
          _remoteRenderer.videoWidth > 0 && _remoteRenderer.videoHeight > 0;

      // Na Web, o flutter_webrtc por vezes não reporta dimensões ou onFirstFrameRendered.
      // Usamos um fallback de ~3 segundos (10 tentativas) para forçar o ecrã a abrir.
      if (hasDimensions || (kIsWeb && attempts > 10)) {
        setState(() => _hasActiveStream = true);
        _streamCheckTimer?.cancel();
      }
    });
  }

  Future<void> _initializeWebRTC() async {
    if (!mounted) return;

    setState(() {
      _hasActiveStream = false;
      _rendererReady = false;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection('robots')
          .doc(_robotId)
          .get();
      bool isVideoReady = doc.data()?['status']?['video_ready'] ?? false;

      if (!isVideoReady) {
        // Se não está pronto, espera 3 segundos e tenta sozinho de novo
        Future.delayed(const Duration(seconds: 3), _initializeWebRTC);
        return;
      }

      // Se chegou aqui, o robô diz que está pronto. Tenta ligar o WebRTC.
      _webrtcService?.dispose();
      _webrtcService = WebRTCService(remoteRenderer: _remoteRenderer);

      _webrtcService!.onRemoteStreamAvailable = () {
        if (mounted) {
          setState(() => _rendererReady = true);
        }
      };

      await _webrtcService!.connect().timeout(const Duration(seconds: 15));

      if (mounted) {
        _startStreamCheck();
        _subscribeToWebRTCStats();
      }
    } catch (e) {
      AppLogger.error("Erro na conexão WebRTC", e);
      // Em caso de erro (timeout ou rede), tenta de novo automaticamente após 5 segundos
      if (mounted) {
        Future.delayed(const Duration(seconds: 5), _initializeWebRTC);
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
          final status = data['status'] as Map<String, dynamic>? ?? {};
          final activeEmail = control['active_controller_email'] as String?;
          final myEmail = AuthService().currentUser?.email;
          bool isOnline = status['online'] ?? false;

          setState(() {
            _activeControllerEmail = activeEmail;
            _canControl =
                (activeEmail == null || activeEmail == myEmail) && isOnline;
            _streamStats['cpu'] = "${telemetry['system_cpu'] ?? 0}%";
            _streamStats['temp'] = "${telemetry['system_temperature'] ?? 0}°C";
            _streamStats['battery'] =
                "${telemetry['battery_percentage'] ?? 0}%";
            if (!isOnline) {
              _streamStats['status'] = 'Offline';
            } else {
              _streamStats['status'] = _webrtcService?.isConnected ?? false
                  ? 'Online'
                  : 'A Conectar...';
            }
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
                    child: LayoutBuilder(
                      builder: (context, constraints) => SizedBox(
                        height: constraints.maxHeight,
                        width: constraints.maxWidth,
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
            child: Builder(
              builder: (context) {
                // Só monta o RTCVideoView quando o srcObject já está definido.
                // Antes disso, mostra apenas o fundo preto com o loading overlay.
                if (!_rendererReady) {
                  return ClipRRect(
                    borderRadius: kIsWeb
                        ? BorderRadius.zero
                        : BorderRadius.circular(24),
                    child: Container(
                      color: Colors.black,
                      child: _buildStreamLoadingOverlay(isFullScreen: false),
                    ),
                  );
                }

                final videoStack = Stack(
                  children: [
                    VideoFeedDisplay(
                      renderer: _remoteRenderer,
                      isFullScreen: false,
                    ),
                    _buildStreamLoadingOverlay(isFullScreen: false),
                    if (_hasActiveStream && _canControl)
                      Positioned(
                        right: 15,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: DrumOverlay(
                            onChanged: (val) => _webrtcService?.sendDrum(val),
                          ),
                        ),
                      ),
                    if (_showDebug)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: StreamDebugPanel(stats: _streamStats),
                      ),
                  ],
                );

                return kIsWeb
                    ? videoStack
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: videoStack,
                      );
              },
            ),
          ),
        ),

        // Joystick Area
        Container(
          height: 180,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _hasActiveStream
                ? (_canControl
                      ? JoystickOverlay(
                          key: const ValueKey("joystick_on"),
                          transparent: false,
                          swapJoysticks: _joystickSwap,
                          onMoveLeft: (x, y) =>
                              _handleJoystickUpdate(x, y, isLeft: true),
                          onMoveRight: (x, y) =>
                              _handleJoystickUpdate(x, y, isLeft: false),
                        )
                      : _buildControlLockedMessage())
                : const SizedBox.shrink(),
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
        Positioned.fill(child: _buildStreamLoadingOverlay(isFullScreen: true)),

        if (_hasActiveStream) ...[
          if (_canControl) ...[
            // Joysticks
            Positioned(
              left: 0,
              right: 0,
              bottom: 60,
              child: JoystickOverlay(
                transparent: true,
                isFullScreen: true,
                swapJoysticks: _joystickSwap,
                onMoveLeft: (x, y) => _handleJoystickUpdate(x, y, isLeft: true),
                onMoveRight: (x, y) =>
                    _handleJoystickUpdate(x, y, isLeft: false),
              ),
            ),

            // Drum
            Positioned(
              right: 20,
              bottom: 100,
              child: DrumOverlay(
                isFullScreen: true,
                onChanged: (val) => _webrtcService?.sendDrum(val),
              ),
            ),
          ] else ...[
            // Banner de Bloqueio (Só aparece se o vídeo estiver pronto e não tiver permissão)
            Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(child: _buildControlLockedBanner()),
            ),
          ],
        ],

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
                  child: GlassButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: _toggleFullScreen,
                  ),
                ),
              ),
              _buildBatteryWidget(),
              Expanded(
                flex: 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlassButton(
                      icon: _showDebug
                          ? Icons.bug_report
                          : Icons.bug_report_outlined,
                      onTap: () => setState(() => _showDebug = !_showDebug),
                    ),
                    const SizedBox(width: 12),
                    GlassButton(
                      icon: Icons.map_rounded,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                    ),
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
                GlassButton(
                  icon: Icons.camera_alt_rounded,
                  onTap: _captureScreenshot,
                ),
                const SizedBox(width: 20),
                GlassButton(
                  icon: Icons.fullscreen_exit_rounded,
                  onTap: _toggleFullScreen,
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

  Widget _buildLockedBannerContent() {
    return Row(
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
    );
  }

  /// Banner mostrado em fullscreen quando o controlo está ocupado.
  Widget _buildControlLockedBanner() {
    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(
            215,
          ), // Escuro semi-transparente (~0.85 opacity)
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.orange.withAlpha(128)),
        ),
        child: _buildLockedBannerContent(),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      borderRadius: 15,
      child: _buildLockedBannerContent(),
    );
  }

  Widget _buildBatteryContent(ColorScheme colorScheme) {
    return Row(
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
    );
  }

  Widget _buildBatteryWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    if (kIsWeb) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(160), // ~0.65 opacity
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withAlpha(80)),
        ),
        child: _buildBatteryContent(colorScheme),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 20,
      child: _buildBatteryContent(colorScheme),
    );
  }
}
