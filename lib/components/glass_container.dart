import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  const GlassContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final cardTheme = Theme.of(context).cardTheme;
    final shape = cardTheme.shape;

    // Extrai a BorderSide se o shape for RoundedRectangleBorder
    BorderSide? borderSide;
    if (shape is RoundedRectangleBorder) {
      borderSide = shape.side;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: cardTheme.color,
            borderRadius: BorderRadius.circular(24),
            border: borderSide != null && borderSide.style != BorderStyle.none
                ? Border.fromBorderSide(borderSide)
                : Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: child,
        ),
      ),
    );
  }
}
