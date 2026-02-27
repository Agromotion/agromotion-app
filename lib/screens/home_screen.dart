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
  const HomeScreen({super.key, required this.modelController});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  // Firestore data state
  bool _isOnline = false;
  String _batteryPercent = "0%";
  String get _robotId => AppConfig.robotId;

  StreamSubscription? _robotSubscription;
  bool _isDisposed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _listenToRobotStatus();
    widget.modelController.onModelLoaded.addListener(_onModelLoadedHandler);
  }

  /// Listen to the primary Firestore document for this robot
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

            setState(() {
              _isOnline = status['online'] ?? false;
              _batteryPercent = "${telemetry['battery_percentage'] ?? 0}%";
            });
          }
        });
  }

  void _onModelLoadedHandler() {
    if (!mounted || _isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_isDisposed) {
        try {
          widget.modelController.setCameraTarget(0, 0, 0);
        } catch (e) {
          debugPrint('3D Controller Error: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
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
    final bgColor = customColors.backgroundBaseColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        child: Stack(
          children: [
            // 3D Model View
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, -0.2),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: customColors.backgroundGradient,
                    ),
                    child: ClipRect(
                      child: ColoredBox(
                        color: bgColor,
                        child: Flutter3DViewer(
                          controller: widget.modelController,
                          src: 'assets/models/fp.glb',
                          progressBarColor: Colors.transparent,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // App Bar Actions
            Positioned(
              top: 40,
              right: 24,
              child: SafeArea(child: AgroAppBar.buildActions(context)),
            ),

            // Robot Info Title
            Positioned(
              top: 120,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Agromotion",
                    style: TextStyle(
                      fontSize: 32,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
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
                          fontSize: 18,
                          color: _isOnline ? colorScheme.primary : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Controls
            Positioned(
              bottom: 130,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  _buildTelemetryRow(colorScheme),
                  const SizedBox(height: 24),
                  _buildMainActionButton(customColors, colorScheme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTelemetryRow(ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChip(Icons.battery_charging_full, _batteryPercent, colorScheme),
        const SizedBox(width: 12),
        _buildMapButton(colorScheme),
      ],
    );
  }

  Widget _buildChip(IconData icon, String value, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface.withAlpha(128),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outline.withAlpha(26)),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: colorScheme.surface.withAlpha(128),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.outline.withAlpha(26)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              'Mapa',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const CameraScreen()),
      ),
      child: Container(
        height: 65,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: customColors.primaryButtonGradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withAlpha(77),
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
