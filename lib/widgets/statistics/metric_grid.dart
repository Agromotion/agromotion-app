import 'package:agromotion/widgets/glass_container.dart';
import 'package:agromotion/widgets/statistics/chart_popup.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agromotion/models/metric_data.dart';

/// Ecrãs com largura ≥ este valor mostram gráficos inline nos cards.
const double _kLargeBreakpoint = 600;

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLarge = constraints.maxWidth >= _kLargeBreakpoint;
        final spacing = 12.0;

        // Calculamos a largura de cada item (2 colunas) subtraindo o espaçamento central
        final itemWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: metrics.map((metric) {
            return SizedBox(
              width: itemWidth,
              child: isLarge
                  ? _InlineMetricCard(metric: metric, startTime: startTime)
                  : _CompactMetricCard(metric: metric, startTime: startTime),
            );
          }).toList(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card com gráfico inline — ecrãs largos
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
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ────────────────────────────────────────────────────────
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
              Expanded(
                child: Text(
                  metric.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
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
          // Substituído SizedBox por Padding no content
          Padding(
            padding: const EdgeInsets.only(top: 14),
            child: SizedBox(
              height: 110,
              child: metric.history.isEmpty
                  ? Center(
                      child: Text(
                        'Sem dados para o período',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withAlpha(60),
                        ),
                      ),
                    )
                  : _MiniLineChart(
                      metric: metric,
                      startTime: startTime,
                      cs: cs,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card compacto — telemóvel (toque abre popup)
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
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // ── Ícone + indicador de expansão ─────────────────────────────
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
                  size: 12,
                  color: cs.onSurface.withAlpha(50),
                ),
              ],
            ),

            // ── Label + valor ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: cs.onSurface.withAlpha(110),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      metric.value,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: metric.color,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Sparkline ─────────────────────────────────────────────────
            if (metric.history.isNotEmpty)
              SizedBox(height: 26, child: _SparkLine(metric: metric)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gráfico de linha completo (inline, ecrãs largos)
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
              reservedSize: 30,
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
              reservedSize: 20,
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
// Sparkline minimalista (cards compactos)
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
