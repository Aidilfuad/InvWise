import 'dart:io';
import 'dart:convert';

import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:invwise/services/report_export_service.dart';
import 'package:invwise/services/reports_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  const report = ReportTable(
    title: 'Inventory Summary Report',
    headers: ['SKU', 'Item'],
    rows: [
      ['SKU-1', 'Pipe, "large"'],
    ],
    metrics: [ReportMetric('Items', '1')],
  );
  const exporter = ReportExportService();
  Directory? documentsDirectory;

  setUp(() async {
    documentsDirectory = await Directory.systemTemp.createTemp(
      'invwise-report-export-',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          expect(call.method, 'getApplicationDocumentsDirectory');
          return documentsDirectory!.path;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    final directory = documentsDirectory;
    if (directory != null && await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('CSV export quotes fields and preserves UTF-8 BOM', () {
    final bytes = exporter.toCsv(report);

    expect(bytes.take(3), [0xEF, 0xBB, 0xBF]);
    expect(
      utf8.decode(bytes.skip(3).toList()),
      '"SKU","Item"\r\n"SKU-1","Pipe, ""large"""',
    );
  });

  test('Excel export produces a readable XLSX workbook', () {
    final workbook = Excel.decodeBytes(exporter.toExcel(report));

    expect(workbook.tables.keys, contains('Sheet1'));
    expect(workbook.tables['Sheet1']!.rows, isNotEmpty);
  });

  test(
    'local fallback writes report files into Documents/InvWiseReports',
    () async {
      final path = await exporter.saveFile(
        bytes: exporter.toCsv(report),
        fileName: 'report.csv',
      );
      final file = File(path);

      expect(
        path,
        '${documentsDirectory!.path}${Platform.pathSeparator}'
        'InvWiseReports${Platform.pathSeparator}report.csv',
      );
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), exporter.toCsv(report));
    },
  );
}
