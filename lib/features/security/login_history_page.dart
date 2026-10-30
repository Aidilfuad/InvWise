import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/security_history_service.dart';

class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key});

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  final SecurityHistoryService _service = SecurityHistoryService();
  List<LoginEvent> _events = const [];
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final events = await _service.getLoginHistory();
      if (!mounted) return;
      setState(() {
        _events = events;
        _isLoading = false;
      });
    } on SecurityHistoryServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load login history: $error';
        _isLoading = false;
      });
    }
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Recent Login History'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh login history',
            onPressed: _isLoading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: _events.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: const [
                        SizedBox(height: 100),
                        Center(child: Text('No login history found.')),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _events.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => _LoginEventCard(
                        event: _events[index],
                        dateTime: _formatDateTime(_events[index].occurredAt),
                      ),
                    ),
            ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _loadHistory, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _LoginEventCard extends StatelessWidget {
  const _LoginEventCard({required this.event, required this.dateTime});

  final LoginEvent event;
  final String dateTime;

  @override
  Widget build(BuildContext context) {
    final color = event.succeeded ? AppColors.success : AppColors.danger;
    final background = event.succeeded
        ? AppColors.successContainer
        : AppColors.dangerContainer;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateTime,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  event.succeeded ? 'Succeeded' : 'Failed',
                  style: textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (!event.succeeded &&
              event.failureReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'Failure reason', value: event.failureReason!),
          ],
          if (event.ipAddress?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'IP address', value: event.ipAddress!),
          ],
          if (event.userAgent?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            _DetailRow(label: 'Device', value: event.userAgent!),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 2),
      SelectableText(
        value,
        style: Theme.of(context).textTheme.bodyMedium
            ?.copyWith(color: AppColors.textPrimary),
      ),
    ],
  );
}
