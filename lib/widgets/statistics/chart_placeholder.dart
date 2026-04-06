import 'package:flutter/material.dart';
import '../glass_container.dart';

class ChartPlaceholder extends StatelessWidget {
  final String label;
  final IconData icon;

  const ChartPlaceholder({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        height: 160,
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colorScheme.primary.withAlpha(40), size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withAlpha(60),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              "(Integração fl_chart pendente)",
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
