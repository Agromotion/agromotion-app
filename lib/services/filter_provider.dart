import 'package:agromotion/models/date_range_filter.dart';
import 'package:flutter/material.dart';

class FilterProvider extends ChangeNotifier {
  DateRangeFilter _currentFilter = DateRangeFilter(
    start: DateTime.now().subtract(const Duration(hours: 24)),
    end: DateTime.now(),
    selectedIndex: 0,
  );

  DateRangeFilter get currentFilter => _currentFilter;

  void setFilter(int index) {
    DateTime now = DateTime.now();
    DateTime start;

    switch (index) {
      case 0: // 24H
        start = now.subtract(const Duration(hours: 24));
        break;
      case 1: // 7D
        start = now.subtract(const Duration(days: 7));
        break;
      case 2: // 30D
        start = now.subtract(const Duration(days: 30));
        break;
      default:
        return; // Não altera se for custom por aqui
    }

    _currentFilter = DateRangeFilter(
      start: start,
      end: now,
      selectedIndex: index,
    );
    notifyListeners();
  }

  void setCustomRange(DateTime start, DateTime end) {
    _currentFilter = DateRangeFilter(start: start, end: end, selectedIndex: 3);
    notifyListeners();
  }
}
