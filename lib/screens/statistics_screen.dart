import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/widgets/glass_container.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/agro_appbar.dart';
import '../widgets/statistics/date_filter_widget.dart';

enum ChartType { line, bar, pie }

class MetricData {
  final String id;
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final List<FlSpot> history;
  final ChartType chartType;
  final String unit;

  MetricData({
    required this.id,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.history,
    required this.chartType,
    this.unit = '',
  });
}

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final DateTime _startDate = DateTime.now().subtract(const Duration(days: 1));
  final DateTime _endDate = DateTime.now();
  int _selectedFilter = 0;

  // Mapas para armazenar o histórico de cada KPI
  Map<String, List<FlSpot>> _historyMap = {};
  Map<String, String> _currentValues = {};

  @override
  void initState() {
    super.initState();
    _fetchHistoryData();
  }

  Future<void> _fetchHistoryData() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('robots')
          .doc(AppConfig.robotId)
          .collection('telemetry_history')
          .where('timestamp', isGreaterThanOrEqualTo: _startDate)
          .where('timestamp', isLessThanOrEqualTo: _endDate)
          .orderBy('timestamp', descending: false)
          .get();

      // Inicializar listas limpas
      Map<String, List<FlSpot>> newHistory = {
        'bat': [],
        'cpu': [],
        'tmp': [],
        'rssi': [],
        'mem': [],
        'lat': [],
        'load': [],
      };

      for (var doc in query.docs) {
        final data = doc.data();
        final ts = (data['timestamp'] as Timestamp).toDate();
        double x = ts.difference(_startDate).inMinutes / 60.0;

        newHistory['bat']!.add(
          FlSpot(x, (data['battery_percentage'] ?? 0).toDouble()),
        );
        newHistory['cpu']!.add(FlSpot(x, (data['system_cpu'] ?? 0).toDouble()));
        newHistory['tmp']!.add(
          FlSpot(x, (data['system_temperature'] ?? 0).toDouble()),
        );
        newHistory['rssi']!.add(
          FlSpot(x, (data['rssi'] ?? -70).toDouble().abs()),
        ); // Abs para gráfico melhor
        newHistory['mem']!.add(FlSpot(x, (data['ram_usage'] ?? 0).toDouble()));
        newHistory['lat']!.add(FlSpot(x, (data['latency'] ?? 0).toDouble()));
        newHistory['load']!.add(
          FlSpot(x, (data['motor_load'] ?? 0).toDouble()),
        );
      }

      setState(() {
        _historyMap = newHistory;
        if (query.docs.isNotEmpty) {
          final last = query.docs.last.data();
          _currentValues = {
            'bat': "${last['battery_percentage'] ?? 0}%",
            'cpu': "${last['system_cpu'] ?? 0}%",
            'tmp': "${last['system_temperature'] ?? 0}°C",
            'rssi': "${last['rssi'] ?? 0} dBm",
            'mem': "${last['ram_usage'] ?? 0}MB",
            'lat': "${last['latency'] ?? 0}ms",
            'load': "${last['motor_load'] ?? 0}%",
          };
        }
      });
    } catch (e) {}
  }

  List<MetricData> get _allMetrics => [
    MetricData(
      id: 'bat',
      title: 'Bateria',
      value: _currentValues['bat'] ?? '0%',
      icon: Icons.battery_charging_full,
      color: Colors.greenAccent,
      history: _historyMap['bat'] ?? [],
      chartType: ChartType.pie,
      unit: '%',
    ),
    MetricData(
      id: 'cpu',
      title: 'Uso CPU',
      value: _currentValues['cpu'] ?? '0%',
      icon: Icons.memory,
      color: Colors.blueAccent,
      history: _historyMap['cpu'] ?? [],
      chartType: ChartType.line,
      unit: '%',
    ),
    MetricData(
      id: 'tmp',
      title: 'Temperatura',
      value: _currentValues['tmp'] ?? '0°C',
      icon: Icons.thermostat,
      color: Colors.orangeAccent,
      history: _historyMap['tmp'] ?? [],
      chartType: ChartType.line,
      unit: '°C',
    ),
    MetricData(
      id: 'mem',
      title: 'Memória RAM',
      value: _currentValues['mem'] ?? '0MB',
      icon: Icons.storage,
      color: Colors.purpleAccent,
      history: _historyMap['mem'] ?? [],
      chartType: ChartType.bar,
      unit: 'MB',
    ),
    MetricData(
      id: 'rssi',
      title: 'Sinal Wi-Fi',
      value: _currentValues['rssi'] ?? '0 dBm',
      icon: Icons.wifi,
      color: Colors.cyanAccent,
      history: _historyMap['rssi'] ?? [],
      chartType: ChartType.line,
      unit: 'dBm',
    ),
    MetricData(
      id: 'lat',
      title: 'Latência',
      value: _currentValues['lat'] ?? '0ms',
      icon: Icons.speed,
      color: Colors.redAccent,
      history: _historyMap['lat'] ?? [],
      chartType: ChartType.bar,
      unit: 'ms',
    ),
    MetricData(
      id: 'load',
      title: 'Carga Motor',
      value: _currentValues['load'] ?? '0%',
      icon: Icons.settings_input_component,
      color: Colors.yellowAccent,
      history: _historyMap['load'] ?? [],
      chartType: ChartType.line,
      unit: '%',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final customColors = Theme.of(context).extension<AppColorsExtension>()!;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              const AgroAppBar(),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    DateFilterWidget(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: (f) {
                        setState(() => _selectedFilter = f);
                        _fetchHistoryData();
                      },
                      onCustomDatePressed: () {},
                    ),
                    const SizedBox(height: 25),
                    _buildSectionLabel("Painel de Telemetria"),
                    const SizedBox(height: 15),
                    _buildMetricsGrid(),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.white54,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allMetrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final m = _allMetrics[index];
        return GestureDetector(
          onTap: () => _showMetricPopup(m),
          child: GlassContainer(
            borderRadius: 15,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(m.icon, color: m.color, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        m.title,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                        ),
                      ),
                      Text(
                        m.value,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showMetricPopup(MetricData metric) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _MetricPopup(metric: metric),
    );
  }
}

class _MetricPopup extends StatelessWidget {
  final MetricData metric;
  const _MetricPopup({required this.metric});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 25,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(metric.icon, color: metric.color),
                  const SizedBox(width: 12),
                  Text(
                    metric.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                metric.value,
                style: TextStyle(
                  fontSize: 18,
                  color: metric.color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(height: 220, child: _buildChart()),
          const SizedBox(height: 30),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.white10,
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    if (metric.history.isEmpty) {
      return const Center(child: Text("Sem dados no período"));
    }

    switch (metric.chartType) {
      case ChartType.line:
        return LineChart(_lineData());
      case ChartType.bar:
        return BarChart(_barData());
      case ChartType.pie:
        return PieChart(_pieData());
    }
  }

  LineChartData _lineData() {
    return LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: metric.history,
          isCurved: true,
          color: metric.color,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: metric.color.withAlpha(20),
          ),
        ),
      ],
    );
  }

  BarChartData _barData() {
    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: const FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      barGroups: metric.history
          .take(10)
          .map(
            (s) => BarChartGroupData(
              x: s.x.toInt(),
              barRods: [
                BarChartRodData(toY: s.y, color: metric.color, width: 15),
              ],
            ),
          )
          .toList(),
    );
  }

  PieChartData _pieData() {
    final val = metric.history.last.y;
    return PieChartData(
      sections: [
        PieChartSectionData(
          value: val,
          color: metric.color,
          radius: 50,
          title: '${val.toInt()}%',
          titleStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
        PieChartSectionData(
          value: 100 - val,
          color: Colors.white10,
          radius: 50,
          title: '',
        ),
      ],
      centerSpaceRadius: 40,
    );
  }
}
