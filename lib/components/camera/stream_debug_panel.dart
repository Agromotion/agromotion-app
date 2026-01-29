import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class StreamDebugPanel extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StreamDebugPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.terminal_rounded,
                color: colorScheme.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "DIAGNÓSTICO TÉCNICO",
                style: TextStyle(
                  color: colorScheme.primary.withAlpha(80),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          Divider(color: colorScheme.onSurface.withAlpha(10), height: 20),
          _debugLine(context, "RESOLUÇÃO", stats['res'] ?? "---"),
          _debugLine(
            context,
            "FRAME RATE",
            "${stats['fps']?.toInt() ?? 0} FPS",
          ),
          _debugLine(context, "LATÊNCIA", "${stats['latency'] ?? '---'} ms"),
          _debugLine(
            context,
            "PERDA PAC.",
            "${stats['loss']?.toStringAsFixed(2) ?? '0.00'}%",
          ),
          const SizedBox(height: 8),
          _debugLine(context, "CPU ROBÔ", stats['cpu'] ?? "---"),
          _debugLine(context, "TEMP. PI", stats['temp'] ?? "---"),
        ],
      ),
    );
  }

  Widget _debugLine(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colorScheme.onSurface.withAlpha(60),
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 20),
          Text(
            value,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
