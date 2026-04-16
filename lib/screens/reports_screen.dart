import 'package:agromotion/widgets/agro_loading.dart';
import 'package:agromotion/widgets/agro_snackbar.dart';
import 'package:agromotion/widgets/reports/report_card.dart';
import 'package:agromotion/widgets/section_label.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/widgets/statistics/date_filter.dart';
import 'package:agromotion/services/report_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

enum _GeneratingState { idle, excel, pdf }

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _reportService = ReportService();
  _GeneratingState _generatingState = _GeneratingState.idle;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _isGenerating => _generatingState != _GeneratingState.idle;

  Future<void> _handleGeneration(
    Future<void> Function(DateFilterProvider) action,
    _GeneratingState state,
  ) async {
    final filter = context.read<DateFilterProvider>();
    setState(() => _generatingState = state);

    try {
      await action(filter);
    } catch (e) {
      AgroSnackbar.show(
        context,
        message: e.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _generatingState = _GeneratingState.idle);
    }
  }

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
          body: CustomScrollView(
            slivers: [
              const AgroAppBar(
                showBackButton: true,
                title: 'Relatórios',
                subtitle: 'Exportação de telemetria',
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 5, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SectionLabel(label: 'Período de Análise'),
                    const SizedBox(height: 10),
                    DateFilter(
                      selected: filterProvider.selectedIndex,
                      onChanged: (i) => filterProvider.setFilter(i),
                      onCustomPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange: filterProvider.range,
                        );
                        if (picked != null && context.mounted) {
                          filterProvider.setCustomRange(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 32),
                    const SectionLabel(label: 'Exportar Relatório'),
                    const SizedBox(height: 12),
                    ReportCard(
                      title: 'Exportar para Excel',
                      badge: '.XLSX',
                      icon: Icons.table_chart_rounded,
                      isLoading: _generatingState == _GeneratingState.excel,
                      disabled: _isGenerating,
                      onTap: () => _handleGeneration(
                        _reportService.generateExcel,
                        _GeneratingState.excel,
                      ),
                      features: const [
                        'Dados brutos completos',
                        'Folha de sumário automática',
                        'Compatível com Excel & Sheets',
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReportCard(
                      title: 'Gerar Relatório PDF',
                      badge: '.PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      isLoading: _generatingState == _GeneratingState.pdf,
                      disabled: _isGenerating,
                      onTap: () => _handleGeneration(
                        _reportService.generatePdf,
                        _GeneratingState.pdf,
                      ),
                      features: const [
                        'KPIs visuais em destaque',
                        'Análise automática de dados',
                        'Pronto para imprimir/partilhar',
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
        if (_isGenerating)
          Container(
            color: Colors.black.withValues(
              alpha: 0.4,
            ), // Overlay suave para o loading
            child: const Center(child: AgroLoading()),
          ),
      ],
    );
  }
}
