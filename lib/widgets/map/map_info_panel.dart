import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

/// Bottom panel that shows user/robot coordinates, distance and speed.
///
/// ## Dark-mode contrast strategy
/// The map tiles (CartoDB Voyager) are always light/bright.  In dark mode the
/// semi-transparent glass panel lets the pale map bleed through, which makes
/// white text hard to read.  We therefore pass a solid (opaque) dark colour as
/// [GlassContainer.color] in dark mode so the panel has a proper dark
/// background.  The backdrop blur and gradient are still applied on top, giving
/// depth without sacrificing legibility.
class MapInfoPanel extends StatelessWidget {
  const MapInfoPanel({
    super.key,
    required this.userLocation,
    required this.robotLocation,
    required this.formattedDistance,
    required this.formattedSpeed,
    required this.hasRobotError,
    required this.accentColor,
    required this.isDark,
  });

  final LatLng? userLocation;
  final LatLng? robotLocation;
  final String formattedDistance;
  final String formattedSpeed;
  final bool hasRobotError;
  final Color accentColor;
  final bool isDark;

  // Solid dark fill used in dark mode so the bright Voyager map cannot bleed
  // through and wash out the text.
  static const Color _darkPanelColor = Color(0xFF1C2B24);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      // Solid background in dark mode; let GlassContainer default (surface
      // with alpha) in light mode — white map tiles behind white glass works.
      color: isDark ? _darkPanelColor : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LocationRow(
            icon: Icons.person_pin_circle,
            label: 'Eu',
            loc: userLocation,
            accentColor: accentColor,
            cs: cs,
          ),
          const SizedBox(height: 10),
          _LocationRow(
            icon: Icons.precision_manufacturing,
            label: 'Robô',
            loc: robotLocation,
            accentColor: accentColor,
            cs: cs,
          ),
          if (robotLocation != null) ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatChip(
                  icon: Icons.straighten,
                  label: 'Distância',
                  value: formattedDistance,
                  accentColor: accentColor,
                  cs: cs,
                ),
                _StatChip(
                  icon: Icons.speed,
                  label: 'Velocidade',
                  value: formattedSpeed,
                  accentColor: accentColor,
                  cs: cs,
                ),
              ],
            ),
          ],
          if (hasRobotError) const _ErrorBanner(),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _LocationRow extends StatelessWidget {
  const _LocationRow({
    required this.icon,
    required this.label,
    required this.loc,
    required this.accentColor,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final LatLng? loc;
  final Color accentColor;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
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
                color: cs.onSurface.withAlpha(130),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              loc != null
                  ? '${loc!.latitude.toStringAsFixed(5)}, '
                        '${loc!.longitude.toStringAsFixed(5)}'
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
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.cs,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: accentColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: cs.onSurface.withAlpha(130),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: cs.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Text(
        '⚠️ GPS do robô indisponível.',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
