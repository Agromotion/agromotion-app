import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:agromotion/widgets/notifications/notification_tile.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/services/notification_service.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = theme.extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: _notificationService.streamNotifications(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final totalCount = docs.length;
                final pendingCount = docs
                    .where(
                      (d) =>
                          (d.data() as Map<String, dynamic>)['isRead'] == false,
                    )
                    .length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(theme, pendingCount, totalCount),
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        docs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (docs.isEmpty)
                      const SliverFillRemaining(
                        child: Center(
                          child: Text(
                            "Sem notificações",
                            style: TextStyle(color: Colors.white54),
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: context.horizontalPadding,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final doc = docs[index];
                            final data = doc.data() as Map<String, dynamic>;
                            final timestamp =
                                (data['timestamp'] as Timestamp?)?.toDate() ??
                                DateTime.now();
                            final bool isRead = data['isRead'] ?? false;

                            return Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) => _notificationService
                                  .deleteNotification(doc.id),
                              background: _buildDismissibleBackground(),
                              child: NotificationTile(
                                title: data['title'] ?? '',
                                message: data['message'] ?? '',
                                time: DateFormat('HH:mm').format(timestamp),
                                type: _mapType(data['type']),
                                isRead: isRead,
                                onTap: () => _notificationService.markAsRead(
                                  doc.id,
                                  status: !isRead,
                                ),
                              ),
                            );
                          }, childCount: docs.length),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme, int pending, int total) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => Navigator.pop(context),
              color: theme.colorScheme.onSurface,
              iconSize: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Notificações",
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "$pending Alertas pendentes",
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withAlpha(128),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded),
                        onPressed: pending > 0
                            ? () => _notificationService.markAllAsRead()
                            : null,
                        tooltip: "Marcar todas como lidas",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        color: theme.colorScheme.error.withAlpha(200),
                        onPressed: total > 0
                            ? () => _showConfirmClearDialog(theme)
                            : null,
                        tooltip: "Limpar tudo",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(Icons.delete_outline, color: Colors.red),
    );
  }

  void _showConfirmClearDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text("Limpar histórico?"),
        content: const Text(
          "Isto irá apagar permanentemente todas as suas notificações.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              _notificationService.clearAllNotifications();
              Navigator.pop(context);
            },
            child: Text(
              "Limpar",
              style: TextStyle(color: theme.colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  NotificationType _mapType(String? type) {
    switch (type) {
      case 'error':
        return NotificationType.error;
      case 'warning':
        return NotificationType.warning;
      case 'success':
        return NotificationType.success;
      default:
        return NotificationType.info;
    }
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          color: Theme.of(context).colorScheme.primary.withAlpha(180),
        ),
      ),
    );
  }
}
