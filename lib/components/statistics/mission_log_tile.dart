import 'package:flutter/material.dart';
import '../glass_container.dart';

class MissionLogTile extends StatelessWidget {
  final String date;
  final String status;
  final String qty;
  final IconData icon;
  final Color statusColor;

  const MissionLogTile({
    super.key,
    required this.date,
    required this.status,
    required this.qty,
    required this.icon,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          title: Text(
            date,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            status,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withAlpha(60),
            ),
          ),
          trailing: Text(
            qty,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
