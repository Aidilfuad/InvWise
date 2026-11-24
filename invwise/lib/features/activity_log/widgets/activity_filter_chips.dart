import 'package:flutter/material.dart';

import '../../../app/constants/app_spacing.dart';
import '../data/activity_log_options.dart';

class ActivityFilterChips extends StatelessWidget {
  const ActivityFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ActivityFilter selected;
  final ValueChanged<ActivityFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ActivityFilter>(
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Filter activity',
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(),
      ),
      items: ActivityFilter.values
          .map(
            (filter) => DropdownMenuItem<ActivityFilter>(
              value: filter,
              child: Text(filter.label),
            ),
          )
          .toList(growable: false),
      onChanged: (filter) {
        if (filter != null) onSelected(filter);
      },
    );
  }
}
