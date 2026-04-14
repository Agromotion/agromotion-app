import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/statistics/chart_popup.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agromotion/models/metric_data.dart';

/// Threshold (dp) acima do qual os gráficos aparecem directamente no card.
const double _kLargeScreenBreakpoint = 600;

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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth >= _kLargeScreenBreakpoint;

    if (isLarge) {
      // Ecrã grande: dois cards por linha com gráfico inline
      return Column(
        children: [
          for (int i = 0; i < metrics.length; i += 2)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InlineMetricCard(
                      metric: metrics[i],
                      startTime: startTime,
                    ),
                  ),
                  if (i + 1 < metrics.length) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: _InlineMetricCard(
                        metric: metrics[i + 1],
                        startTime: startTime,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      );
    } else {
      // Ecrã pequeno: grid 2×N sem gráfico, abre popup ao tocar
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, i) =>
            _CompactMetricCard(metric: metrics[i], startTime: startTime),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card grande com gráfico inline (ecrãs ≥ 600 dp)
// ─────────────────────────────────────────────────────────────────────────────

class _InlineMetricCard extends StatelessWidget {
  const _InlineMetricCard({required this.metric, required this.startTime});

  final MetricData metric;
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: metric.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, size: 16, color: metric.color),
              ),
              const SizedBox(width: 10),
              Text(
                metric.title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: metric.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Gráfico inline
          SizedBox(
            height: 120,
            child: metric.history.isEmpty
                ? Center(
                    child: Text(
                      'Sem dados',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withAlpha(60),
                      ),
                    ),
                  )
                : _MiniLineChart(metric: metric, startTime: startTime, cs: cs),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card compacto sem gráfico (ecrãs < 600 dp) — abre popup ao tocar
// ─────────────────────────────────────────────────────────────────────────────

class _CompactMetricCard extends StatelessWidget {
  const _CompactMetricCard({required this.metric, required this.startTime});

  final MetricData metric;
  final DateTime startTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () =>
          ChartPopup.show(context, metric: metric, startTime: startTime),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: metric.color.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(metric.icon, size: 14, color: metric.color),
                ),
                const Spacer(),
                Icon(
                  Icons.open_in_full_rounded,
                  size: 13,
                  color: cs.onSurface.withAlpha(60),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: cs.onSurface.withAlpha(120),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: metric.color,
                    height: 1,
                  ),
                ),
              ],
            ),
            // Mini sparkline apenas para dar contexto visual
            if (metric.history.isNotEmpty)
              SizedBox(height: 28, child: _SparkLine(metric: metric)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gráfico de linha completo para cards inline
// ─────────────────────────────────────────────────────────────────────────────

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({
    required this.metric,
    required this.startTime,
    required this.cs,
  });

  final MetricData metric;
  final DateTime startTime;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: cs.onSurface.withAlpha(10), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (val, _) => Text(
                val.toStringAsFixed(0),
                style: TextStyle(
                  fontSize: 8,
                  color: cs.onSurface.withAlpha(70),
                ),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, _) {
                final d = startTime.add(
                  Duration(minutes: (value * 60).toInt()),
                );
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('HH:mm').format(d),
                    style: TextStyle(
                      fontSize: 8,
                      color: cs.onSurface.withAlpha(70),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: metric.history,
            isCurved: true,
            color: metric.color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [metric.color.withAlpha(50), metric.color.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sparkline minimalista para cards compactos
// ─────────────────────────────────────────────────────────────────────────────

class _SparkLine extends StatelessWidget {
  const _SparkLine({required this.metric});
  final MetricData metric;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: const FlTitlesData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        lineBarsData: [
          LineChartBarData(
            spots: metric.history,
            isCurved: true,
            color: metric.color.withAlpha(160),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [metric.color.withAlpha(40), metric.color.withAlpha(0)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
