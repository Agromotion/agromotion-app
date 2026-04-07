import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/statistics/chart_popup.dart';
import 'package:flutter/material.dart';
import 'package:agromotion/models/metric_data.dart';

/// A 2-column grid of tappable metric tiles, each with an inline sparkline.
class MetricsGrid extends StatelessWidget {
  const MetricsGrid({
    super.key,
    required this.metrics,
    required this.startTime,
  });

  final List<MetricData> metrics;
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, i) =>
          _MetricTile(metric: metrics[i], startTime: startTime),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.metric, required this.startTime});

  final MetricData metric;
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () =>
          ChartPopup.show(context, metric: metric, startTime: startTime),
      child: GlassContainer(
        borderRadius: 16,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon + title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: metric.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(metric.icon, size: 13, color: metric.color),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    metric.title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: cs.onSurface.withAlpha(120),
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 14,
                  color: cs.onSurface.withAlpha(60),
                ),
              ],
            ),

            const Spacer(),

            // Value
            Text(
              metric.value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1,
              ),
            ),

            // Trend indicator
            if (metric.history.length >= 2) ...[
              const SizedBox(height: 4),
              _TrendIndicator(history: metric.history, color: metric.color),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shows whether the metric is trending up, down or flat compared to its
/// first value in the current window.
class _TrendIndicator extends StatelessWidget {
  const _TrendIndicator({required this.history, required this.color});

  final List history;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final first = (history.first.y as double);
    final last = (history.last.y as double);
    final delta = last - first;
    final pct = first == 0 ? 0.0 : delta / first * 100;

    final isUp = delta > 0;
    final isFlat = delta.abs() < 0.5;

    final trendColor = isFlat
        ? cs.onSurface.withAlpha(80)
        : isUp
        ? const Color(0xFFFFA726)
        : const Color(0xFF66BB6A);

    final icon = isFlat
        ? Icons.remove_rounded
        : isUp
        ? Icons.trending_up_rounded
        : Icons.trending_down_rounded;

    return Row(
      children: [
        Icon(icon, size: 12, color: trendColor),
        const SizedBox(width: 3),
        Text(
          isFlat ? 'Estável' : '${pct.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: trendColor,
          ),
        ),
      ],
    );
  }
}
