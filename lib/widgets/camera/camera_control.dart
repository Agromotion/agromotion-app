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
  final String currentQuality;
  final Function(String) onQualityChanged;

  const CameraControl({
    super.key,
    this.onCapturePressed,
    this.onRetryPressed,
    this.onToggleDebug,
    this.onToggleFullScreen,
    this.onMapPressed,
    required this.isDebugVisible,
    this.isFullScreen = false,
    required this.currentQuality,
    required this.onQualityChanged,
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
          // 1. Botão Info/Debug
          _buildIconButton(
            icon: isDebugVisible
                ? Icons.info_rounded
                : Icons.info_outline_rounded,
            onTap: onToggleDebug,
            color: isDebugVisible ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Debug Info",
          ),

          const SizedBox(width: 4),

          // 2. Seletor de Qualidade
          _buildQualityDropdown(theme),

          VerticalDivider(
            width: 20,
            indent: 10,
            endIndent: 10,
            color: colorScheme.onSurface.withAlpha(20),
          ),

          // 3. Botão Mapa
          _buildIconButton(
            icon: Icons.map_rounded,
            onTap: onMapPressed,
            color: colorScheme.onSurface,
            tooltip: "Ver Mapa",
          ),

          // 4. Botão Fullscreen
          _buildIconButton(
            icon: isFullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            onTap: onToggleFullScreen,
            color: isFullScreen ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Ecrã Inteiro",
          ),

          const SizedBox(width: 8),

          // 5. Botão Captura Foto (Destaque)
          Container(
            decoration: BoxDecoration(
              color: colorScheme.primary.withAlpha(10),
              shape: BoxShape.circle,
            ),
            child: _buildIconButton(
              icon: Icons.camera_alt_rounded,
              onTap: onCapturePressed,
              color: colorScheme.primary,
              tooltip: "Tirar Foto",
            ),
          ),

          const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildQualityDropdown(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButton<String>(
        value: currentQuality,
        underline: const SizedBox(),
        alignment: Alignment.center,
        icon: const Icon(Icons.arrow_drop_up_rounded, size: 18),
        dropdownColor: theme.colorScheme.surface.withAlpha(95),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          DropdownMenuItem(value: 'auto', child: Text('auto')),
          DropdownMenuItem(value: '720', child: Text('720p')),
          DropdownMenuItem(value: '480', child: Text('480p')),
        ],
        onChanged: (val) {
          if (val != null) onQualityChanged(val);
        },
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
