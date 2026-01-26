import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class CameraControl extends StatelessWidget {
  final VoidCallback? onCapturePressed;
  final VoidCallback? onRecordPressed;
  final VoidCallback? onFlipPressed;

  const CameraControl({
    super.key,
    this.onCapturePressed,
    this.onRecordPressed,
    this.onFlipPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      // Padding reduzido para tornar a barra mais curta
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      borderRadius: 28,
      child: Row(
        mainAxisSize: MainAxisSize.min, // Ocupa apenas o espaço necessário
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionIcon(
            icon: Icons.camera_alt_outlined,
            onTap: onCapturePressed,
            colorScheme: colorScheme,
          ),
          const SizedBox(width: 20),

          // Botão de Gravar mais compacto
          GestureDetector(
            onTap: onRecordPressed,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red, width: 1.5),
              ),
              child: const Icon(
                Icons.fiber_manual_record,
                color: Colors.red,
                size: 28, // Reduzido de 32
              ),
            ),
          ),

          const SizedBox(width: 20),
          _buildActionIcon(
            icon: Icons.flip_camera_ios_outlined,
            onTap: onFlipPressed,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon({
    required IconData icon,
    required VoidCallback? onTap,
    required ColorScheme colorScheme,
  }) {
    return IconButton(
      icon: Icon(
        icon,
        color: colorScheme.onSurface,
        size: 24,
      ), // Reduzido de 28
      onPressed: onTap,
      visualDensity: VisualDensity.compact, // Remove espaços extras nativos
    );
  }
}
