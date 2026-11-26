import 'package:flutter/material.dart';

import '../../../app/constants/app_spacing.dart';
import '../../../widgets/searchable_dropdown_form_field.dart';
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
    return SearchableDropdownFormField(
      initialValue: selected.name,
      decoration: const InputDecoration(
        labelText: 'Filter activity',
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(),
      ),
      options: ActivityFilter.values.map((filter) => filter.name).toList(),
      optionLabels: {
        for (final filter in ActivityFilter.values)
          filter.name: filter.label,
      },
      onChanged: (value) {
        if (value == null) return;
        onSelected(
          ActivityFilter.values.firstWhere((filter) => filter.name == value),
        );
      },
    );
  }
}
