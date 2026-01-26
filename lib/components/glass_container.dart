import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Ajuste conforme a sua estrutura

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blur;
  final Color? color;
  final Border? border;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding,
    this.blur = 10,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorsExtension>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(borderRadius),
            border:
                border ??
                Border.all(color: theme.colorScheme.outline, width: 1.5),
            gradient: customColors?.glassGradient,
          ),
          child: child,
        ),
      ),
    );
  }
}
