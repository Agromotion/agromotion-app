import 'package:flutter/material.dart';

class ActivityItem extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  const ActivityItem({
    super.key,
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 10),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(time, style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
