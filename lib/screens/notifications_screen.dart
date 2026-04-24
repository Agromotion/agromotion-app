import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/widgets/agro_loading.dart';
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
          body: StreamBuilder<QuerySnapshot>(
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
                  // 1. AppBar com Título e Subtítulo
                  AgroAppBar(
                    showBackButton: true,
                    title: 'Notificações',
                    subtitle: '$pendingCount Alertas pendentes',
                    showNotifications: false,
                    showSettings: false,
                  ),

                  // 2. Linha de Ações (Abaixo da AppBar)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: context.horizontalPadding,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.end, // Alinhado à direita
                        children: [
                          _ActionButton(
                            icon: Icons.done_all_rounded,
                            label: "Lidas",
                            onTap: pendingCount > 0
                                ? () => _notificationService.markAllAsRead()
                                : null,
                          ),
                          const SizedBox(width: 12),
                          _ActionButton(
                            icon: Icons.delete_sweep_outlined,
                            label: "Limpar",
                            isError: true,
                            onTap: totalCount > 0
                                ? () => _showConfirmClearDialog(theme)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. Conteúdo (Loading, Vazio ou Lista)
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      docs.isEmpty)
                    const SliverFillRemaining(
                      child: Center(child: AgroLoading()),
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
                      padding: EdgeInsets.fromLTRB(
                        context.horizontalPadding,
                        0,
                        context.horizontalPadding,
                        40,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final timestamp =
                              (data['timestamp'] as Timestamp?)?.toDate() ??
                              DateTime.now();
                          final bool isRead = data['isRead'] ?? false;

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) =>
                                _notificationService.deleteNotification(doc.id),
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
      ],
    );
  }

  Widget _buildDismissibleBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
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
          "Isto irá apagar permanentemente todas as notificações.",
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

// Widget auxiliar para os botões de ação abaixo da AppBar
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isError;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;

    return Opacity(
      opacity: onTap == null ? 0.4 : 1.0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
