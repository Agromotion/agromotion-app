import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Generates and shares an Excel report from raw telemetry data.
/// Optimized for Web to avoid Stack Overflow.
Future<Uint8List?> buildExcelReport({
  required List<Map<String, dynamic>> rawData,
  required int filterIndex,
  required DateTime startDate,
}) async {
  final excel = Excel.createExcel();

  final String defaultSheet = excel.getDefaultSheet()!;
  excel.rename(defaultSheet, 'Telemetria');
  final Sheet telSheet = excel['Telemetria'];

  // Definir estilos FORA do loop para reaproveitamento de memória
  final CellStyle headerStyle = CellStyle(
    bold: true,
    backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
    fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    horizontalAlign: HorizontalAlign.Center,
  );

  final CellStyle evenRowStyle = CellStyle(
    backgroundColorHex: ExcelColor.fromHexString('#F1F8E9'),
  );

  final CellStyle oddRowStyle = CellStyle();

  final headers = [
    'Data/Hora',
    'Bateria %',
    'Tensão (V)',
    'Corrente (A)',
    'CPU %',
    'RAM %',
    'Temp °C',
    'Altitude (m)',
    'Em Movimento',
  ];

  // Escrever Headers
  for (var i = 0; i < headers.length; i++) {
    var cell = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
    );
    cell.value = TextCellValue(headers[i]);
    cell.cellStyle = headerStyle;
  }

  // Preencher Dados
  for (var i = 0; i < rawData.length; i++) {
    // ESSENCIAL PARA WEB: A cada 100 linhas, liberta a thread para o browser respirar
    if (kIsWeb && i % 100 == 0) {
      await Future.delayed(Duration.zero);
    }

    final d = rawData[i];
    final rowIndex = i + 1;
    final currentStyle = i.isEven ? evenRowStyle : oddRowStyle;

    // Data/Hora
    var c0 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    c0.value = TextCellValue(
      DateFormat(
        'dd/MM/yyyy HH:mm',
      ).format((d['timestamp'] as Timestamp).toDate()),
    );
    c0.cellStyle = currentStyle;

    // Bateria %
    var c1 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );
    c1.value = DoubleCellValue(
      (d['battery_percentage'] as num? ?? 0).toDouble(),
    );
    c1.cellStyle = currentStyle;

    // Tensão
    var c2 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex),
    );
    c2.value = DoubleCellValue((d['battery_voltage'] as num? ?? 0).toDouble());
    c2.cellStyle = currentStyle;

    // Corrente
    var c3 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex),
    );
    c3.value = DoubleCellValue((d['battery_current'] as num? ?? 0).toDouble());
    c3.cellStyle = currentStyle;

    // CPU
    var c4 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex),
    );
    c4.value = DoubleCellValue((d['system_cpu'] as num? ?? 0).toDouble());
    c4.cellStyle = currentStyle;

    // RAM
    var c5 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex),
    );
    c5.value = DoubleCellValue((d['system_ram'] as num? ?? 0).toDouble());
    c5.cellStyle = currentStyle;

    // Temp
    var c6 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex),
    );
    c6.value = DoubleCellValue(
      (d['system_temperature'] as num? ?? 0).toDouble(),
    );
    c6.cellStyle = currentStyle;

    // Altitude
    var c7 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex),
    );
    c7.value = DoubleCellValue((d['gps_altitude'] as num? ?? 0).toDouble());
    c7.cellStyle = currentStyle;

    // Movimento
    var c8 = telSheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex),
    );
    c8.value = TextCellValue(d['robot_moving'] == true ? 'SIM' : 'NÃO');
    c8.cellStyle = currentStyle;
  }

  // Larguras das colunas
  final widths = [20.0, 10.0, 12.0, 12.0, 10.0, 10.0, 10.0, 12.0, 15.0];
  for (var i = 0; i < widths.length; i++) {
    telSheet.setColumnWidth(i, widths[i]);
  }

  // ── Sheet 2: Summary ─────────────────────────────────────────────────────
  if (rawData.isNotEmpty) {
    final Sheet sumSheet = excel['Sumário'];
    final CellStyle sumHeader = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#1B5E20'),
      fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
    );

    double maxTemp = -999, minTemp = 999, totalCpu = 0, maxCpu = 0;
    double totalBat = 0, minBat = 100, maxVolt = 0;
    int movingCount = 0;

    for (final d in rawData) {
      final temp = (d['system_temperature'] as num? ?? 0).toDouble();
      final cpu = (d['system_cpu'] as num? ?? 0).toDouble();
      final bat = (d['battery_percentage'] as num? ?? 0).toDouble();
      final volt = (d['battery_voltage'] as num? ?? 0).toDouble();

      if (temp > maxTemp) maxTemp = temp;
      if (temp < minTemp) minTemp = temp;
      totalCpu += cpu;
      if (cpu > maxCpu) maxCpu = cpu;
      totalBat += bat;
      if (bat < minBat) minBat = bat;
      if (volt > maxVolt) maxVolt = volt;
      if (d['robot_moving'] == true) movingCount++;
    }

    final count = rawData.length;
    final summaryRows = [
      ['Métrica', 'Valor'],
      ['Período', '${DateFormat('dd/MM/yy').format(startDate)} → Hoje'],
      ['Total de Registos', count.toString()],
      ['CPU Média', '${(totalCpu / count).toStringAsFixed(1)}%'],
      ['CPU Máxima', '${maxCpu.toStringAsFixed(1)}%'],
      ['Temp. Máxima', '${maxTemp.toStringAsFixed(1)} °C'],
      ['Temp. Mínima', '${minTemp.toStringAsFixed(1)} °C'],
      ['Bateria Média', '${(totalBat / count).toStringAsFixed(1)}%'],
      ['Bateria Mínima', '${minBat.toStringAsFixed(1)}%'],
      ['Tensão Máxima', '${maxVolt.toStringAsFixed(2)} V'],
      ['Em Movimento', '$movingCount registos'],
      [
        'Atividade',
        '${(movingCount / count * 100).toStringAsFixed(0)}% do tempo',
      ],
    ];

    for (var r = 0; r < summaryRows.length; r++) {
      for (var c = 0; c < 2; c++) {
        var cell = sumSheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r),
        );
        cell.value = TextCellValue(summaryRows[r][c]);
        if (r == 0) cell.cellStyle = sumHeader;
      }
    }
    sumSheet.setColumnWidth(0, 25.0);
    sumSheet.setColumnWidth(1, 20.0);
  }

  final List<int>? bytes = excel.encode();
  if (bytes == null) return null;
  return Uint8List.fromList(bytes);
}

