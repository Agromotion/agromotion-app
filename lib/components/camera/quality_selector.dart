import 'package:agromotion/components/glass_container.dart';
import 'package:flutter/material.dart';

class QualitySelector extends StatelessWidget {
  final String currentQuality;
  final Function(String) onQualityChanged;

  const QualitySelector({
    super.key,
    required this.currentQuality,
    required this.onQualityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: DropdownButton<String>(
        value: currentQuality,
        icon: const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Icon(Icons.tune_rounded, size: 16),
        ),
        underline: const SizedBox(),
        dropdownColor: theme.colorScheme.surface.withAlpha(240),
        borderRadius: BorderRadius.circular(16),
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        items: const [
          DropdownMenuItem(value: 'auto', child: Text('AUTO')),
          DropdownMenuItem(value: 'original', child: Text('1080p')),
          DropdownMenuItem(value: '720', child: Text('720p')),
          DropdownMenuItem(value: '480', child: Text('480p')),
        ],
        onChanged: (val) => onQualityChanged(val!),
      ),
    );
  }
}
