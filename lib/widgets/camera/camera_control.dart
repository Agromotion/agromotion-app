import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';

class CameraControl extends StatelessWidget {
  final VoidCallback? onCapturePressed;
  final VoidCallback? onRetryPressed;
  final VoidCallback? onToggleDebug;
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onMapPressed;

  final bool isDebugVisible;
  final bool isFullScreen;

  const CameraControl({
    super.key,
    this.onCapturePressed,
    this.onRetryPressed,
    this.onToggleDebug,
    this.onToggleFullScreen,
    this.onMapPressed,
    required this.isDebugVisible,
    this.isFullScreen = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      borderRadius: 40,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Info/Debug
          _buildIconButton(
            icon: isDebugVisible
                ? Icons.info_rounded
                : Icons.info_outline_rounded,
            onTap: onToggleDebug,
            color: isDebugVisible ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Debug Info",
          ),

          // Botão Mapa
          _buildIconButton(
            icon: Icons.map_rounded,
            onTap: onMapPressed,
            color: colorScheme.onSurface,
            tooltip: "Ver Mapa",
          ),

          // Botão Fullscreen
          _buildIconButton(
            icon: isFullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            onTap: onToggleFullScreen,
            color: isFullScreen ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Ecrã Inteiro",
          ),

          // Botão Captura Foto (Destaque)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: _buildIconButton(
              icon: Icons.camera_alt_rounded,
              onTap: onCapturePressed,
              color: colorScheme.primary,
              tooltip: "Tirar Screenshot",
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 24),
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 20,
    );
  }
}
