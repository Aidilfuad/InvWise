import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/report_export_service.dart';
import '../../services/reports_service.dart';
import 'widgets/export_report_actions.dart';
import 'widgets/report_card.dart';
import 'widgets/report_section_header.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  static const double _maxContentWidth = 900;

  final ReportsService _reportsService = ReportsService();
  final ReportExportService _exportService = const ReportExportService();

  ReportType _selectedReport = ReportType.inventorySummary;
  ReportsData? _data;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _reportsService.loadReports();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } on ReportsServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load reports. Please try again. ($error)';
        _isLoading = false;
      });
    }
  }

  Future<void> _export({required bool excel}) async {
    final data = _data;
    if (data == null || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      final report = data[_selectedReport];
      final extension = excel ? 'xlsx' : 'csv';
      final fileName =
          'invwise_${_selectedReport.name}_${_dateStamp(data.generatedAt)}.'
          '$extension';
      final bytes = excel
          ? _exportService.toExcel(report)
          : _exportService.toCsv(report);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        final savedPath = await _exportService.saveFile(
          bytes: bytes,
          fileName: fileName,
        );
        if (mounted) {
          _showMessage('Report saved to $savedPath');
        }
      } else {
        try {
          await SharePlus.instance.share(
            ShareParams(
              title: report.title,
              subject: report.title,
              files: [
                XFile.fromData(
                  Uint8List.fromList(bytes),
                  mimeType: excel
                      ? 'application/vnd.openxmlformats-officedocument.'
                            'spreadsheetml.sheet'
                      : 'text/csv',
                  name: fileName,
                ),
              ],
              fileNameOverrides: [fileName],
            ),
          );
        } on MissingPluginException {
          if (kIsWeb) rethrow;
          final path = await _exportService.saveInDocuments(
            bytes: bytes,
            fileName: fileName,
          );
          if (mounted) _showMessage('Report saved to $path');
        }
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to export report. $error');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _dateStamp(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final data = _data;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Reports',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: _isLoading ? null : _loadReports,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
              ? _buildErrorState()
              : RefreshIndicator(
                  onRefresh: _loadReports,
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.xxl + bottomInset,
                    ),
                    children: [
                      Text(
                        'Live data · Updated ${_formatGeneratedAt(data!.generatedAt)}',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: AppColors.textSecondary),
                      ),
                      AppSpacing.gapMd,
                      DropdownButtonFormField<ReportType>(
                        initialValue: _selectedReport,
                        decoration: const InputDecoration(
                          labelText: 'Report',
                          border: OutlineInputBorder(),
                        ),
                        items: ReportType.values
                            .map(
                              (report) => DropdownMenuItem(
                                value: report,
                                child: Text(report.title),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (report) {
                          if (report != null) {
                            setState(() => _selectedReport = report);
                          }
                        },
                      ),
                      AppSpacing.gapMd,
                      _buildMetrics(data[_selectedReport]),
                      AppSpacing.gapMd,
                      _buildReportTable(data[_selectedReport]),
                      AppSpacing.gapMd,
                      ExportReportActions(
                        isExporting: _isExporting,
                        onExportCsvTap: () => _export(excel: false),
                        onExportExcelTap: () => _export(excel: true),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildMetrics(ReportTable report) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReportSectionHeader(title: 'Summary', subtitle: report.title),
      AppSpacing.gapSm,
      LayoutBuilder(
        builder: (context, constraints) {
          const gap = AppSpacing.sm;
          final cardWidth = (constraints.maxWidth - gap) / 2;
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final metric in report.metrics)
                SizedBox(
                  width: cardWidth,
                  child: ReportCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          metric.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Widget _buildReportTable(ReportTable report) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ReportSectionHeader(
        title: 'Report data',
        subtitle: '${report.rows.length} records',
      ),
      AppSpacing.gapSm,
      ReportCard(
        padding: EdgeInsets.zero,
        child: report.rows.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('No records found for this report.'),
              )
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: report.headers
                      .map((header) => DataColumn(label: Text(header)))
                      .toList(growable: false),
                  rows: report.rows
                      .map(
                        (row) => DataRow(
                          cells: row
                              .map((value) => DataCell(Text(value)))
                              .toList(growable: false),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
      ),
    ],
  );

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: _loadReports, child: const Text('Retry')),
        ],
      ),
    ),
  );

  String _formatGeneratedAt(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year} ${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';
}
