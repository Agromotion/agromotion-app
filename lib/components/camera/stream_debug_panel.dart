import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class StreamDebugPanel extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StreamDebugPanel({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.terminal_rounded,
                color: Colors.greenAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                "DIAGNÓSTICO TÉCNICO",
                style: TextStyle(
                  color: Colors.greenAccent.withOpacity(0.8),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white10, height: 20),
          _debugLine("RESOLUÇÃO", stats['res'] ?? "---"),
          _debugLine("FRAME RATE", "${stats['fps']?.toInt() ?? 0} FPS"),
          _debugLine("LATÊNCIA", "${stats['latency'] ?? '---'} ms"),
          _debugLine("PERDA PAC.", "${stats['loss']?.toStringAsFixed(2)}%"),
          const SizedBox(height: 8),
          _debugLine("CPU ROBÔ", stats['cpu'] ?? "---"),
          _debugLine("TEMP. PI", stats['temp'] ?? "---"),
        ],
      ),
    );
  }

  Widget _debugLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 20),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
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
