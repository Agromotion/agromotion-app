import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:agromotion/models/metric_data.dart';

class ChartPopup extends StatefulWidget {
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
  State<ChartPopup> createState() => _ChartPopupState();
}

class _ChartPopupState extends State<ChartPopup> {
  late double _minX;
  late double _maxX;

  @override
  void initState() {
    super.initState();
    if (widget.metric.history.isNotEmpty) {
      _minX = widget.metric.history
          .map((e) => e.x)
          .reduce((a, b) => a < b ? a : b);
      _maxX = widget.metric.history
          .map((e) => e.x)
          .reduce((a, b) => a > b ? a : b);
      if (_maxX <= _minX) _maxX = _minX + 0.1;
    } else {
      _minX = 0;
      _maxX = 1;
    }
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
                  color: widget.metric.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.metric.icon,
                  color: widget.metric.color,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.metric.title,
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
                widget.metric.value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: widget.metric.color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Chart
          SizedBox(
            height: 260,
            child: widget.metric.history.isEmpty
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
                : LineChart(_lineData(cs)),
          ),

          // Hint zoom/pan
          if (widget.metric.history.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pinch_rounded,
                    size: 12,
                    color: cs.onSurface.withAlpha(50),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Pinch para zoom · Arrasta para navegar',
                    style: TextStyle(
                      fontSize: 10,
                      color: cs.onSurface.withAlpha(50),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 20),

          // Stats row (min / avg / max)
          if (widget.metric.history.isNotEmpty) _buildStatsRow(cs),

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

  Widget _buildStatsRow(ColorScheme cs) {
    final values = widget.metric.history.map((s) => s.y).toList();
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;

    String fmt(double v) => '${v.toStringAsFixed(1)} ${widget.metric.unit}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _MiniStat(label: 'MÍN', value: fmt(min), color: Colors.blue.shade300),
        _Divider(),
        _MiniStat(label: 'MÉDIA', value: fmt(avg), color: cs.onSurface),
        _Divider(),
        _MiniStat(label: 'MÁX', value: fmt(max), color: widget.metric.color),
      ],
    );
  }

  LineChartData _lineData(ColorScheme cs) {
    return LineChartData(
      minX: _minX,
      maxX: _maxX,
      clipData: const FlClipData.all(),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (spot) => cs.surfaceContainerHigh,
          getTooltipItems: (spots) => spots.map((s) {
            return LineTooltipItem(
              '${s.y.toStringAsFixed(1)} ${widget.metric.unit}',
              TextStyle(
                color: widget.metric.color,
                fontWeight: FontWeight.bold,
              ),
            );
          }).toList(),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 20,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: cs.onSurface.withAlpha(12), strokeWidth: 1),
        getDrawingVerticalLine: (_) =>
            FlLine(color: cs.onSurface.withAlpha(12), strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(),
        rightTitles: const AxisTitles(),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (val, _) => Text(
              val.toStringAsFixed(0),
              style: TextStyle(fontSize: 9, color: cs.onSurface.withAlpha(80)),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: (_maxX - _minX) / 4 > 0 ? (_maxX - _minX) / 4 : 1,
            getTitlesWidget: (value, _) {
              final d = widget.startTime.add(
                Duration(milliseconds: (value * 3600000).toInt()),
              );
              return Padding(
                padding: const EdgeInsets.only(top: 8),
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
          spots: widget.metric.history,
          isCurved: true,
          curveSmoothness: 0.35,
          color: widget.metric.color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                widget.metric.color.withAlpha(80),
                widget.metric.color.withAlpha(0),
              ],
            ),
          ),
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
