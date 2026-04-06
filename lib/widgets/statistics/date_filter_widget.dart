import 'package:flutter/material.dart';
import '../glass_container.dart';

class DateFilterWidget extends StatelessWidget {
  final int selectedFilter;
  final Function(int) onFilterChanged;
  final VoidCallback onCustomDatePressed;

  const DateFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onCustomDatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PERÍODO',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            color: colorScheme.primary.withAlpha(80),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('24H', 0, colorScheme, onFilterChanged),
              const SizedBox(width: 10),
              _buildFilterButton('7 dias', 1, colorScheme, onFilterChanged),
              const SizedBox(width: 10),
              _buildFilterButton('30 dias', 2, colorScheme, onFilterChanged),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: onCustomDatePressed,
                child: GlassContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  borderRadius: 20,
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: selectedFilter == 3
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Custom.',
                        style: TextStyle(
                          color: selectedFilter == 3
                              ? colorScheme.primary
                              : colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildFilterButton(
    String label,
    int index,
    ColorScheme colorScheme,
    Function(int) onFilterChanged,
  ) {
    return GestureDetector(
      onTap: () => onFilterChanged(index),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        borderRadius: 20,
        child: Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
