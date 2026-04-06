import 'package:agromotion/models/battery_state.dart';
import 'package:agromotion/widgets/home/home_chip.dart';
import 'package:flutter/material.dart'; 

/// Battery chip that shows level, charging state, and colour-coded icon.
class HomeBatteryChip extends StatelessWidget {
  const HomeBatteryChip({
    super.key,
    required this.level,
    required this.isCharging,
  });

  final int level;
  final bool isCharging;

  @override
  Widget build(BuildContext context) {
    final battery = BatteryState.from(level: level, isCharging: isCharging);

    return HomeChip(
      icon: battery.icon,
      label: battery.label,
      iconColor: battery.color,
    );
  }
}