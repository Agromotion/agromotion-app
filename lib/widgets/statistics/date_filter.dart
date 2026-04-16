import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DateFilterProvider extends ChangeNotifier {
  int _selectedIndex = 0; // 0: 24H, 1: 7D, 2: 30D, 3: Custom
  DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(hours: 24)),
    end: DateTime.now(),
  );

  int get selectedIndex => _selectedIndex;
  DateTimeRange get range => _range;

  void setFilter(int index) {
    if (index == 3) return;

    _selectedIndex = index;
    final now = DateTime.now();

    if (index == 0) {
      _range = DateTimeRange(
        start: now.subtract(const Duration(hours: 24)),
        end: now,
      );
    } else if (index == 1) {
      _range = DateTimeRange(
        start: now.subtract(const Duration(days: 7)),
        end: now,
      );
    } else if (index == 2) {
      _range = DateTimeRange(
        start: now.subtract(const Duration(days: 30)),
        end: now,
      );
    }

    notifyListeners();
  }

  void setCustomRange(DateTimeRange newRange) {
    _selectedIndex = 3;
    _range = newRange;
    notifyListeners();
  }
}

class DateFilter extends StatelessWidget {
  // Devolvemos os parâmetros ao construtor para que a StatisticsScreen possa reagir
  final int selected;
  final ValueChanged<int> onChanged;
  final VoidCallback onCustomPressed;

  const DateFilter({
    super.key,
    required this.selected,
    required this.onChanged,
    required this.onCustomPressed,
  });

  static const _labels = ['24H', '7D', '30D'];

  @override
  Widget build(BuildContext context) {
    final filterProvider = context.watch<DateFilterProvider>();

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
            label: selected == 3
                ? '${filterProvider.range.start.day}/${filterProvider.range.start.month} - ${filterProvider.range.end.day}/${filterProvider.range.end.month}'
                : 'Custom',
            icon: Icons.calendar_today_rounded,
            isSelected: selected == 3,
            onTap: onCustomPressed,
          ),
        ],
      ),
    );
  }
}

/// SUB-WIDGET DE ESTILO (CHIP)
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

    return InkWell(
      // Adicionado para feedback visual de toque em todas as plataformas
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
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
