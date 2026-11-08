import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../services/system_activity_log_service.dart';

class ActivityLogsPage extends StatefulWidget {
  const ActivityLogsPage({super.key, this.service});

  final SystemActivityLogService? service;

  @override
  State<ActivityLogsPage> createState() => _ActivityLogsPageState();
}

class _ActivityLogsPageState extends State<ActivityLogsPage> {
  late final SystemActivityLogService _service =
      widget.service ?? SystemActivityLogService();
  final _searchController = TextEditingController();
  List<SystemActivityEntry> _entries = const [];
  List<String> _categories = const [];
  bool _isLoading = true;
  String? _errorMessage;
  String _query = '';
  String _category = '';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final entries = await _service.getEntries(
        category: _category.isEmpty ? null : _category,
        from: _dateRange?.start,
        through: _dateRange?.end,
      );
      if (!mounted) return;
      setState(() {
        _entries = entries;
        if (_category.isEmpty && _dateRange == null) {
          _categories = entries.map((entry) => entry.category).toSet().toList()
            ..sort();
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load activity logs: $error';
        _isLoading = false;
      });
    }
  }

  List<SystemActivityEntry> get _filteredEntries {
    final normalizedQuery = _query.trim().toLowerCase();
    return _entries
        .where((entry) {
          final matchesSearch =
              normalizedQuery.isEmpty ||
              [
                entry.actorName,
                entry.category,
                entry.action,
                entry.description,
                entry.entityType,
                entry.entityId ?? '',
                entry.metadata.toString(),
              ].any((value) => value.toLowerCase().contains(normalizedQuery));
          final matchesCategory =
              _category.isEmpty || entry.category == _category;
          final matchesDate =
              _dateRange == null ||
              (!entry.occurredAt.isBefore(_dateRange!.start) &&
                  !entry.occurredAt.isAfter(
                    DateTime(
                      _dateRange!.end.year,
                      _dateRange!.end.month,
                      _dateRange!.end.day,
                      23,
                      59,
                      59,
                      999,
                    ),
                  ));
          return matchesSearch && matchesCategory && matchesDate;
        })
        .toList(growable: false);
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1),
      initialDateRange: _dateRange,
    );
    if (selected != null && mounted) {
      setState(() => _dateRange = selected);
      await _load();
    }
  }

  Widget _filterPanel() => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search usernames, actions, or descriptions',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('All categories'),
                  ),
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  setState(() => _category = value ?? '');
                  _load();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDateRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  _dateRange == null
                      ? 'Date Range'
                      : '${_dateRange!.start.month}/${_dateRange!.start.day}'
                            ' – ${_dateRange!.end.month}/${_dateRange!.end.day}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        if (_dateRange != null || _category.isNotEmpty || _query.isNotEmpty)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _query = '';
                  _category = '';
                  _dateRange = null;
                });
                _load();
              },
              child: const Text('Clear filters'),
            ),
          ),
      ],
    ),
  );

  Widget _entryList(List<SystemActivityEntry> filtered) => _isLoading
      ? const Center(child: CircularProgressIndicator())
      : _errorMessage != null
      ? _ErrorState(message: _errorMessage!, onRetry: _load)
      : RefreshIndicator(
          onRefresh: _load,
          child: filtered.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 100),
                    Center(child: Text('No activity logs found.')),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _ActivityLogTile(entry: filtered[index]),
                ),
        );

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEntries;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _isLoading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 1200) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 310,
                  child: SingleChildScrollView(child: _filterPanel()),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _entryList(filtered)),
              ],
            );
          }
          if (constraints.maxWidth >= 600) {
            return Column(
              children: [
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: ExpansionTile(
                    title: const Text('Filters'),
                    initiallyExpanded: false,
                    children: [_filterPanel()],
                  ),
                ),
                Expanded(child: _entryList(filtered)),
              ],
            );
          }
          return Column(
            children: [
              _filterPanel(),
              Expanded(child: _entryList(filtered)),
            ],
          );
        },
      ),
    );
  }
}

class _ActivityLogTile extends StatelessWidget {
  const _ActivityLogTile({required this.entry});

  final SystemActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final time = entry.occurredAt;
    final categoryColor = switch (entry.category.toLowerCase()) {
      'telemetry' => AppColors.warning,
      'user management' || 'registration approvals' => AppColors.primary,
      'inventory' => AppColors.success,
      _ => AppColors.textSecondary,
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '${time.year}-${time.month.toString().padLeft(2, '0')}-'
                '${time.day.toString().padLeft(2, '0')} '
                '${time.hour.toString().padLeft(2, '0')}:'
                '${time.minute.toString().padLeft(2, '0')}',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text('·', style: TextStyle(color: AppColors.textSecondary)),
              Text(
                entry.actorName,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  entry.category,
                  style: TextStyle(
                    color: categoryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            entry.action,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            entry.description,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
