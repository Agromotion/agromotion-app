import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/widgets/home/battery_chip.dart';
import 'package:agromotion/widgets/home/home_action_button.dart';
import 'package:agromotion/widgets/home/home_chip.dart';
import 'package:agromotion/widgets/home/home_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/screens/camera_screen.dart';
import 'package:agromotion/screens/map_screen.dart';
import 'package:agromotion/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  final Flutter3DController modelController;
  final bool isVisible;

  const HomeScreen({
    super.key,
    required this.modelController,
    this.isVisible = true,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  bool _isOnline = false;
  int _batteryLevel = 0;
  bool _isCharging = false;
  String get _robotId => AppConfig.robotId;

  StreamSubscription? _robotSubscription;
  Timer? _rotationTimer;
  Timer? _resumeTimer;

  double _currentOrbitY = 0.0;
  final double _carouselTilt = 25;

  bool _isDisposed = false;
  bool _isUserInteracting = false;

  @override
  bool get wantKeepAlive => true;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _listenToRobotStatus();
    widget.modelController.onModelLoaded.addListener(_onModelLoadedHandler);
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isVisible != oldWidget.isVisible) {
      widget.isVisible ? _startAutoRotation() : _rotationTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _rotationTimer?.cancel();
    _resumeTimer?.cancel();
    _robotSubscription?.cancel();
    widget.modelController.onModelLoaded.removeListener(_onModelLoadedHandler);
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Firebase
  // -------------------------------------------------------------------------

  void _listenToRobotStatus() {
    _robotSubscription = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted || _isDisposed) return;

          final data = snap.data()!;
          final status = data['status'] as Map<String, dynamic>? ?? {};
          final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};

          setState(() {
            _isOnline = status['online'] ?? false;
            _batteryLevel =
                (telemetry['battery_percentage'] as num?)?.toInt() ?? 0;
            _isCharging = telemetry['is_charging'] ?? false;
          });
        });
  }

  // -------------------------------------------------------------------------
  // 3D model rotation
  // -------------------------------------------------------------------------

  void _onModelLoadedHandler() {
    if (!mounted || _isDisposed) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      widget.modelController.setCameraTarget(0, 0, 0);
      widget.modelController.setCameraOrbit(
        _carouselTilt,
        _currentOrbitY + 90,
        100,
      );
      _startAutoRotation();
    });
  }

  void _startAutoRotation() {
    _rotationTimer?.cancel();
    if (!widget.isVisible) return;

    _rotationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted || _isDisposed || _isUserInteracting || !widget.isVisible) {
        return;
      }
      _currentOrbitY = (_currentOrbitY + 0.6) % 360;
      try {
        widget.modelController.setCameraOrbit(
          _carouselTilt,
          _currentOrbitY + 90,
          100,
        );
      } catch (e) {
        debugPrint('Erro ao orbitar: $e');
      }
    });
  }

  void _onUserInteractionStart() {
    setState(() => _isUserInteracting = true);
    _resumeTimer?.cancel();
  }

  void _onUserInteractionEnd() {
    _resumeTimer?.cancel();
    _resumeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted && !_isDisposed) {
        setState(() => _isUserInteracting = false);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final customColors = Theme.of(context).extension<AppColorsExtension>()!;
    final cs = Theme.of(context).colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: customColors.backgroundBaseColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        child: Stack(
          children: [
            // 3D model viewer
            Positioned(
              top: screenHeight * 0.18,
              left: 0,
              right: 0,
              child: SizedBox(
                height: screenHeight * 0.40,
                child: Listener(
                  onPointerDown: (_) => _onUserInteractionStart(),
                  onPointerUp: (_) => _onUserInteractionEnd(),
                  child: RepaintBoundary(
                    child: Flutter3DViewer(
                      controller: widget.modelController,
                      src: 'assets/models/fp2.glb',
                      progressBarColor: cs.primary,
                    ),
                  ),
                ),
              ),
            ),

            // Top bar: title + status
            Positioned(
              top: 60,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Agromotion',
                        style: TextStyle(
                          fontSize: 32,
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      AgroAppBar.buildActions(context),
                    ],
                  ),
                  HomeStatusIndicator(isOnline: _isOnline),
                ],
              ),
            ),

            // Bottom: chips + action button
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HomeBatteryChip(
                        level: _batteryLevel,
                        isCharging: _isCharging,
                      ),
                      const SizedBox(width: 12),
                      HomeChip(
                        icon: Icons.map_rounded,
                        label: 'Mapa',
                        iconColor: cs.primary,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HomeActionButton(
                    onTap: () {
                      _rotationTimer?.cancel();
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      ).then((_) => _startAutoRotation());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
