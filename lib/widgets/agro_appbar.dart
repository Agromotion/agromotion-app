import 'package:agromotion/widgets/agro_backbutton.dart';
import 'package:agromotion/widgets/glass_button.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:agromotion/widgets/home/home_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';

class AgroAppBar extends StatelessWidget {
  final bool isOnline;
  final bool showBackButton;
  final bool showNotifications;
  final bool showSettings;
  final String? title;
  final String? subtitle;
  final bool showStatus;

  const AgroAppBar({
    super.key,
    this.showBackButton = false,
    this.showNotifications = true,
    this.showSettings = true,
    this.isOnline = true,
    this.title,
    this.subtitle,
    this.showStatus = false,
  });

  // Altura reduzida para evitar espaço livre excessivo
  double get _toolbarHeight {
    double height = kToolbarHeight + 10;
    if (title != null) height += 25;
    if (showStatus || subtitle != null) height += 20;
    return height;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: false,
      toolbarHeight: _toolbarHeight,
      automaticallyImplyLeading: false,
      flexibleSpace: _buildFlexibleSpace(context, theme),
    );
  }

  Widget _buildFlexibleSpace(BuildContext context, ThemeData theme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (showBackButton) ...[
                  const AgroBackButton(),
                  const SizedBox(width: 12),
                ],

                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                buildActions(context),
              ],
            ),

            if (showStatus || subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: EdgeInsets.only(left: showBackButton ? 52 : 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showStatus) HomeStatusIndicator(isOnline: isOnline),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget buildActions(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showNotifications) const _NotificationButton(),
        const SizedBox(width: 8),
        if (showSettings) const _SettingsButton(),
      ],
    );
  }
}

// --- Widgets Privados (Mantidos conforme original para performance) ---
class _SettingsButton extends StatelessWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context) {
    return GlassButton(
      icon: Icons.settings_outlined,
      tooltip: 'Definições',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  const _NotificationButton();

  Stream<QuerySnapshot> _unreadStream() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return const Stream.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(email)
        .collection('notifications')
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _unreadStream(),
      builder: (context, snapshot) {
        final hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topRight,
          children: [
            GlassButton(
              icon: Icons.notifications_outlined,
              tooltip: 'Notificações',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
            ),
            if (hasUnread) const _UnreadBadge(),
          ],
        );
      },
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Colors.red,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
