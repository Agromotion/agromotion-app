import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../glass_container.dart';

class UptimeChart extends StatelessWidget {
  final List<BarChartGroupData> barGroups;

  const UptimeChart({super.key, required this.barGroups});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: 12,
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final days = [
                      'Seg',
                      'Ter',
                      'Qua',
                      'Qui',
                      'Sex',
                      'Sab',
                      'Dom',
                    ];
                    return Text(
                      days[value.toInt() % days.length],
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(70),
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                  interval: 1,
                  reservedSize: 30,
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}h',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(50),
                        fontSize: 9,
                      ),
                    );
                  },
                  interval: 3,
                  reservedSize: 40,
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 3,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.outline.withAlpha(10),
                  strokeWidth: 1,
                );
              },
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}
