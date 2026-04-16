import 'dart:io';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:agromotion/utils/report_utils.dart';
import 'package:agromotion/services/statistics_service.dart';
import 'package:agromotion/widgets/statistics/date_filter.dart';

class ReportService {
  final _statsService = StatisticsService();

  String _getFileName(String extension, String label) {
    final dateStr = DateFormat('ddMMyyyy').format(DateTime.now());
    return 'report_${label.toLowerCase()}_$dateStr.$extension';
  }

  String _getLabel(DateFilterProvider filter) {
    switch (filter.selectedIndex) {
      case 0:
        return '24h';
      case 1:
        return '7d';
      case 2:
        return '30d';
      default:
        return 'custom';
    }
  }

  Future<void> generateExcel(DateFilterProvider filter) async {
    final rawData = await _statsService.getRawHistoryData(
      filter.range.start,
      filter.range.end,
    );

    if (rawData.isEmpty) throw Exception('Sem dados no período.');

    final Uint8List? bytes = await buildExcelReport(
      rawData: rawData,
      filterIndex: filter.selectedIndex,
      startDate: filter.range.start,
    );

    if (bytes == null) throw Exception('Erro ao gerar Excel.');

    await _handleExport(bytes, _getFileName('xlsx', _getLabel(filter)));
  }

  Future<void> generatePdf(DateFilterProvider filter) async {
    final summary = await _statsService.getHistoryData(
      filter.range.start,
      filter.range.end,
    );

    final fileName = _getFileName('pdf', _getLabel(filter));

    await buildAndPrintPdf(
      summary: summary,
      startDate: filter.range.start,
      fileName: fileName,
    );
  }

  Future<void> _handleExport(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'Relatório Agromotion');
    }
  }
}
