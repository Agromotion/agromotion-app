import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agromotion/components/agro_appbar.dart';
import 'package:agromotion/screens/camera_screen.dart';
import 'package:agromotion/screens/map_screen.dart';
import '../theme/app_theme.dart';

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
  String _batteryPercent = "0%";
  String get _robotId => AppConfig.robotId;

  StreamSubscription? _robotSubscription;
  Timer? _rotationTimer;
  Timer? _resumeTimer;

  double _currentOrbitY = 0.0;

  // Inclinação para efeito carrossel
  final double _carouselTilt = 25;

  bool _isDisposed = false;
  bool _isUserInteracting = false;

  @override
  bool get wantKeepAlive => true;

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
      if (widget.isVisible) {
        _startAutoRotation();
      } else {
        _rotationTimer?.cancel();
      }
    }
  }

  void _listenToRobotStatus() {
    _robotSubscription = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (snap.exists && mounted && !_isDisposed) {
            final data = snap.data()!;
            final status = data['status'] as Map<String, dynamic>? ?? {};
            final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};

            if (mounted) {
              setState(() {
                _isOnline = status['online'] ?? false;
                _batteryPercent = "${telemetry['battery_percentage'] ?? 0}%";
              });
            }
          }
        });
  }

  void _onModelLoadedHandler() {
    if (!mounted || _isDisposed) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      widget.modelController.setCameraTarget(0, 0, 0);

      // Configuração inicial do carrossel
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

    _rotationTimer = Timer.periodic(
      const Duration(milliseconds: 16), // ~60 FPS
      (timer) {
        if (!mounted ||
            _isDisposed ||
            _isUserInteracting ||
            !widget.isVisible) {
          return;
        }

        // Rotação infinita suave
        _currentOrbitY = (_currentOrbitY + 0.6) % 360;

        try {
          widget.modelController.setCameraOrbit(
            _carouselTilt,
            _currentOrbitY + 90,
            100,
          );
        } catch (e) {
          debugPrint("Erro ao orbitar: $e");
        }
      },
    );
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

  @override
  void dispose() {
    _isDisposed = true;

    _rotationTimer?.cancel();
    _resumeTimer?.cancel();
    _robotSubscription?.cancel();

    widget.modelController.onModelLoaded.removeListener(_onModelLoadedHandler);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: customColors.backgroundBaseColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        child: Stack(
          children: [
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
                      progressBarColor: colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            _buildTopUI(colorScheme),
            Positioned(
              bottom: 110,
              left: 24,
              right: 24,
              child: _buildBottomContent(customColors, colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopUI(ColorScheme colorScheme) {
    return Positioned(
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
                "Agromotion",
                style: TextStyle(
                  fontSize: 32,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AgroAppBar.buildActions(context),
            ],
          ),
          _buildStatusIndicator(colorScheme),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isOnline ? colorScheme.primary : Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _isOnline ? "Online" : "Offline",
          style: TextStyle(
            fontSize: 16,
            color: _isOnline ? colorScheme.primary : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomContent(
    AppColorsExtension customColors,
    ColorScheme colorScheme,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildChip(
              Icons.battery_charging_full,
              _batteryPercent,
              colorScheme,
            ),
            const SizedBox(width: 12),
            _buildMapButton(colorScheme),
          ],
        ),
        const SizedBox(height: 16),
        _buildMainActionButton(customColors, colorScheme),
      ],
    );
  }

  Widget _buildChip(IconData icon, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(50),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapButton(ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(50),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          children: [
            Icon(Icons.map_rounded, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Mapa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionButton(
    AppColorsExtension customColors,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () {
        _rotationTimer?.cancel();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CameraScreen()),
        ).then((_) => _startAutoRotation());
      },
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: customColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(30),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            "CONDUZIR",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}
