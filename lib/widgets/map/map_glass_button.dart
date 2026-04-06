import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';

/// A circular frosted-glass icon button used in the map overlay.
///
/// In dark mode the icon is white; in light mode it is near-black.
/// The GlassContainer itself remains translucent in both modes — it sits
/// directly over the map so a little transparency is desirable.
class MapGlassButton extends StatelessWidget {
  const MapGlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: 50,
        child: Icon(
          icon,
          color: isDark ? Colors.white : Colors.black87,
          size: 26,
        ),
      ),
    );
  }
}
