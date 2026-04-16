import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/models/metric_data.dart';

class SummaryRow extends StatelessWidget {
  const SummaryRow({super.key, required this.tiles});
  final List<SummaryTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Tablet/desktop: 4 colunas numa única linha.
        // Telemóvel: 2 colunas × 2 linhas.
        final isWide = constraints.maxWidth >= 600;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final itemWidth = isWide
                ? (constraints.maxWidth - 30) /
                      4 // 4 colunas
                : (constraints.maxWidth - 10) / 2; // 2 colunas

            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: tiles
                  .map(
                    (tile) => SizedBox(
                      width: itemWidth,
                      child: AspectRatio(
                        aspectRatio: isWide ? 2.5 : 1.8,
                        child: _SummaryTile(data: tile),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );
      },
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Label com ícone ──────────────────────────────────────────────
          Row(
            children: [
              Icon(
                data.icon,
                size: 13,
                color: data.color.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Valor — escala para não transbordar ──────────────────────────
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
