import 'package:agromotion/components/glass_container.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';

<<<<<<< Updated upstream
class AgroAppBar extends StatelessWidget {
  final String title;

  final dynamic isOnline;

  const AgroAppBar({super.key, required this.title, this.isOnline = true});

  @override
=======
class AgroAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AgroAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 20);

  @override
>>>>>>> Stashed changes
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      toolbarHeight: kToolbarHeight + 20,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNotificationButton(context, colorScheme),
              const SizedBox(width: 8),
              _buildGlassIconButton(
                context: context,
                icon: Icons.settings_outlined,
                tooltip: 'Definições',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                ),
                colorScheme: colorScheme,
                isSmall: context.isSmall,
              ),
            ],
          ),
        ),
        SizedBox(width: context.horizontalPadding),
      ],
    );
  }

  static Widget _buildNotificationButton(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    final email = FirebaseAuth.instance.currentUser?.email;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUnread = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            _buildGlassIconButton(
              context: context,
              icon: Icons.notifications_outlined,
              tooltip: 'Notificações',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              ),
              colorScheme: colorScheme,
              isSmall: context.isSmall,
            ),
            if (hasUnread)
              Positioned(
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
              ),
          ],
        );
      },
    );
  }

  // Static version for use in non-sliver contexts (HomeScreen)
  static Widget buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNotificationButton(context, colorScheme),
        const SizedBox(width: 8),
        _buildGlassIconButton(
          context: context,
          icon: Icons.settings_outlined,
          tooltip: 'Definições',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsScreen()),
          ),
          colorScheme: colorScheme,
          isSmall: context.isSmall,
        ),
      ],
    );
  }

  static Widget _buildGlassIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isSmall,
  }) {
    final iconSize = isSmall ? 20.0 : 24.0;
    final containerSize = isSmall ? 38.0 : 42.0;

    return Tooltip(
      message: tooltip,
      child: GlassContainer(
        borderRadius: 32,
        child: SizedBox(
          width: containerSize,
          height: containerSize,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(32),
              child: Icon(icon, size: iconSize, color: colorScheme.onSurface),
            ),
          ),
        ),
      ),
    );
  }
}
