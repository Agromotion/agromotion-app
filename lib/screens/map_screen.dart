import 'dart:async';
import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/utils/map/motion_calculator.dart';
import 'package:agromotion/widgets/glass_button.dart';
import 'package:agromotion/widgets/map/map_info_panel.dart';
import 'package:agromotion/widgets/map/map_markers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// ## User location
/// Delegated entirely to [CurrentLocationLayer] from
/// `flutter_map_location_marker`.  It handles GPS permissions, the position
/// stream, compass heading, accuracy circle and smooth animations
/// automatically.  We share its default position stream so we can still read
/// the current user position for the distance/midpoint calculation without
/// running a second Geolocator subscription.
///
/// ## Robot location
/// Streamed from Firestore.  Speed and heading are derived from consecutive
/// positions using [MotionCalculator].
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  String get _robotId => AppConfig.robotId;

  // ── User (read from CurrentLocationLayer's shared stream) ─────────────────
  LatLng? _userLocation;
  // The stream is created once and shared between CurrentLocationLayer and our
  // StreamSubscription so we don't open two parallel GPS sessions.
  late final Stream<LocationMarkerPosition?> _positionStream;
  StreamSubscription<LocationMarkerPosition?>? _positionSub;

  // ── Robot ─────────────────────────────────────────────────────────────────
  LatLng? _robotLocation;
  DateTime? _lastRobotTime;
  double _robotSpeedKmh = 0;
  double? _robotHeadingRad;

  StreamSubscription? _robotSub;
  bool _hasRobotError = false;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Share the default position stream between the layer and our subscription.
    _positionStream = const LocationMarkerDataStreamFactory()
        .fromGeolocatorPositionStream()
        .asBroadcastStream();

    _positionSub = _positionStream.listen((pos) {
      if (pos != null && mounted) {
        setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      }
    });

    _listenToRobot();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _robotSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Robot stream
  // -------------------------------------------------------------------------

  void _listenToRobot() {
    _robotSub = FirebaseFirestore.instance
        .collection('robots')
        .doc(_robotId)
        .snapshots()
        .listen((snap) {
          if (!snap.exists || !mounted) return;

          final data = snap.data()!;
          final telemetry = data['telemetry'] as Map<String, dynamic>? ?? {};
          final lat = telemetry['gps_latitude'];
          final lon = telemetry['gps_longitude'];
          final isValid = telemetry['gps_is_valid'] ?? false;

          if (lat != null && lon != null && lat != 0 && isValid) {
            final newLocation = LatLng(lat as double, lon as double);
            final now = DateTime.now();

            setState(() {
              _hasRobotError = false;
              if (_robotLocation != null && _lastRobotTime != null) {
                _robotSpeedKmh = MotionCalculator.kmh(
                  from: _robotLocation!,
                  to: newLocation,
                  elapsed: now.difference(_lastRobotTime!),
                );
                _robotHeadingRad = MotionCalculator.headingRadians(
                  from: _robotLocation!,
                  to: newLocation,
                );
              }
              _robotLocation = newLocation;
              _lastRobotTime = now;
            });
          } else {
            setState(() => _hasRobotError = true);
          }
        });
  }

  // -------------------------------------------------------------------------
  // Derived values
  // -------------------------------------------------------------------------

  double get _distanceInMeters {
    if (_userLocation == null || _robotLocation == null) return 0;
    return const Distance().as(
      LengthUnit.Meter,
      _userLocation!,
      _robotLocation!,
    );
  }

  String get _formattedDistance => _distanceInMeters >= 1000
      ? '${(_distanceInMeters / 1000).toStringAsFixed(2)} km'
      : '${_distanceInMeters.toStringAsFixed(0)} m';

  String get _formattedSpeed => '${_robotSpeedKmh.toStringAsFixed(1)} km/h';

  LatLng get _midPoint {
    if (_userLocation != null && _robotLocation != null) {
      return LatLng(
        (_userLocation!.latitude + _robotLocation!.latitude) / 2,
        (_userLocation!.longitude + _robotLocation!.longitude) / 2,
      );
    }
    return _userLocation ?? const LatLng(0, 0);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = cs.primary;
    final polylineColor = accent.withAlpha(isDark ? 160 : 90);
    final badgeBg = isDark ? const Color(0xFF1C2B24) : accent;
    final badgeText = isDark ? accent : cs.onPrimary;

    // Style the CurrentLocationLayer to match the app theme.
    final locationStyle = LocationMarkerStyle(
      marker: DefaultLocationMarker(
        color: Colors.blue.shade700,
        child: const Icon(Icons.navigation, color: Colors.white, size: 14),
      ),
      markerSize: const Size(36, 36),
      markerDirection: MarkerDirection.heading,
      showAccuracyCircle: true,
      accuracyCircleColor: Colors.blue.withAlpha(25),
      showHeadingSector: true,
      headingSectorRadius: 60,
      headingSectorColor: Colors.blue.withAlpha(50),
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation ?? const LatLng(38.736, -9.142),
              initialZoom: 16.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
              ),

              // User location — handled by the package (compass, accuracy, animations)
              CurrentLocationLayer(
                positionStream: _positionStream,
                style: locationStyle,
              ),

              // Polyline user ↔ robot
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

              // Robot marker
              if (_robotLocation != null)
                MarkerLayer(
                  markers: [
                    MapMarkers.robot(
                      _robotLocation!,
                      accent,
                      headingRad: _robotHeadingRad,
                    ),
                  ],
                ),

              // Distance badge at midpoint
              if (_userLocation != null && _robotLocation != null)
                MarkerLayer(
                  markers: [
                    MapMarkers.distanceBadge(
                      point: _midPoint,
                      label: _formattedDistance,
                      accentColor: badgeBg,
                      textColor: badgeText,
                    ),
                  ],
                ),
            ],
          ),

          // ── UI overlay ─────────────────────────────────────────────────────
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 10,
                  left: 20,
                  child: GlassButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                Positioned(
                  right: 20,
                  bottom: 220,
                  child: Column(
                    children: [
                      GlassButton(
                        icon: Icons.my_location,
                        onTap: () {
                          if (_userLocation != null) {
                            _mapController.move(_userLocation!, 16.0);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      if (_robotLocation != null)
                        GlassButton(
                          icon: Icons.precision_manufacturing,
                          onTap: () =>
                              _mapController.move(_robotLocation!, 16.0),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: MapInfoPanel(
                    userLocation: _userLocation,
                    robotLocation: _robotLocation,
                    formattedDistance: _formattedDistance,
                    formattedSpeed: _formattedSpeed,
                    hasRobotError: _hasRobotError,
                    accentColor: accent,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
