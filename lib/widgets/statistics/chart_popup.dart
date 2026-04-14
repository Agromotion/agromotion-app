import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agromotion/models/metric_data.dart';

/// Full-screen bottom sheet that shows a large chart for [metric].
class ChartPopup extends StatelessWidget {
  const ChartPopup({super.key, required this.metric, required this.startTime});

  final MetricData metric;
  final DateTime startTime;

  static void show(
    BuildContext context, {
    required MetricData metric,
    required DateTime startTime,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChartPopup(metric: metric, startTime: startTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 28,
      color: isDark ? const Color(0xFF1C2B24) : null,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: cs.onSurface.withAlpha(40),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: metric.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(metric.icon, color: metric.color, size: 18),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    metric.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  Text(
                    'Histórico',
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurface.withAlpha(100),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: metric.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Chart
          SizedBox(
            height: 260,
            child: metric.history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 40,
                          color: cs.onSurface.withAlpha(40),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sem dados para o período',
                          style: TextStyle(
                            color: cs.onSurface.withAlpha(80),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildChart(cs),
          ),

          const SizedBox(height: 24),

          // Stats row (min / avg / max)
          if (metric.history.isNotEmpty) _buildStatsRow(cs),

          const SizedBox(height: 20),

          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              height: 48,
              width: double.infinity,
              decoration: BoxDecoration(
                color: cs.onSurface.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cs.outline),
              ),
              child: Center(
                child: Text(
                  'Fechar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withAlpha(180),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(ColorScheme cs) {
    switch (metric.chartType) {
      case ChartType.bar:
        return BarChart(_barData(cs));
      case ChartType.pie:
        return PieChart(_pieData(cs));
      case ChartType.line:
        return LineChart(_lineData(cs));
    }
  }

  Widget _buildStatsRow(ColorScheme cs) {
    final values = metric.history.map((s) => s.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    String fmt(double v) => '${v.toStringAsFixed(1)} ${metric.unit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MiniStat(label: 'MÍN', value: fmt(min), color: Colors.blue.shade300),
        _Divider(),
        _MiniStat(label: 'MÉDIA', value: fmt(avg), color: cs.onSurface),
        _Divider(),
        _MiniStat(label: 'MÁX', value: fmt(max), color: metric.color),
      ],
    );
  }

  LineChartData _lineData(ColorScheme cs) {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: cs.onSurface.withAlpha(12), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(0),
              style: TextStyle(fontSize: 9, color: cs.onSurface.withAlpha(80)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, _) {
              final d = startTime.add(Duration(minutes: (value * 60).toInt()));
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('HH:mm').format(d),
                  style: TextStyle(
                    fontSize: 9,
                    color: cs.onSurface.withAlpha(80),
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
          barWidth: 3,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [metric.color.withAlpha(60), metric.color.withAlpha(0)],
            ),
          ),
        ),
      ],
    );
  }

  BarChartData _barData(ColorScheme cs) {
    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: metric.history
          .map(
            (s) => BarChartGroupData(
              x: s.x.toInt(),
              barRods: [
                BarChartRodData(
                  toY: s.y,
                  color: metric.color,
                  width: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          )
          .toList(),
    );
  }

  PieChartData _pieData(ColorScheme cs) {
    final val = metric.history.isNotEmpty ? metric.history.last.y : 0.0;
    return PieChartData(
      sectionsSpace: 2,
      centerSpaceRadius: 50,
      sections: [
        PieChartSectionData(
          value: val,
          color: metric.color,
          radius: 40,
          title: '${val.toInt()}%',
          titleStyle: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: cs.onSurface,
          ),
        ),
        PieChartSectionData(
          value: (100 - val).clamp(0, 100).toDouble(),
          color: cs.onSurface.withAlpha(18),
          radius: 40,
          title: '',
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: cs.onSurface.withAlpha(90),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      color: Theme.of(context).colorScheme.onSurface.withAlpha(20),
    );
  }
}
