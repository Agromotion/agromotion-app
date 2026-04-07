import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/models/metric_data.dart';

/// A horizontal scrollable strip of summary tiles.
class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.tiles});

  final List<SummaryTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tiles
            .map(
              (t) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: _SummaryTile(data: t),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.data});
  final SummaryTileData data;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: data.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(data.icon, size: 14, color: data.color),
              ),
              const SizedBox(width: 8),
              Text(
                data.label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: cs.onSurface.withAlpha(100),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data.value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
