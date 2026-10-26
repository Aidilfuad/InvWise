import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/activity_log_mock_data.dart';
import 'widgets/activity_filter_chips.dart';
import 'widgets/activity_log_card.dart';
import 'widgets/activity_log_header.dart';
import 'widgets/activity_search_bar.dart';

class ActivityLogPage extends StatefulWidget {
  const ActivityLogPage({super.key});

  @override
  State<ActivityLogPage> createState() => _ActivityLogPageState();
}

class _ActivityLogPageState extends State<ActivityLogPage> {
  ActivityFilter _filter = ActivityFilter.all;

  List<ActivityLogEntry> get _entries {
    final type = _filter.type;
    if (type == null) return ActivityLogMockData.entries;
    return ActivityLogMockData.entries
        .where((e) => e.type == type)
        .toList();
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onFilterTap() {
    // TODO: Open the activity filter options.
  }

  void _onSearchChanged(String value) {
    // TODO: Filter activity by item name or SKU.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final entries = _entries;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            ActivityLogHeader(onBack: _onBack, onFilter: _onFilterTap),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                children: [
                  ActivitySearchBar(onChanged: _onSearchChanged),
                  SizedBox(height: AppSpacing.md),
                  ActivityFilterChips(
                    selected: _filter,
                    onSelected: (f) => setState(() => _filter = f),
                  ),
                  SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                children: [
                  Row(
                    children: [
                      Text(
                        'Recent activity',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Spacer(),
                      Icon(
                        Icons.sort,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Newest first',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.md),
                  for (final entry in entries) ...[
                    ActivityLogCard(entry: entry),
                    SizedBox(height: AppSpacing.md),
                  ],
                  SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Text(
                        'Loading earlier activity...',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}