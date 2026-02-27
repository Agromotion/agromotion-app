import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:agromotion/components/glass_container.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String get _robotId => AppConfig.robotId;

  LatLng? _userLocation;
  LatLng? _robotLocation;
  StreamSubscription? _robotSub;
  StreamSubscription? _userSub;
  bool _hasRobotError = false;

  @override
  void initState() {
    super.initState();
    _initUserLocation();
    _listenToRobot();
  }

  Future<void> _initUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
    }

    _userSub = Geolocator.getPositionStream().listen((pos) {
      if (mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  void _listenToRobot() {
    _robotSub = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (snap.exists && mounted) {
            final data = snap.data()!;
            final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};
            final lat = telemetry['gps_latitude'];
            final lon = telemetry['gps_longitude'];
            final isValid = telemetry['gps_is_valid'] ?? false;

            if (lat != null && lon != null && lat != 0 && isValid) {
              setState(() {
                _robotLocation = LatLng(lat, lon);
                _hasRobotError = false;
              });
            } else {
              setState(() => _hasRobotError = true);
            }
          }
        });
  }

  double get _distanceInMeters {
    if (_userLocation == null || _robotLocation == null) return 0;
    return const Distance().as(
      LengthUnit.Meter,
      _userLocation!,
      _robotLocation!,
    );
  }

  String get _formattedDistance {
    if (_distanceInMeters >= 1000) {
      return '${(_distanceInMeters / 1000).toStringAsFixed(2)} km';
    }
    return '${_distanceInMeters.toStringAsFixed(0)} m';
  }

  LatLng get _midPoint {
    if (_userLocation != null && _robotLocation != null) {
      return LatLng(
        (_userLocation!.latitude + _robotLocation!.latitude) / 2,
        (_userLocation!.longitude + _robotLocation!.longitude) / 2,
      );
    }
    return _userLocation ?? const LatLng(0, 0);
  }

  // --- AJUSTE DE CORES PARA MAPA ---
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Se estiver no modo claro, usamos uma cor mais escura para a linha e ícones
    // para não "desaparecerem" no fundo branco do mapa.
    final accentColor = isDark
        ? colorScheme.primary
        : const Color(0xFF1B5E20); // Verde floresta no modo claro
    final polylineColor = accentColor.withAlpha(70);

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(38.736, -9.142),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate: isDark
                    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png' // Mapa Escuro
                    : 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png', // Mapa Claro
                subdomains: const ['a', 'b', 'c', 'd'],
              ),
              if (_userLocation != null && _robotLocation != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_userLocation!, _robotLocation!],
                      strokeWidth: 4.0,
                      color: polylineColor,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_userLocation != null) _buildUserMarker(isDark),
                  if (_robotLocation != null) _buildRobotMarker(accentColor),
                ],
              ),
              if (_userLocation != null && _robotLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _midPoint,
                      width: 100,
                      height: 40,
                      child: _buildDistanceBadge(accentColor),
                    ),
                  ],
                ),
            ],
          ),
          _buildUIOverlay(context, colorScheme, isDark, accentColor),
        ],
      ),
    );
  }

  // Melhorei o marcador do utilizador para ter contorno sempre visível
  Marker _buildUserMarker(bool isDark) => Marker(
    point: _userLocation!,
    width: 50,
    height: 50,
    child: Icon(
      Icons.person_pin_circle,
      color: Colors.blue.shade700,
      size: 40,
      shadows: const [Shadow(color: Colors.white, blurRadius: 10)],
    ),
  );

  Marker _buildRobotMarker(Color accentColor) => Marker(
    point: _robotLocation!,
    width: 50,
    height: 50,
    child: Icon(
      Icons.precision_manufacturing,
      color: accentColor,
      size: 40,
      shadows: const [Shadow(color: Colors.white, blurRadius: 10)],
    ),
  );

  Widget _buildDistanceBadge(Color accentColor) {
    return Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 4),
        ],
      ),
      child: Center(
        child: Text(
          _formattedDistance,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUIOverlay(
    BuildContext context,
    ColorScheme colorScheme,
    bool isDark,
    Color accentColor,
  ) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 10,
            left: 20,
            child: _buildGlassButton(
              Icons.chevron_left_rounded,
              () => Navigator.pop(context),
              colorScheme,
              isDark,
            ),
          ),
          Positioned(
            right: 20,
            bottom: 220,
            child: Column(
              children: [
                _buildGlassButton(
                  Icons.my_location,
                  () {
                    if (_userLocation != null) {
                      _mapController.move(_userLocation!, 16.0);
                    }
                  },
                  colorScheme,
                  isDark,
                ),
                const SizedBox(height: 12),
                if (_robotLocation != null)
                  _buildGlassButton(
                    Icons.precision_manufacturing,
                    () => _mapController.move(_robotLocation!, 16.0),
                    colorScheme,
                    isDark,
                  ),
              ],
            ),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GlassContainer(
              // No modo claro, aumentamos a opacidade do vidro para não confundir com o mapa
              padding: const EdgeInsets.all(16),
              borderRadius: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLocationRow(
                    Icons.person_pin_circle,
                    'Eu',
                    _userLocation,
                    accentColor,
                    colorScheme,
                  ),
                  const SizedBox(height: 10),
                  _buildLocationRow(
                    Icons.precision_manufacturing,
                    'Robô',
                    _robotLocation,
                    accentColor,
                    colorScheme,
                  ),
                  if (_robotLocation != null) ...[
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.straighten, size: 18, color: accentColor),
                        const SizedBox(width: 8),
                        Text(
                          'Distância: $_formattedDistance',
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_hasRobotError) _buildErrorState(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow(
    IconData icon,
    String label,
    LatLng? loc,
    Color accentColor,
    ColorScheme cs,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20, color: accentColor),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withAlpha(50),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              loc != null
                  ? '${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}'
                  : 'A localizar...',
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassButton(
    IconData icon,
    VoidCallback onTap,
    ColorScheme cs,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 50,
        // No modo claro, o ícone deve ser escuro. No modo escuro, deve ser claro.
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 26,
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        '⚠️ GPS do robô indisponível.',
        style: TextStyle(
          color: Colors.red.shade700,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _robotSub?.cancel();
    _userSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }
}
