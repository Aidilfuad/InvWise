import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/alerts_mock_data.dart';

class AlertsFilterBar extends StatelessWidget {
  const AlertsFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final AlertFilter selected;
  final ValueChanged<AlertFilter> onChanged;

  static const List<(AlertFilter, String)> _tabs = [
    (AlertFilter.all, 'All'),
    (AlertFilter.urgent, 'Urgent'),
    (AlertFilter.warnings, 'Warnings'),
    (AlertFilter.tasks, 'Tasks'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final tab in _tabs)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(tab.$1),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tab.$1 == selected
                        ? AppColors.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tab.$2,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tab.$1 == selected
                          ? AppColors.textOnPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 