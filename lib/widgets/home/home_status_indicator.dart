import 'package:flutter/material.dart';

/// Small coloured dot + text indicating whether the robot is reachable.
class HomeStatusIndicator extends StatelessWidget {
  const HomeStatusIndicator({super.key, required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = isOnline ? cs.primary : Colors.grey;

    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          isOnline ? 'Online' : 'Offline',
          style: TextStyle(
            fontSize: 16,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}