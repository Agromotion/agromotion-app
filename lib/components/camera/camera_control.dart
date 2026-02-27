import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class CameraControl extends StatelessWidget {
  final VoidCallback? onCapturePressed;
<<<<<<< Updated upstream
  final VoidCallback? onRecordPressed;
  final VoidCallback? onRetryPressed;
  final VoidCallback? onToggleDebug;
=======
  final VoidCallback? onToggleDebug;
  final VoidCallback? onToggleFullScreen;
  final VoidCallback? onMapPressed;
>>>>>>> Stashed changes
  final bool isDebugVisible;
  final bool isRecording;
  final String currentQuality;
  final Function(String) onQualityChanged;

  const CameraControl({
    super.key,
    this.onCapturePressed,
<<<<<<< Updated upstream
    this.onRecordPressed,
    this.onRetryPressed,
    this.onToggleDebug,
=======
    this.onToggleDebug,
    this.onToggleFullScreen,
    this.onMapPressed,
>>>>>>> Stashed changes
    required this.isDebugVisible,
    required this.isRecording,
    required this.currentQuality,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      borderRadius: 32,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Info/Debug
          _buildIconButton(
<<<<<<< Updated upstream
            icon: isDebugVisible ? Icons.info : Icons.info_outline,
=======
            icon: isDebugVisible ? Icons.info_rounded : Icons.info_outlined,
>>>>>>> Stashed changes
            onTap: onToggleDebug,
            color: isDebugVisible ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Debug Info",
          ),
<<<<<<< Updated upstream

          const VerticalDivider(
=======
          const SizedBox(width: 8),
          _buildQualityDropdown(),
          VerticalDivider(
>>>>>>> Stashed changes
            width: 20,
            indent: 10,
            endIndent: 10,
            color: colorScheme.onSurface.withOpacity(0.2),
          ),

          // Botão Mapa
          _buildIconButton(
            icon: Icons.map_rounded,
            onTap: onMapPressed,
            color: colorScheme.onSurface,
            tooltip: "Mapa",
          ),

          // Seletor de Qualidade Integrado
          _buildQualityDropdown(theme),

          const SizedBox(width: 12),

          // Botão Captura Foto
          _buildIconButton(
            icon: Icons.camera_alt_rounded,
            onTap: onCapturePressed,
            color: colorScheme.onSurface,
            tooltip: "Screenshot",
          ),

<<<<<<< Updated upstream
          const SizedBox(width: 8),

          // Botão Central de Gravação (Destaque)
          GestureDetector(
            onTap: onRecordPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isRecording ? Colors.red : Colors.white24,
                  width: 2,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRecording ? Colors.red : Colors.white10,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRecording ? Icons.stop_rounded : Icons.fiber_manual_record,
                  color: isRecording ? Colors.white : Colors.red,
                  size: 24,
                ),
              ),
            ),
=======
          // Botão Fullscreen (Toggle Imersivo)
          _buildIconButton(
            icon: isFullScreen
                ? Icons.fullscreen_exit_rounded
                : Icons.fullscreen_rounded,
            onTap: onToggleFullScreen,
            color: isFullScreen ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Fullscreen",
>>>>>>> Stashed changes
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

<<<<<<< Updated upstream
  Widget _buildQualityDropdown(ThemeData theme) {
    return DropdownButton<String>(
      value: currentQuality,
      underline: const SizedBox(),
      icon: const Icon(
        Icons.arrow_drop_up_rounded,
        size: 18,
      ), // Seta para cima (estilo player)
      style: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      items: const [
        DropdownMenuItem(value: 'auto', child: Text('AUTO')),
        DropdownMenuItem(value: '720', child: Text('ORIGINAL')),
        DropdownMenuItem(value: '480', child: Text('480P')),
      ],
      onChanged: (val) => onQualityChanged(val!),
=======
  Widget _buildQualityDropdown() {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        return GlassContainer(
          padding: const EdgeInsets.only(left: 16, right: 8),
          borderRadius: 50,
          child: DropdownButton<String>(
            value: currentQuality,
            underline: const SizedBox.shrink(),
            dropdownColor: colorScheme.surface.withOpacity(0.95),
            icon: Icon(
              Icons.arrow_drop_down_rounded,
              color: colorScheme.onSurface,
            ),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            items: const [
              DropdownMenuItem(value: 'auto', child: Text('AUTO')),
              DropdownMenuItem(value: '720', child: Text('720p')),
              DropdownMenuItem(value: '480', child: Text('480p')),
            ],
            onChanged: (val) => onQualityChanged(val!),
          ),
        );
      },
>>>>>>> Stashed changes
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    String? tooltip,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 22),
      onPressed: onTap,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}
