import 'package:flutter/material.dart';

class CameraStatusView extends StatelessWidget {
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onRetry;

  const CameraStatusView({
    super.key,
    this.errorMessage,
    required this.isLoading,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (errorMessage != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_off_rounded,
            size: 64,
            color: colorScheme.error.withAlpha(150),
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage!,
            style: TextStyle(color: colorScheme.onSurface.withAlpha(200)),
          ),
          const SizedBox(height: 24),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Tentar novamente"),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 60,
          child: LinearProgressIndicator(
            backgroundColor: colorScheme.primary.withAlpha(20),
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "A ligar ao Robô...",
          style: TextStyle(color: colorScheme.onSurface.withAlpha(150)),
        ),
      ],
    );
  }
}
