class DateRangeFilter {
  final DateTime start;
  final DateTime end;
  final int selectedIndex; // 0: 24H, 1: 7D, 2: 30D, 3: Custom

  DateRangeFilter({
    required this.start,
    required this.end,
    required this.selectedIndex,
  });
}
