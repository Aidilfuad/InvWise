import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import 'report_section_header.dart';

class ExportReportActions extends StatelessWidget {
  const ExportReportActions({
    super.key,
    this.onExportCsvTap,
    this.onExportExcelTap,
    this.isExporting = false,
  });

  final VoidCallback? onExportCsvTap;
  final VoidCallback? onExportExcelTap;
  final bool isExporting;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge
        ?.copyWith(fontWeight: FontWeight.w700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ReportSectionHeader(
          title: 'Export Reports',
          subtitle: 'Export the selected report',
        ),
        AppSpacing.gapMd,
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: isExporting ? null : onExportCsvTap,
                icon: const Icon(Icons.table_rows_rounded, size: 20),
                label: const Text('Export CSV'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(_height),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  textStyle: labelStyle,
                ),
              ),
            ),
            AppSpacing.gapMd,
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isExporting ? null : onExportExcelTap,
                icon: const Icon(Icons.table_chart_rounded, size: 20),
                label: const Text('Export Excel'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(_height),
                  backgroundColor: AppColors.surface,
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.borderStrong),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  textStyle: labelStyle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
