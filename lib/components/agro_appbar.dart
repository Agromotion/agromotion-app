import 'dart:ui';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/notifications_screen.dart';
import '../screens/settings_screen.dart';

class AgroAppBar extends StatelessWidget {
  final String title;

  final dynamic isOnline;

  const AgroAppBar({super.key, required this.title, this.isOnline = true});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;

    return SliverLayoutBuilder(
      builder: (context, constraints) {
        return SliverAppBar(
          expandedHeight: 110,
          pinned: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  gradient: customColors.glassGradient,
                  border: Border(
                    bottom: BorderSide(color: colorScheme.outline, width: 1),
                  ),
                ),
                child: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(
                    left: context.horizontalPadding,
                    bottom: 16,
                    right: context.horizontalPadding - 8,
                  ),
                  centerTitle: false,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Lado Esquerdo: Título e Status
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.appBarTheme.titleTextStyle?.copyWith(
                              fontSize: context.isSmall ? 18 : 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _buildStatusBadge(colorScheme, context.isSmall),
                        ],
                      ),

                      // Lado Direito: Ações com feedback visual nativo
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildNativeIconButton(
                            context: context,
                            icon: Icons.notifications_outlined,
                            tooltip: 'Notificações',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const NotificationsScreen(),
                                ),
                              );
                            },
                            colorScheme: colorScheme,
                            isSmall: context.isSmall,
                          ),
                          _buildNativeIconButton(
                            context: context,
                            icon: Icons.settings_outlined,
                            tooltip: 'Definições',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            colorScheme: colorScheme,
                            isSmall: context.isSmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNativeIconButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required bool isSmall,
  }) {
    // Usar IconButton para feedback de toque nativo (ripple circular)
    return Material(
      type: MaterialType.transparency,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        tooltip: tooltip,
        iconSize: isSmall ? 18 : 22,
        color: colorScheme.onSurface,
        // Define o raio do splash para ser proporcional ao ícone
        splashRadius: isSmall ? 20 : 24,
        padding: const EdgeInsets.all(8),
        constraints:
            const BoxConstraints(), // Remove as restrições de tamanho mínimo do Material
      ),
    );
  }

  Widget _buildStatusBadge(ColorScheme colorScheme, bool isSmall) {
    final color = isOnline ? colorScheme.primary : colorScheme.error;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(50),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          isOnline ? 'ONLINE' : 'OFFLINE',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.bold,
            color: color.withAlpha(90),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
