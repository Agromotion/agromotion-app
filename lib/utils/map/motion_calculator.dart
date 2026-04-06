import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

/// Calculates speed and heading from consecutive GPS positions.
///
/// Both methods share the same [minMovementMeters] threshold: if the distance
/// between the two points is smaller than this value we treat the entity as
/// stationary and return 0 / null accordingly.  This prevents GPS noise from
/// producing phantom speed or jittery heading arrows while standing still.
class MotionCalculator {
  MotionCalculator._();

  /// Minimum real-world displacement required before we trust the values.
  static const double minMovementMeters = 0.5;

  // ---------------------------------------------------------------------------
  // Speed
  // ---------------------------------------------------------------------------

  static double metersPerSecond({
    required LatLng from,
    required LatLng to,
    required Duration elapsed,
  }) {
    if (elapsed.inMilliseconds <= 0) return 0;
    final distanceM = const Distance().as(LengthUnit.Meter, from, to);
    if (distanceM < minMovementMeters) return 0;
    return distanceM / (elapsed.inMilliseconds / 1000.0);
  }

  static double kmh({
    required LatLng from,
    required LatLng to,
    required Duration elapsed,
  }) => metersPerSecond(from: from, to: to, elapsed: elapsed) * 3.6;

  // ---------------------------------------------------------------------------
  // Heading
  // ---------------------------------------------------------------------------

  /// Returns the bearing in **radians** (0 = North, clockwise) from [from] to
  /// [to], or `null` if the displacement is below [minMovementMeters].
  ///
  /// Returning radians directly means callers can pass it straight to
  /// [Transform.rotate] without an extra conversion.
  static double? headingRadians({required LatLng from, required LatLng to}) {
    final distanceM = const Distance().as(LengthUnit.Meter, from, to);
    if (distanceM < minMovementMeters) return null;

    final lat1 = _toRad(from.latitude);
    final lat2 = _toRad(to.latitude);
    final dLon = _toRad(to.longitude - from.longitude);

    final x = math.sin(dLon) * math.cos(lat2);
    final y =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    // atan2 gives bearing in radians where 0 = East (math convention).
    // We rotate by -π/2 to make 0 = North (map convention).
    return math.atan2(x, y);
  }

  /// Same as [headingRadians] but returns degrees (0–360, clockwise from North),
  /// or `null` when stationary.  Useful for display labels.
  static double? headingDegrees({required LatLng from, required LatLng to}) {
    final rad = headingRadians(from: from, to: to);
    if (rad == null) return null;
    return (_toDeg(rad) + 360) % 360;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;
}
