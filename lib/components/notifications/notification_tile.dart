import 'package:flutter/material.dart';
import 'package:agromotion/components/glass_container.dart';

enum NotificationType { info, warning, success, error }

class NotificationTile extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final NotificationType type;
  final bool isRead;

  const NotificationTile({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  Color _getTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return Colors.amber;
      case NotificationType.success:
        return const Color(0xFFCDFF5E);
      case NotificationType.error:
        return Colors.redAccent;
      case NotificationType.info:
        return Colors.blueAccent;
    }
  }

  IconData _getTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.warning:
        return Icons.warning_amber_rounded;
      case NotificationType.success:
        return Icons.check_circle_outline_rounded;
      case NotificationType.error:
        return Icons.error_outline_rounded;
      case NotificationType.info:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getTypeColor(type);

    return Opacity(
      opacity: isRead ? 0.6 : 1.0,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(10),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getTypeIcon(type), color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withAlpha(40),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withAlpha(70),
                      ),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(left: 8, top: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
