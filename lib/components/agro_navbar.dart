import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AgroNavBar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onDestinationSelected;

  const AgroNavBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.only(bottom: 20),
        alignment: Alignment.bottomCenter,
        child: IntrinsicWidth(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surface.withAlpha(50),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: colorScheme.outline.withAlpha(10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPillItem(context, Icons.schedule_outlined, 'Agenda', 0),
                const SizedBox(width: 12),
                _buildHomeButton(customColors, colorScheme),
                const SizedBox(width: 12),
                _buildPillItem(
                  context,
                  Icons.bar_chart_rounded,
                  'Estatísticas',
                  2,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPillItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = selectedIndex == index;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onDestinationSelected(index),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withOpacity(0.15)
                  : colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeButton(
    AppColorsExtension customColors,
    ColorScheme colorScheme,
  ) {
    // Verifica se o índice atual é o da Home (1)
    final bool isSelected = selectedIndex == 1;

    return GestureDetector(
      onTap: () => onDestinationSelected(1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: isSelected ? customColors.primaryButtonGradient : null,
          color: isSelected ? null : colorScheme.onSurface.withOpacity(0.1),
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [], // Remove sombra quando não selecionado
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : colorScheme.outline.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          isSelected ? Icons.home : Icons.home_outlined,
          color: isSelected
              ? colorScheme.onPrimary
              : colorScheme.onSurface.withOpacity(0.6),
          size: 30,
        ),
      ),
    );
  }
}
