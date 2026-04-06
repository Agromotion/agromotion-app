import 'package:flutter/material.dart';

/// A pill-shaped info chip that adapts to light and dark themes.
///
/// In dark mode the background stays semi-transparent (glass-like).
/// In light mode it uses the surface colour at full opacity so the label
/// doesn't get lost on a light background.
class HomeChip extends StatelessWidget {
  const HomeChip({
    super.key,
    required this.icon,
    required this.label,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Dark: translucent glass feel.  Light: opaque surface so text is legible.
    final bgColor = isDark
        ? cs.surface.withAlpha(50)
        : cs.surfaceContainerHighest;

    final borderColor = isDark ? Colors.white10 : cs.outlineVariant;

    final textColor = isDark ? Colors.white : cs.onSurface;

    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return chip;
    return GestureDetector(onTap: onTap, child: chip);
  }
}