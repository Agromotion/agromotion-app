import 'package:agromotion/components/notifications/notification_tile.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _email = FirebaseAuth.instance.currentUser?.email;

  CollectionReference get _notifRef => FirebaseFirestore.instance
      .collection('users')
      .doc(_email)
      .collection('notifications');

  Future<void> _markAllAsRead() async {
    final unread = await _notifRef.where('isRead', isEqualTo: false).get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> _clearAllNotifications() async {
    final allDocs = await _notifRef.get();
    final batch = FirebaseFirestore.instance.batch();
    for (var doc in allDocs.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> _dismissNotification(String id) async {
    await _notifRef.doc(id).delete();
  }

  Future<void> _toggleRead(String id, bool currentStatus) async {
    await _notifRef.doc(id).update({'isRead': !currentStatus});
  }

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
              stream: _notifRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final totalCount = docs.length; // Adiciona isto
                final pendingCount = docs
                    .where((d) => d['isRead'] == false)
                    .length;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildHeader(theme, pendingCount, totalCount),
                    if (docs.isEmpty && !snapshot.hasData)
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

                            return Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) =>
                                  _dismissNotification(doc.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(20),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                ),
                              ),
                              child: NotificationTile(
                                title: data['title'] ?? '',
                                message: data['message'] ?? '',
                                time: DateFormat('HH:mm').format(timestamp),
                                type: _mapType(data['type']),
                                isRead: data['isRead'] ?? false,
                                onTap: () => _toggleRead(
                                  doc.id,
                                  data['isRead'] ?? false,
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
                          color: theme.colorScheme.onSurface.withAlpha(50),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Botão Marcar como Lidas
                      IconButton(
                        icon: const Icon(Icons.done_all_rounded),
                        onPressed: pending > 0 ? _markAllAsRead : null,
                        tooltip: "Marcar todas como lidas",
                      ),
                      // NOVO: Botão Limpar Tudo
                      IconButton(
                        icon: const Icon(Icons.delete_sweep_outlined),
                        color: theme.colorScheme.error.withOpacity(0.8),
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

  // Dialog de confirmação para não apagar por acidente
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
              _clearAllNotifications();
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
          color: Theme.of(context).colorScheme.primary.withAlpha(70),
        ),
      ),
    );
  }
}
