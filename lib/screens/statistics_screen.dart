import 'dart:async';
import 'package:agromotion/screens/reports_screen.dart';
import 'package:agromotion/widgets/section_label.dart';
import 'package:agromotion/widgets/statistics/date_filter.dart';
import 'package:agromotion/widgets/statistics/metric_grid.dart';
import 'package:agromotion/widgets/statistics/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart'; // Adicionado Provider
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/widgets/agro_loading.dart';
import 'package:agromotion/models/metric_data.dart';
import 'package:agromotion/services/statistics_service.dart';
import 'package:agromotion/utils/responsive_layout.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _service = StatisticsService();
  StreamSubscription? _rtSub;

  bool _isLoading = true;
  TelemetrySnapshot _realtime = const TelemetrySnapshot();
  Map<String, List<FlSpot>> _history = {};
  Map<String, String> _summary = {
    'maxTemp': '0',
    'minTemp': '0',
    'avgCpu': '0',
    'maxCpu': '0',
    'docCount': '0',
    'movingPct': '0',
  };

  @override
  void initState() {
    super.initState();
    // Agendamos o fetch para o próximo frame para garantir que o context/provider estejam prontos
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchHistory());

    _rtSub = _service.getRealtimeStatus().listen((snap) {
      if (!snap.exists || !mounted) return;
      final data = snap.data()!;
      setState(() {
        _realtime = TelemetrySnapshot.fromMap(
          data['telemetry'] as Map<String, dynamic>? ?? {},
        );
      });
    });
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchHistory() async {
    if (!mounted) return;

    // Pegamos o range atual do Provider
    final filter = context.read<DateFilterProvider>();

    setState(() => _isLoading = true);

    final res = await _service.getHistoryData(
      filter.range.start,
      filter.range.end,
    );

    if (!mounted) return;
    setState(() {
      _history = Map<String, List<FlSpot>>.from(res['history'] ?? {});
      _summary = {
        'maxTemp': res['maxTemp'] ?? '0',
        'minTemp': res['minTemp'] ?? '0',
        'avgCpu': res['avgCpu'] ?? '0',
        'maxCpu': res['maxCpu'] ?? '0',
        'docCount': res['docCount'] ?? '0',
        'movingPct': res['movingPct'] ?? '0',
      };
      _isLoading = false;
    });
  }

  List<MetricData> get _metrics => [
    MetricData(
      id: 'cpu',
      title: 'CPU',
      unit: '%',
      value: '${_realtime.systemCpu}%',
      icon: Icons.developer_board_rounded,
      color: const Color(0xFF42A5F5),
      history: _history['cpu'] ?? [],
    ),
    MetricData(
      id: 'temperature',
      title: 'Temperatura',
      unit: '°C',
      value: '${_realtime.systemTemperature.toStringAsFixed(1)}°C',
      icon: Icons.thermostat_rounded,
      color: const Color(0xFFFFA726),
      history: _history['temperature'] ?? [],
    ),
    MetricData(
      id: 'battery',
      title: 'Bateria',
      unit: '%',
      value: '${_realtime.batteryPercentage}%',
      icon: Icons.battery_full_rounded,
      color: const Color(0xFF26C6DA),
      history: _history['battery'] ?? [],
    ),
    MetricData(
      id: 'voltage',
      title: 'Tensão',
      unit: 'V',
      value: '${_realtime.batteryVoltage.toStringAsFixed(1)} V',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFDD835),
      history: _history['voltage'] ?? [],
    ),
  ];

  List<SummaryTileData> get _summaryTiles => [
    SummaryTileData(
      label: 'TEMP. MÁX',
      value: '${_summary['maxTemp']}°C',
      icon: Icons.thermostat_rounded,
      color: const Color(0xFFFFA726),
    ),
    SummaryTileData(
      label: 'MÉDIA CPU',
      value: '${_summary['avgCpu']}%',
      icon: Icons.developer_board_rounded,
      color: const Color(0xFF42A5F5),
    ),
    SummaryTileData(
      label: 'MOVIMENTO',
      value: '${_summary['movingPct']}%',
      icon: Icons.directions_run_rounded,
      color: const Color(0xFF66BB6A),
    ),
    SummaryTileData(
      label: 'REGISTOS',
      value: _summary['docCount'] ?? '0',
      icon: Icons.history_rounded,
      color: const Color(0xFFCE93D8),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final customColors = theme.extension<AppColorsExtension>()!;

    // Escutamos o provider para reagir a mudanças de data
    final filterProvider = context.watch<DateFilterProvider>();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? CustomScrollView(
                  slivers: [
                    const AgroAppBar(title: 'Estatísticas'),
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: AgroLoading()),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _fetchHistory,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      const AgroAppBar(title: 'Estatísticas'),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          5,
                          context.horizontalPadding,
                          140,
                        ),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // 1. Filtros
                            const SectionLabel(label: 'Período'),
                            const SizedBox(height: 8),
                            DateFilter(
                              selected: filterProvider.selectedIndex,
                              onChanged: (index) {
                                context.read<DateFilterProvider>().setFilter(
                                  index,
                                );
                                _fetchHistory();
                              },
                              onCustomPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                  initialDateRange: filterProvider.range,
                                );

                                if (picked != null && context.mounted) {
                                  context
                                      .read<DateFilterProvider>()
                                      .setCustomRange(picked);
                                  _fetchHistory();
                                }
                              },
                            ),

                            // 2. Relatórios
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _ReportsButton(cs: colorScheme),
                            ),

                            // 3. Resumo
                            const SizedBox(height: 16),
                            const SectionLabel(label: 'Resumo do período'),
                            const SizedBox(height: 10),
                            SummaryRow(tiles: _summaryTiles),

                            // 4. Evolução Temporal
                            const SizedBox(height: 20),
                            const SectionLabel(label: 'Evolução Temporal'),
                            const SizedBox(height: 10),
                            MetricsGrid(
                              metrics: _metrics,
                              startTime: filterProvider.range.start,
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ReportsButton extends StatelessWidget {
  const _ReportsButton({required this.cs});
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportsScreen()),
      ),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.3),
          border: Border.all(color: cs.primary.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 14, color: cs.primary),
            const SizedBox(width: 8),
            Text(
              'Relatórios',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
