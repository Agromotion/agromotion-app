import 'dart:io';
import 'dart:typed_data';

import 'package:agromotion/theme/app_theme.dart';
import 'package:agromotion/utils/report_utils.dart' hide Icons;
import 'package:agromotion/widgets/agro_appbar.dart';
import 'package:agromotion/services/statistics_service.dart';
import 'package:agromotion/widgets/statistics/date_filter.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  final _service = StatisticsService();
  int _filterIndex = 0;
  _GeneratingState _generatingState = _GeneratingState.idle;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  DateTime get _startDate => DateTime.now().subtract(
    Duration(
      days: _filterIndex == 0
          ? 1
          : _filterIndex == 1
          ? 7
          : 30,
    ),
  );

  bool get _isGenerating => _generatingState != _GeneratingState.idle;

  // ── Excel ──────────────────────────────────────────────────────────────────
  Future<void> _generateExcel() async {
    setState(() => _generatingState = _GeneratingState.excel);
    try {
      final rawData = await _service.getRawHistoryData(
        _startDate,
        DateTime.now(),
      );

      if (rawData.isEmpty) {
        _showSnack('Sem dados para o período selecionado.', isError: true);
        return;
      }

      final Uint8List? bytes = await buildExcelReport(
        rawData: rawData,
        filterIndex: _filterIndex,
        startDate: _startDate,
      );

      if (bytes == null) {
        _showSnack('Erro ao gerar o ficheiro Excel.', isError: true);
        return;
      }

      final fileName =
          'report_${_filterLabel()}_${DateFormat('ddMMyyyy').format(DateTime.now())}.xlsx';

      if (kIsWeb) {
        // Web: trigger browser download
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
        _showSnack('Excel descarregado com sucesso!');
      } else {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(bytes);
        await Share.shareXFiles([
          XFile(file.path),
        ], text: 'Relatório Agromotion');
        _showSnack('Excel partilhado com sucesso!');
      }
    } catch (e) {
      _showSnack('Erro inesperado: $e', isError: true);
    } finally {
      setState(() => _generatingState = _GeneratingState.idle);
    }
  }

  // ── PDF ────────────────────────────────────────────────────────────────────
  Future<void> _generatePdf() async {
    setState(() => _generatingState = _GeneratingState.pdf);
    try {
      final summary = await _service.getHistoryData(_startDate, DateTime.now());

      final fileName = 'report_${_filterLabel()}_${DateFormat('ddMMyyyy').format(DateTime.now())}.pdf';
      await buildAndPrintPdf(summary: summary, startDate: _startDate,fileName: fileName);
      _showSnack('PDF gerado com sucesso!');
    } catch (e) {
      _showSnack('Erro ao gerar PDF: $e', isError: true);
    } finally {
      setState(() => _generatingState = _GeneratingState.idle);
    }
  }

  String _filterLabel() => _filterIndex == 0
      ? '24h'
      : _filterIndex == 1
      ? '7d'
      : '30d';

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError
            ? Colors.red.shade800
            : const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

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
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Period selector
                    _SectionLabel(label: 'Período de Análise'),
                    const SizedBox(height: 10),
                    DateFilter(
                      selected: _filterIndex,
                      onChanged: (i) => setState(() => _filterIndex = i),
                    ),

                    const SizedBox(height: 32),

                    // Info card
                    _InfoBanner(filterLabel: _filterLabel()),

                    const SizedBox(height: 32),
                    _SectionLabel(label: 'Exportar Relatório'),
                    const SizedBox(height: 12),

                    // Excel card
                    _ReportCard(
                      title: 'Exportar para Excel',
                      subtitle:
                          'Tabela completa com telemetria raw + folha de sumário estatístico.',
                      badge: '.XLSX',
                      icon: Icons.table_chart_rounded,
                      accentColor: const Color(0xFF69F0AE),
                      isLoading: _generatingState == _GeneratingState.excel,
                      disabled: _isGenerating,
                      onTap: _generateExcel,
                      features: const [
                        'Dados brutos completos',
                        'Folha de sumário automática',
                        'Compatível com Excel & Sheets',
                      ],
                    ),

                    const SizedBox(height: 16),

                    // PDF card
                    _ReportCard(
                      title: 'Gerar Relatório PDF',
                      subtitle:
                          'Documento formatado com insights, KPIs e análise do período.',
                      badge: '.PDF',
                      icon: Icons.picture_as_pdf_rounded,
                      accentColor: const Color(0xFFFFB74D),
                      isLoading: _generatingState == _GeneratingState.pdf,
                      disabled: _isGenerating,
                      onTap: _generatePdf,
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

        // Global loading overlay
        if (_isGenerating)
          _LoadingOverlay(
            pulseAnim: _pulseAnim,
            label: _generatingState == _GeneratingState.excel
                ? 'A preparar Excel…'
                : 'A gerar PDF…',
          ),
      ],
    );
  }
}

// ─── Supporting widgets ────────────────────────────────────────────────────────

enum _GeneratingState { idle, excel, pdf }

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String filterLabel;
  const _InfoBanner({required this.filterLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF69F0AE).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFF69F0AE),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Relatório baseado na telemetria do robô',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Os dados cobrem as últimas $filterLabel de operação registada no sistema.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final IconData icon;
  final Color accentColor;
  final bool isLoading;
  final bool disabled;
  final VoidCallback? onTap;
  final List<String> features;

  const _ReportCard({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.icon,
    required this.accentColor,
    required this.isLoading,
    required this.disabled,
    required this.onTap,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: disabled && !isLoading ? 0.45 : 1.0,
      child: Material(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(18),
          splashColor: accentColor.withValues(alpha: 0.1),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isLoading
                    ? accentColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.08),
                width: isLoading ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: accentColor, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Divider(color: Colors.white.withValues(alpha: 0.06)),
                const SizedBox(height: 12),

                // Feature list
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline_rounded,
                          color: accentColor.withValues(alpha: 0.7),
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          f,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isLoading
                          ? accentColor.withValues(alpha: 0.08)
                          : accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.3),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: accentColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'A gerar…',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: accentColor,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Gerar e Exportar',
                                style: TextStyle(
                                  color: accentColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  final Animation<double> pulseAnim;
  final String label;

  const _LoadingOverlay({required this.pulseAnim, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: ScaleTransition(
          scale: pulseAnim,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2A1A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF69F0AE).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF69F0AE),
                  strokeWidth: 2.5,
                ),
                const SizedBox(height: 16),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
