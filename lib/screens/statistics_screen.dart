import 'package:agromotion/config/app_config.dart';
import 'package:agromotion/utils/responsive_layout.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../components/agro_appbar.dart';
import '../components/statistics/date_filter_widget.dart';
import '../components/statistics/kpi_card.dart';
import '../components/statistics/battery_chart.dart';
import '../components/statistics/distance_chart.dart';
import '../components/statistics/uptime_chart.dart';
import '../components/statistics/activity_report.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  // Filter State
  late DateTime _startDate;
  late DateTime _endDate;
  int _selectedFilter = 0;
  bool _isLoading = false;

  String get robotId => AppConfig.robotId;

  // Real Data State
  List<FlSpot> _batteryData = [];
  String _avgCpu = "0.0";
  String _maxTemp = "0.0";
  String _currentBattery = "---";
  int _dataPoints = 0;

  @override
  void initState() {
    super.initState();
    _setFilter(0); // Default to Last 24h
  }

  /// Logic to fetch real history from Firestore
  Future<void> _fetchHistoryData() async {
    setState(() => _isLoading = true);

    try {
      final query = await FirebaseFirestore.instance
          .collection('robots')
          .doc(robotId)
          .collection('telemetry_history')
          .where('timestamp', isGreaterThanOrEqualTo: _startDate)
          .where('timestamp', isLessThanOrEqualTo: _endDate)
          .orderBy('timestamp', descending: false)
          .get();

      List<FlSpot> batterySpots = [];
      double maxTemp = 0.0;
      double totalCpu = 0.0;
      String latestBattery = "---";

      for (var doc in query.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();

        // Calculate X axis: hours from the start of the period
        double xValue = timestamp.difference(_startDate).inMinutes / 60.0;

        // Battery
        double battery = (data['battery_percentage'] ?? 0.0).toDouble();
        batterySpots.add(FlSpot(xValue, battery));
        latestBattery = "${battery.toInt()}%";

        // Temperature
        double temp = (data['system_temperature'] ?? 0.0).toDouble();
        if (temp > maxTemp) maxTemp = temp;

        // CPU
        totalCpu += (data['system_cpu'] ?? 0.0).toDouble();
      }

      setState(() {
        _batteryData = batterySpots;
        _maxTemp = maxTemp.toStringAsFixed(1);
        _avgCpu = query.docs.isNotEmpty
            ? (totalCpu / query.docs.length).toStringAsFixed(1)
            : "0.0";
        _currentBattery = latestBattery;
        _dataPoints = query.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Firestore Statistics Error: $e");
      setState(() => _isLoading = false);
      // Note: If you see an error here about "The query requires an index",
      // click the link provided in the Flutter Console to auto-create it.
    }
  }

  void _setFilter(int filter) {
    setState(() {
      _selectedFilter = filter;
      _endDate = DateTime.now();
      switch (filter) {
        case 0: // 24h
          _startDate = _endDate.subtract(const Duration(days: 1));
          break;
        case 1: // 7d
          _startDate = _endDate.subtract(const Duration(days: 7));
          break;
        case 2: // 30d
          _startDate = _endDate.subtract(const Duration(days: 30));
          break;
      }
    });
    _fetchHistoryData();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedFilter = 3;
      });
      _fetchHistoryData();
    }
  }

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
            physics: const BouncingScrollPhysics(),
            slivers: [
              const AgroAppBar(),
              SliverPadding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.horizontalPadding,
                  vertical: 24,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    DateFilterWidget(
                      selectedFilter: _selectedFilter,
                      onFilterChanged: _setFilter,
                      onCustomDatePressed: () => _selectDateRange(context),
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Resumo do Período'),
                    const SizedBox(height: 12),

                    // Show a linear progress indicator if loading
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else ...[
                      _buildKPIsGrid(),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Nível de Bateria (%)'),
                      const SizedBox(height: 12),
                      BatteryChart(
                        data: _batteryData.isEmpty
                            ? [const FlSpot(0, 0)]
                            : _batteryData,
                      ),
                      const SizedBox(height: 24),

                      _buildSectionTitle('Análise de Hardware'),
                      const SizedBox(height: 12),
                      ActivityReport(activities: _activityTiles),
                    ],

                    const SizedBox(height: 120),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: colorScheme.primary.withAlpha(180),
      ),
    );
  }

  Widget _buildKPIsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: context.gridCrossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        KPICard(
          title: 'Bateria Final',
          value: _currentBattery,
          icon: Icons.battery_charging_full_rounded,
          iconColor: Colors.orange,
        ),
        KPICard(
          title: 'Registos',
          value: _dataPoints.toString(),
          icon: Icons.analytics_outlined,
          iconColor: Colors.blue,
        ),
        KPICard(
          title: 'Temp. Máxima',
          value: '$_maxTemp°C',
          icon: Icons.thermostat_rounded,
          iconColor: Colors.red,
        ),
        KPICard(
          title: 'CPU Médio',
          value: '$_avgCpu%',
          icon: Icons.memory_rounded,
          iconColor: Colors.purple,
        ),
      ],
    );
  }

  List<ActivityTile> get _activityTiles => [
    ActivityTile(
      title: 'Uso de Processador',
      value: '$_avgCpu% Avg',
      icon: Icons.speed,
      color: Colors.blue,
    ),
    ActivityTile(
      title: 'Estado Térmico',
      value: '$_maxTemp°C Max',
      icon: Icons.wb_sunny_rounded,
      color: Colors.orange,
    ),
    ActivityTile(
      title: 'Saúde do Sistema',
      value: 'Estável',
      icon: Icons.check_circle_outline_rounded,
      color: Colors.green,
    ),
    ActivityTile(
      title: 'Total de Telemetria',
      value: '$_dataPoints pontos',
      icon: Icons.cloud_done_rounded,
      color: Colors.teal,
    ),
  ];
}