// ─────────────────────────────────────────────────────────────────────────────
// PDF Section (Mantida igual, mas com import fix)
// ─────────────────────────────────────────────────────────────────────────────

Future<void> buildAndPrintPdf({
  required Map<String, dynamic> summary,
  required DateTime startDate,
  required String fileName,
}) async {
  final pdf = pw.Document();

  // Cores
  const primary = PdfColor.fromInt(0xFF1B5E20);
  const accent = PdfColor.fromInt(0xFF69F0AE);
  const textMuted = PdfColor.fromInt(0xFF666666);

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: primary,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'AGROMOTION',
                style: pw.TextStyle(
                  color: accent,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Relatório Operacional',
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 10),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Simples grid para PDF
        pw.Text(
          'RESUMO DO PERÍODO',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primary),
        ),
        pw.Divider(color: accent),
        pw.SizedBox(height: 10),

        _pdfMetricRow('Total de Registos', summary['docCount'].toString()),
        _pdfMetricRow('CPU Média', '${summary['avgCpu']}%'),
        _pdfMetricRow('Temp Máxima', '${summary['maxTemp']}°C'),
        _pdfMetricRow('Atividade (Movimento)', '${summary['movingPct']}%'),

        pw.SizedBox(height: 40),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8, color: textMuted),
          ),
        ),
      ],
    ),
  );

  await Printing.layoutPdf(
    onLayout: (format) async => pdf.save(),
    name: fileName,
  );
}

pw.Widget _pdfMetricRow(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 4),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ],
    ),
  );
}
