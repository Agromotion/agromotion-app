import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class CameraControl extends StatelessWidget {
  final VoidCallback? onCapturePressed;
  final VoidCallback? onRecordPressed;
  final VoidCallback? onRetryPressed;
  final VoidCallback? onToggleDebug;
  final bool isDebugVisible;
  final bool isRecording;
  final String currentQuality;
  final Function(String) onQualityChanged;

  const CameraControl({
    super.key,
    this.onCapturePressed,
    this.onRecordPressed,
    this.onRetryPressed,
    this.onToggleDebug,
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
            icon: isDebugVisible ? Icons.info : Icons.info_outline,
            onTap: onToggleDebug,
            color: isDebugVisible ? colorScheme.primary : colorScheme.onSurface,
            tooltip: "Debug Info",
          ),

          const VerticalDivider(
            width: 20,
            indent: 10,
            endIndent: 10,
            color: Colors.white24,
          ),

          // Seletor de Qualidade Integrado
          _buildQualityDropdown(theme),

          const SizedBox(width: 12),

          // Botão Captura Foto
          _buildIconButton(
            icon: Icons.camera_alt_rounded,
            onTap: onCapturePressed,
            color: colorScheme.onSurface,
          ),

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
          ),

          const SizedBox(width: 8),

          // Botão Reconnect
          _buildIconButton(
            icon: Icons.refresh_rounded,
            onTap: onRetryPressed,
            color: colorScheme.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _buildQualityDropdown(ThemeData theme) {
    return DropdownButton<String>(
      value: currentQuality,
      underline: const SizedBox(),
      dropdownColor: theme.colorScheme.surface.withOpacity(0.9),
      borderRadius: BorderRadius.circular(16),
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
        DropdownMenuItem(value: 'original', child: Text('1080P')),
        DropdownMenuItem(value: '720', child: Text('720P')),
        DropdownMenuItem(value: '480', child: Text('480P')),
      ],
      onChanged: (val) => onQualityChanged(val!),
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
