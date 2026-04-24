import 'dart:async';
import 'package:agromotion/screens/reports_screen.dart';
import 'package:agromotion/widgets/section_label.dart';
import 'package:agromotion/widgets/statistics/date_filter.dart';
import 'package:agromotion/widgets/statistics/metric_grid.dart';
import 'package:agromotion/widgets/statistics/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
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
  StreamSubscription? _historySub;

  // Controla apenas o loading inicial (primeira carga ou mudança de filtro)
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeHistory());

    _rtSub = _service.getRealtimeStatus().listen((snap) {
      if (!snap.exists || !mounted) return;
      setState(() {
        _realtime = TelemetrySnapshot.fromMap(snap.data()!);
      });
    });
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }

  /// [showLoading] true apenas na primeira carga ou ao mudar filtro.
  /// Atualizações em tempo real via stream não mostram loading.
  void _subscribeHistory({bool showLoading = true}) {
    if (!mounted) return;
    final filter = context.read<DateFilterProvider>();
    _historySub?.cancel();

    if (showLoading) setState(() => _isLoading = true);

    bool firstEmission = true;

    _historySub = _service
        .streamHistoryData(filter.range.start, filter.range.end)
        .listen((res) {
          if (!mounted) return;

          setState(() {
            // 1. Atualiza o histórico (o que faz o gráfico mexer)
            _history = Map<String, List<FlSpot>>.from(res['history'] ?? {});

            final tempSpots = _history['temperature'] ?? [];
            final cpuSpots = _history['cpu'] ?? [];

            // 2. RECALCULA na hora com os dados que acabaram de chegar na Stream
            _summary = {
              'maxTemp': tempSpots.isEmpty
                  ? '0'
                  : tempSpots
                        .map((s) => s.y)
                        .reduce((a, b) => a > b ? a : b)
                        .toStringAsFixed(1),
              'minTemp': tempSpots.isEmpty
                  ? '0'
                  : tempSpots
                        .map((s) => s.y)
                        .reduce((a, b) => a < b ? a : b)
                        .toStringAsFixed(1),
              'avgCpu': cpuSpots.isEmpty
                  ? '0'
                  : (cpuSpots.map((s) => s.y).reduce((a, b) => a + b) /
                            cpuSpots.length)
                        .toStringAsFixed(1),
              'maxCpu': cpuSpots.isEmpty
                  ? '0'
                  : cpuSpots
                        .map((s) => s.y)
                        .reduce((a, b) => a > b ? a : b)
                        .toStringAsFixed(1),
              'docCount': res['docCount']?.toString() ?? '0',
              'movingPct': res['movingPct']?.toString() ?? '0',
            };

            if (firstEmission) {
              _isLoading = false;
              firstEmission = false;
            }
          });
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
      value: '${_realtime.batteryVoltage.toStringAsFixed(1)}V',
      icon: Icons.bolt_rounded,
      color: const Color(0xFFFDD835),
      history: _history['voltage'] ?? [],
    ),
  ];

  List<SummaryTileData> get _summaryTiles => [
    SummaryTileData(
      label:
          'TEMP. ATUAL', // Mudança sugerida de MÁX para ATUAL se quiser real-time
      value: '${_realtime.systemTemperature.toStringAsFixed(1)}°C',
      icon: Icons.thermostat_rounded,
      color: const Color(0xFFFFA726),
    ),
    SummaryTileData(
      label: 'CPU ATUAL',
      value: '${_realtime.systemCpu}%',
      icon: Icons.developer_board_rounded,
      color: const Color(0xFF42A5F5),
    ),
    // Estes geralmente dependem de agregação do histórico (DB), então continuam vindo do _summary
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

    final filterProvider = context.watch<DateFilterProvider>();

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: customColors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: _isLoading
              ? const CustomScrollView(
                  slivers: [
                    AgroAppBar(title: 'Estatísticas'),
                    SliverFillRemaining(child: Center(child: AgroLoading())),
                  ],
                )
              : RefreshIndicator(
                  // Pull-to-refresh silencioso — não mostra loading
                  onRefresh: () async => _subscribeHistory(showLoading: false),
                  color: colorScheme.primary,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
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
                            const SectionLabel(label: 'Período'),
                            const SizedBox(height: 8),
                            DateFilter(
                              selected: filterProvider.selectedIndex,
                              onChanged: (index) {
                                filterProvider.setFilter(index);
                                _subscribeHistory();
                              },
                              onCustomPressed: () async {
                                final picked = await showDateRangePicker(
                                  context: context,
                                  firstDate: DateTime(2024),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                  initialDateRange: filterProvider.range,
                                  builder: (context, child) {
                                    return Theme(
                                      data: theme.copyWith(
                                        colorScheme: colorScheme.copyWith(
                                          primary: colorScheme.primary,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );

                                if (picked != null && mounted) {
                                  filterProvider.setCustomRange(picked);
                                  _subscribeHistory();
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: _ReportsButton(cs: colorScheme),
                            ),
                            const SizedBox(height: 24),
                            const SectionLabel(label: 'Resumo do período'),
                            const SizedBox(height: 12),
                            SummaryRow(tiles: _summaryTiles),
                            const SizedBox(height: 32),
                            const SectionLabel(label: 'Evolução Temporal'),
                            const SizedBox(height: 12),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withOpacity(0.2),
          border: Border.all(color: cs.primary.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.analytics_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 10),
            Text(
              'Relatórios',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: cs.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
