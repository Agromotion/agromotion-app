import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../glass_container.dart';

class DistanceChart extends StatelessWidget {
  final List<FlSpot> data;

  const DistanceChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: 5,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: colorScheme.outline.withAlpha(10),
                  strokeWidth: 1,
                );
              },
            ),
            titlesData: FlTitlesData(
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()}h',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(50),
                        fontSize: 10,
                      ),
                    );
                  },
                  interval: 2,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      '${value.toInt()} km',
                      style: TextStyle(
                        color: colorScheme.onSurface.withAlpha(50),
                        fontSize: 9,
                      ),
                    );
                  },
                  interval: 5,
                  reservedSize: 40,
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withAlpha(80),
                    Colors.cyan.withAlpha(60),
                  ],
                ),
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: Colors.white,
                      strokeColor: Colors.blue,
                      strokeWidth: 2,
                    );
                  },
                ),
              ),
            ],
            minY: 0,
            maxY: 20,
          ),
        ),
      ),
    );
  }
}
