import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

/// Builds map markers used by [MapScreen].
///
/// The **user** marker is no longer here — it is handled entirely by
/// [CurrentLocationLayer] from `flutter_map_location_marker`, which provides
/// the compass heading, accuracy circle, and smooth animations out of the box.
///
/// The **robot** marker is a proper painted marker: a filled circle with a
/// directional arrow sector (similar to the location marker style) plus a
/// small robot icon label underneath for quick identification.
class MapMarkers {
  MapMarkers._();

  // ---------------------------------------------------------------------------
  // Robot marker
  // ---------------------------------------------------------------------------

  /// [accentColor]  — fill colour of the marker circle and arrow.
  /// [headingRad]   — bearing in radians (0 = North, clockwise).
  ///                  Pass `null` when the robot is stationary — the arrow
  ///                  sector is hidden and the circle is shown without direction.
  static Marker robot(LatLng point, Color accentColor, {double? headingRad}) =>
      Marker(
        point: point,
        width: 72,
        height: 72,
        alignment: Alignment.center,
        child: _RobotMarker(accentColor: accentColor, headingRad: headingRad),
      );

  // ---------------------------------------------------------------------------
  // Distance badge
  // ---------------------------------------------------------------------------

  static Marker distanceBadge({
    required LatLng point,
    required String label,
    required Color accentColor,
    Color textColor = Colors.white,
  }) => Marker(
    point: point,
    width: 100,
    height: 40,
    child: Container(
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 6),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Robot marker widget
// ---------------------------------------------------------------------------

class _RobotMarker extends StatelessWidget {
  const _RobotMarker({required this.accentColor, this.headingRad});

  final Color accentColor;
  final double? headingRad;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(72, 72),
      painter: _RobotMarkerPainter(color: accentColor, headingRad: headingRad),
      // Robot icon centred inside the circle
      child: Center(
        child: Icon(
          Icons.precision_manufacturing_rounded,
          color: Colors.white,
          size: 22,
          shadows: [Shadow(color: accentColor.withAlpha(180), blurRadius: 4)],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Robot marker painter
// ---------------------------------------------------------------------------

/// Draws:
///  1. A soft shadow/halo behind the circle for depth.
///  2. A filled circle in [color] (with white border).
///  3. When [headingRad] is not null: a teardrop/arrow sector extending from
///     the circle in the direction of travel, styled like a navigation pointer.
class _RobotMarkerPainter extends CustomPainter {
  const _RobotMarkerPainter({required this.color, this.headingRad});

  final Color color;
  final double? headingRad;

  // The circle occupies the inner 40×40 area, centred in the 72×72 canvas.
  static const double _circleRadius = 20.0;
  // How far the arrow tip extends past the circle edge.
  static const double _arrowLength = 16.0;
  // Half-angle of the arrow sector in radians (~30°).
  static const double _arrowHalfAngle = 0.52;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // ── 1. Shadow ────────────────────────────────────────────────────────────
    canvas.drawCircle(
      center + const Offset(0, 2),
      _circleRadius + 2,
      Paint()
        ..color = Colors.black.withAlpha(40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // ── 2. Directional arrow sector ──────────────────────────────────────────
    if (headingRad != null) {
      final sectorPaint = Paint()
        ..color = color.withAlpha(220)
        ..style = PaintingStyle.fill;

      // The sector starts at the circle edge and tapers to a point.
      final tipDistance = _circleRadius + _arrowLength;
      final tip = Offset(
        center.dx + tipDistance * math.sin(headingRad!),
        center.dy - tipDistance * math.cos(headingRad!),
      );
      final leftAngle = headingRad! - _arrowHalfAngle;
      final rightAngle = headingRad! + _arrowHalfAngle;
      final leftBase = Offset(
        center.dx + _circleRadius * math.sin(leftAngle),
        center.dy - _circleRadius * math.cos(leftAngle),
      );
      final rightBase = Offset(
        center.dx + _circleRadius * math.sin(rightAngle),
        center.dy - _circleRadius * math.cos(rightAngle),
      );

      final arrowPath = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(leftBase.dx, leftBase.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: _circleRadius),
          math.pi / 2 + math.pi + leftAngle, // start angle in Flutter coords
          _arrowHalfAngle * 2,
          false,
        )
        ..lineTo(tip.dx, tip.dy)
        ..close();

      // White outline on the arrow for contrast on light tiles
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = Colors.white.withAlpha(200)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeJoin = StrokeJoin.round,
      );
      canvas.drawPath(arrowPath, sectorPaint);
    }

    // ── 3. Circle fill ───────────────────────────────────────────────────────
    canvas.drawCircle(center, _circleRadius, Paint()..color = color);

    // ── 4. Circle white border ───────────────────────────────────────────────
    canvas.drawCircle(
      center,
      _circleRadius,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(_RobotMarkerPainter old) =>
      old.color != color || old.headingRad != headingRad;
}
