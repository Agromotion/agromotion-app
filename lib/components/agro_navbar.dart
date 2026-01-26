import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Ajusta para o teu path

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
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(
          horizontal: isTablet ? size.width * 0.1 : 16,
          vertical: 16,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: colorScheme.outline, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(
                    context,
                    Icons.schedule_outlined,
                    Icons.schedule,
                    'Horário',
                    0,
                    isTablet,
                  ),
                  _buildNavItem(
                    context,
                    Icons.videocam_outlined,
                    Icons.videocam,
                    'Câmara',
                    1,
                    isTablet,
                  ),
                  _buildCenterNavItem(
                    context,
                    isTablet,
                    colorScheme,
                    customColors,
                  ),
                  _buildNavItem(
                    context,
                    Icons.bar_chart_outlined,
                    Icons.bar_chart,
                    'Stats',
                    3,
                    isTablet,
                  ),
                  _buildNavItem(
                    context,
                    Icons.people_outline,
                    Icons.people,
                    'Acessos',
                    4,
                    isTablet,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    IconData selectedIcon,
    String label,
    int index,
    bool isTablet,
  ) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;
    final activeColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withAlpha(60);

    return Expanded(
      child: InkWell(
        onTap: () => onDestinationSelected(index),
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: EdgeInsets.all(isTablet ? 10 : 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor.withAlpha(15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? selectedIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: isTablet ? 28 : 22,
              ),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 12 : 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(
    BuildContext context,
    bool isTablet,
    ColorScheme colorScheme,
    AppColorsExtension customColors,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = selectedIndex == 2;
    final double size = isTablet ? 60 : 52;

    final Decoration activeDecoration = BoxDecoration(
      gradient: isDark ? customColors.primaryButtonGradient : null,
      color: isDark ? null : colorScheme.primary, // Verde escuro no modo claro
      shape: BoxShape.circle,
      border: Border.all(
        color: isSelected ? colorScheme.primary : colorScheme.outline,
        width: 2,
      ),
      boxShadow: [
        if (isSelected)
          BoxShadow(
            color: colorScheme.primary.withAlpha(30),
            blurRadius: 15,
            spreadRadius: 2,
          ),
      ],
    );

    return GestureDetector(
      onTap: () => onDestinationSelected(2),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: size,
        height: size,
        margin: const Offset(8, 0).horizontal,
        decoration: isSelected
            ? activeDecoration
            : BoxDecoration(
                color: colorScheme.onSurface.withAlpha(5),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.outline, width: 2),
              ),
        child: Icon(
          isSelected ? Icons.home : Icons.home_outlined,
          color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
          size: isTablet ? 30 : 26,
        ),
      ),
    );
  }
}

extension on Offset {
  EdgeInsets get horizontal => EdgeInsets.symmetric(horizontal: dx);
}
