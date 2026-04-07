import 'package:flutter/material.dart';

class DateFilter extends StatelessWidget {
  const DateFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    this.onCustomPressed,
  });

  final int selected;
  final ValueChanged<int> onChanged;
  final VoidCallback? onCustomPressed;

  static const _labels = ['24H', '7D', '30D'];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ..._labels.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _FilterChip(
                label: e.value,
                isSelected: selected == e.key,
                onTap: () => onChanged(e.key),
              ),
            ),
          ),
          _FilterChip(
            label: 'Custom',
            icon: Icons.calendar_today_rounded,
            isSelected: selected == 3,
            onTap: onCustomPressed ?? () {},
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primary.withAlpha(isDark ? 50 : 30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isSelected ? cs.primary : cs.onSurface.withAlpha(120),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? cs.primary : cs.onSurface.withAlpha(140),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
