import 'package:flutter/material.dart';

/// Derives the visual representation of the battery based on [level] (0–100)
/// and [isCharging].
///
/// Priority rule: charging always wins → yellow bolt icon, regardless of level.
///
/// When not charging:
///   < 15 %  → red    (critical)
///   < 50 %  → orange (low)
///   ≥ 50 %  → green  (good)
class BatteryState {
  BatteryState._({
    required this.icon,
    required this.color,
    required this.label,
  });

  factory BatteryState.from({
    required int level,
    required bool isCharging,
  }) {
    if (isCharging) {
      return BatteryState._(
        icon: Icons.battery_charging_full_rounded,
        color: const Color(0xFFFDD835), // yellow
        label: '$level% ⚡',
      );
    }

    final Color color;
    final IconData icon;

    if (level < 15) {
      color = const Color(0xFFE53935); // red
      icon = Icons.battery_alert_rounded;
    } else if (level < 50) {
      color = const Color(0xFFFB8C00); // orange
      icon = Icons.battery_3_bar_rounded;
    } else {
      color = const Color(0xFF43A047); // green
      icon = Icons.battery_full_rounded;
    }

    return BatteryState._(
      icon: icon,
      color: color,
      label: '$level%',
    );
  }

  final IconData icon;
  final Color color;
  final String label;
}