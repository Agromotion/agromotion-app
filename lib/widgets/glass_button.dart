import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  const GlassButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bool isSmall = context.isSmall;
    final double iconSize = isSmall ? 20.0 : 24.0;
    final double containerSize = isSmall ? 38.0 : 42.0;

    final color = Theme.of(context).colorScheme.onSurface;

    Widget button = GlassContainer(
      borderRadius: 32,
      child: SizedBox(
        width: containerSize,
        height: containerSize,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(32),
            child: Icon(icon, size: iconSize, color: color),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
