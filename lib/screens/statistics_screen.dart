import 'dart:async';
import 'package:agromotion/widgets/statistics/date_filter.dart';
import 'package:agromotion/widgets/statistics/metric_grid.dart';
import 'package:agromotion/widgets/statistics/realtime_panel.dart';
import 'package:agromotion/widgets/statistics/summary_row.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/models/metric_data.dart';
import 'package:agromotion/services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _service = StatisticsService();
  StreamSubscription? _rtSub;

  // ── Date range ─────────────────────────────────────────────────────────────
  int _filterIndex = 0;
  DateTime _endDate = DateTime.now();
  DateTime get _startDate => _endDate.subtract(
    Duration(
      days: _filterIndex == 0
          ? 1
          : _filterIndex == 1
          ? 7
          : 30,
    ),
  );

  // ── State ──────────────────────────────────────────────────────────────────
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

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchHistory();
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
    setState(() => _isLoading = true);
    final res = await _service.getHistoryData(_startDate, _endDate);
    if (!mounted) return;
    setState(() {
      _history = Map<String, List<FlSpot>>.from(res['history'] ?? {});
      _summary = {
        'maxTemp': res['maxTemp'],
        'minTemp': res['minTemp'],
        'avgCpu': res['avgCpu'],
        'maxCpu': res['maxCpu'],
        'docCount': res['docCount'],
        'movingPct': res['movingPct'],
      };
      _isLoading = false;
    });
  }

  // -------------------------------------------------------------------------
  // Derived metric list for the history grid
  // -------------------------------------------------------------------------

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
      id: 'ram',
      title: 'RAM',
      unit: '%',
      value: '${_realtime.systemRam}%',
      icon: Icons.memory_rounded,
      color: const Color(0xFF66BB6A),
      history: _history['ram'] ?? [],
    ),
    MetricData(
      id: 'temperature',
      title: 'Temperatura',
      unit: '°C',
      value: '${_realtime.systemTemperature.toStringAsFixed(1)}°C',
      icon: Icons.device_thermostat_rounded,
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
    MetricData(
      id: 'current',
      title: 'Corrente',
      unit: 'A',
      value: '${_realtime.batteryCurrent.toStringAsFixed(1)} A',
      icon: Icons.electrical_services_rounded,
      color: const Color(0xFFEF5350),
      history: _history['current'] ?? [],
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
      label: 'EM MOVIMENTO',
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

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(gradient: colors.backgroundGradient),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: CustomScrollView(
            slivers: [
              const AgroAppBar(),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Date filter ────────────────────────────────────────
                    DateFilter(
                      selected: _filterIndex,
                      onChanged: (i) {
                        setState(() {
                          _filterIndex = i;
                          _endDate = DateTime.now();
                        });
                        _fetchHistory();
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Summary strip ─────────────────────────────────────
                    _SectionLabel(text: 'Resumo do período'),
                    const SizedBox(height: 12),
                    SummaryRow(tiles: _summaryTiles),
                    const SizedBox(height: 24),

                    // ── Live status ───────────────────────────────────────
                    _SectionLabel(text: 'Estado em tempo real'),
                    const SizedBox(height: 12),
                    RealtimePanel(snapshot: _realtime),
                    const SizedBox(height: 24),

                    // ── History grid ──────────────────────────────────────
                    _SectionLabel(text: 'Histórico de telemetria'),
                    const SizedBox(height: 12),
                    _isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: CircularProgressIndicator(
                                color: cs.primary,
                                strokeWidth: 2,
                              ),
                            ),
                          )
                        : MetricsGrid(metrics: _metrics, startTime: _startDate),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Consistent section label used throughout the screen.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.4,
        color: cs.onSurface.withAlpha(90),
      ),
    );
  }
}
