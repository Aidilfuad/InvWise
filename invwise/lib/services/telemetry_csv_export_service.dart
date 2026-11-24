import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import 'report_export_service.dart';
import 'reports_service.dart';

class TelemetryCsvExportService {
  const TelemetryCsvExportService();

  Future<String> export({
    required BuildContext context,
    required ReportTable report,
    required String fileName,
  }) async {
    final exporter = const ReportExportService();
    final bytes = exporter.toCsv(report);
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final path = await exporter.saveFile(bytes: bytes, fileName: fileName);
      if (context.mounted) _showMessage(context, 'CSV saved to $path');
      return path;
    }

    try {
      await SharePlus.instance.share(
        ShareParams(
          title: report.title,
          subject: report.title,
          files: [
            XFile.fromData(
              Uint8List.fromList(bytes),
              mimeType: 'text/csv',
              name: fileName,
            ),
          ],
          fileNameOverrides: [fileName],
        ),
      );
      return fileName;
    } on MissingPluginException {
      if (kIsWeb) rethrow;
      final path = await exporter.saveFile(bytes: bytes, fileName: fileName);
      if (context.mounted) _showMessage(context, 'CSV saved to $path');
      return path;
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
