import 'dart:io';
import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'reports_service.dart';

class ReportExportService {
  const ReportExportService();

  Future<String> saveFile({
    required List<int> bytes,
    required String fileName,
  }) async {
    final safeFileName = _safeFileName(fileName);
    final documents = await getApplicationDocumentsDirectory();
    final exportDirectory = Directory(
      '${documents.path}${Platform.pathSeparator}InvWiseReports',
    );
    await exportDirectory.create(recursive: true);
    final file = File(
      '${exportDirectory.path}${Platform.pathSeparator}$safeFileName',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<String> saveInDocuments({
    required List<int> bytes,
    required String fileName,
  }) => saveFile(bytes: bytes, fileName: fileName);

  String _safeFileName(String fileName) =>
      fileName.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');

  List<int> toCsv(ReportTable report) {
    final csv = [
      _encodeCsvRow(report.headers),
      for (final row in report.rows) _encodeCsvRow(row),
    ].join('\r\n');
    return utf8.encode('\uFEFF$csv');
  }

  List<int> toExcel(ReportTable report) {
    final workbook = Excel.createExcel();
    final defaultSheet = workbook.getDefaultSheet();
    if (defaultSheet == null) {
      throw StateError('The Excel workbook does not contain a worksheet.');
    }

    final sheet = workbook[defaultSheet];
    sheet.appendRow([TextCellValue(report.title)]);
    for (final metric in report.metrics) {
      sheet.appendRow([
        TextCellValue(metric.label),
        TextCellValue(metric.value),
      ]);
    }
    sheet.appendRow(const []);
    sheet.appendRow(report.headers.map(TextCellValue.new).toList());
    for (final row in report.rows) {
      sheet.appendRow(row.map(TextCellValue.new).toList());
    }

    final bytes = workbook.save();
    if (bytes == null || bytes.isEmpty) {
      throw StateError('Excel workbook generation returned no data.');
    }
    return bytes;
  }

  String _encodeCsvRow(List<String> cells) => cells
      .map((cell) {
        final escaped = cell.replaceAll('"', '""');
        return '"$escaped"';
      })
      .join(',');
}
