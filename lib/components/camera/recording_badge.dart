import 'package:flutter/material.dart';

class RecordingBadge extends StatelessWidget {
  final int duration;

  const RecordingBadge({super.key, required this.duration});

  String _formatDuration(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(180),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withAlpha(100), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.fiber_manual_record,
            color: duration % 2 == 0 ? Colors.red : Colors.red.withAlpha(100),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
