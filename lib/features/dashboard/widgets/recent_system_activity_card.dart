import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/system_activity_log_service.dart';

class RecentSystemActivityCard extends StatelessWidget {
  const RecentSystemActivityCard({
    super.key,
    required this.entries,
    this.compact = false,
  });

  final List<SystemActivityEntry> entries;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 9 : 14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: [
        if (entries.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No recent activity.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) ...[
            SizedBox(height: compact ? 5 : 10),
            Divider(height: 1, color: AppColors.border),
            SizedBox(height: compact ? 5 : 10),
          ],
          _RecentActivityRow(entry: entries[index], compact: compact),
        ],
      ],
    ),
  );
}

class _RecentActivityRow extends StatelessWidget {
  const _RecentActivityRow({required this.entry, required this.compact});

  final SystemActivityEntry entry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final categoryColor = switch (entry.category.toLowerCase()) {
      'telemetry' => AppColors.warning,
      'inventory' => AppColors.success,
      'user management' || 'registration approvals' => AppColors.primary,
      _ => AppColors.textSecondary,
    };
    final date = entry.occurredAt;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.circle, size: 8, color: categoryColor),
        SizedBox(width: compact ? 6 : 10),
        Expanded(
          child: compact
              ? Text(
                  '${entry.action} · ${entry.actorName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.action} · ${entry.actorName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.category} · ${entry.description}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(width: 8),
        Text(
          compact
              ? '${date.hour % 12 == 0 ? 12 : date.hour % 12}:'
                    '${date.minute.toString().padLeft(2, '0')}'
              : '${date.hour.toString().padLeft(2, '0')}:'
                    '${date.minute.toString().padLeft(2, '0')}',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: compact ? 9 : 10,
          ),
        ),
      ],
    );
  }
}
