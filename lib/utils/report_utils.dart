import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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
    // A cada 100 linhas, liberta a thread para o browser respirar
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
// PDF Section — redesigned
// ─────────────────────────────────────────────────────────────────────────────

Future<void> buildAndPrintPdf({
  required Map<String, dynamic> summary,
  required DateTime startDate,
  required String fileName,
}) async {
  final pdf = pw.Document();

  // ── Cores do tema ──────────────────────────────────────────────────────────
  const primary = PdfColor.fromInt(0xFF1B5E20); // Verde escuro
  const primaryLight = PdfColor.fromInt(0xFF2E7D32); // Verde médio
  const accent = PdfColor.fromInt(0xFF69F0AE); // Verde néon
  const accentSoft = PdfColor.fromInt(0xFFE8F5E9); // Verde muito claro
  const textDark = PdfColor.fromInt(0xFF1A1A1A);
  const textMuted = PdfColor.fromInt(0xFF757575);
  const dividerColor = PdfColor.fromInt(0xFFBDBDBD);
  const white = PdfColors.white;
  const cardBg = PdfColor.fromInt(0xFFF9FBF9);

  // ── Carregar logo ──────────────────────────────────────────────────────────
  pw.ImageProvider? logoImage;
  try {
    final logoBytes = await rootBundle.load('assets/logo_512.png');
    logoImage = pw.MemoryImage(logoBytes.buffer.asUint8List());
  } catch (_) {
    // Logo não disponível — continua sem ele
  }

  // ── Fontes (built-in) ──────────────────────────────────────────────────────
  final fontBold = pw.Font.helveticaBold();
  final fontNormal = pw.Font.helvetica();

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Bloco de métrica individual com ícone textual, valor grande e label
  pw.Widget metricCard(String label, String value, String unit) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 4),
        padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: pw.BoxDecoration(
          color: cardBg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: accentSoft, width: 1.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(font: fontBold, fontSize: 22, color: primary),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              unit,
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 8,
                color: primaryLight,
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Container(height: 2, color: accent),
            pw.SizedBox(height: 6),
            pw.Text(
              label,
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 9,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Linha de tabela de resumo
  pw.Widget tableRow(String label, String value, {bool shaded = false}) {
    return pw.Container(
      color: shaded ? accentSoft : white,
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              font: fontNormal,
              fontSize: 10,
              color: textDark,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(font: fontBold, fontSize: 10, color: primary),
          ),
        ],
      ),
    );
  }

  /// Título de secção com barra lateral colorida
  pw.Widget sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 10, top: 6),
      child: pw.Row(
        children: [
          pw.Container(width: 4, height: 16, color: accent),
          pw.SizedBox(width: 8),
          pw.Text(
            text,
            style: pw.TextStyle(font: fontBold, fontSize: 13, color: primary),
          ),
        ],
      ),
    );
  }

  // ── Página principal ───────────────────────────────────────────────────────
  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),

      // ── Cabeçalho da página ───────────────────────────────────────────────
      header: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 20),
        decoration: pw.BoxDecoration(
          color: primary,
          borderRadius: pw.BorderRadius.circular(10),
        ),
        child: pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo + nome da app
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logoImage != null)
                    pw.Container(
                      width: 40,
                      height: 40,
                      decoration: pw.BoxDecoration(
                        color: white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(logoImage),
                    ),
                  if (logoImage != null) pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Agromotion',
                        style: pw.TextStyle(
                          font: fontBold,
                          color: accent,
                          fontSize: 18,
                        ),
                      ),
                      pw.Text(
                        'Relatório Operacional',
                        style: pw.TextStyle(
                          font: fontNormal,
                          color: white,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Data e período
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Gerado em: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: fontNormal,
                      color: white,
                      fontSize: 8,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: pw.BoxDecoration(
                      color: accent,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Text(
                      '${DateFormat('dd/MM/yy').format(startDate)} - ${DateFormat('dd/MM/yy').format(DateTime.now())}',
                      style: pw.TextStyle(
                        font: fontBold,
                        color: primary,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

      // ── Rodapé da página ──────────────────────────────────────────────────
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Agromotion',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 7,
                color: textMuted,
              ),
            ),
            pw.Text(
              'Pág. ${ctx.pageNumber} / ${ctx.pagesCount}',
              style: pw.TextStyle(
                font: fontNormal,
                fontSize: 7,
                color: textMuted,
              ),
            ),
          ],
        ),
      ),

      // ── Conteúdo ──────────────────────────────────────────────────────────
      build: (ctx) => [
        // Cards de métricas principais (linha 1)
        sectionTitle('Visão Geral'),
        pw.Row(
          children: [
            metricCard(
              'Total de Registos',
              summary['docCount'].toString(),
              'registos',
            ),
            metricCard('CPU Média', '${summary['avgCpu']}', '%'),
            metricCard('RAM Média', '${summary['avgRam'] ?? '--'}', '%'),
            metricCard('Atividade', '${summary['movingPct']}', '% do tempo'),
          ],
        ),
        pw.SizedBox(height: 10),

        // Segunda linha de cards
        pw.Row(
          children: [
            metricCard('Temp. Máxima', '${summary['maxTemp']}', '°C'),
            metricCard('Temp. Mínima', '${summary['minTemp'] ?? '--'}', '°C'),
            metricCard('Bateria Mínima', '${summary['minBat'] ?? '--'}', '%'),
            metricCard('Tensão Máxima', '${summary['maxVolt'] ?? '--'}', 'V'),
          ],
        ),
        pw.SizedBox(height: 20),

        // Tabela de detalhes
        sectionTitle('Detalhes do Período'),
        pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: dividerColor, width: 0.8),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            children: [
              // Cabeçalho da tabela
              pw.Container(
                color: primaryLight,
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Métrica',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: white,
                      ),
                    ),
                    pw.Text(
                      'Valor',
                      style: pw.TextStyle(
                        font: fontBold,
                        fontSize: 10,
                        color: white,
                      ),
                    ),
                  ],
                ),
              ),
              tableRow(
                'Total de Registos Analisados',
                '${summary['docCount']} registos',
                shaded: false,
              ),
              tableRow(
                'CPU Média do Sistema',
                '${summary['avgCpu']}%',
                shaded: true,
              ),
              tableRow(
                'CPU Máxima Registada',
                '${summary['maxCpu'] ?? '--'}%',
                shaded: false,
              ),
              tableRow(
                'RAM Média do Sistema',
                '${summary['avgRam'] ?? '--'}%',
                shaded: true,
              ),
              tableRow(
                'Temperatura Máxima',
                '${summary['maxTemp']}°C',
                shaded: false,
              ),
              tableRow(
                'Temperatura Mínima',
                '${summary['minTemp'] ?? '--'}°C',
                shaded: true,
              ),
              tableRow(
                'Bateria Média',
                '${summary['avgBat'] ?? '--'}%',
                shaded: false,
              ),
              tableRow(
                'Bateria Mínima Registada',
                '${summary['minBat'] ?? '--'}%',
                shaded: true,
              ),
              tableRow(
                'Tensão Máxima',
                '${summary['maxVolt'] ?? '--'} V',
                shaded: false,
              ),
              tableRow(
                'Tempo em Movimento',
                '${summary['movingPct']}% do período',
                shaded: true,
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 20),

        // Nota de rodapé do conteúdo
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: accentSoft,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
          ),
          child: pw.Text(
            'Este relatório foi gerado automaticamente com base nos dados de telemetria registados no período indicado. '
            'Os valores apresentados são calculados sobre todos os registos disponíveis na base de dados.',
            style: pw.TextStyle(
              font: fontNormal,
              fontSize: 8,
              color: textMuted,
            ),
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
