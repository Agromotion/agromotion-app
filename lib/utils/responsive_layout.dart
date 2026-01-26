import 'package:flutter/material.dart';

extension ResponsiveLayout on BuildContext {
  static const double _smallBreakpoint = 600.0;
  static const double _wideBreakpoint = 900.0;

  double get screenWidth => MediaQuery.of(this).size.width;
  double get screenHeight => MediaQuery.of(this).size.height;

  bool get isSmall => screenWidth < _smallBreakpoint;
  bool get isMedium =>
      screenWidth >= _smallBreakpoint && screenWidth <= _wideBreakpoint;
  bool get isWide => screenWidth > _wideBreakpoint;
  bool get isTablet => screenWidth >= _smallBreakpoint;

  double get horizontalPadding {
    if (isWide) return screenWidth * 0.1;
    if (isMedium) return 32.0;
    return 16.0;
  }

  int get gridCrossAxisCount {
    if (isWide) return 4;
    if (isMedium) return 3;
    return 2;
  }
}
