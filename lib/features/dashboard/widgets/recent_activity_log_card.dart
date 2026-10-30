import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/activity_log_service.dart';

class RecentActivityLogCard extends StatelessWidget {
  const RecentActivityLogCard({
    super.key,
    required this.dateLabel,
    required this.entries,
  });

  final String dateLabel;
  final List<ActivityLogEntry> entries;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 14),
        if (entries.isEmpty)
          Text(
            'No recent activity.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        for (var index = 0; index < entries.length; index++) ...[
          if (index > 0) ...[
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 14),
          ],
          _ActivityRow(entry: entries[index]),
        ],
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final ActivityLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (entry.type) {
      ActivityEventType.inventoryCreated => (
        Icons.inventory_2_outlined,
        AppColors.success,
      ),
      ActivityEventType.inventoryUpdated => (
        Icons.edit_outlined,
        AppColors.primary,
      ),
      ActivityEventType.inventoryDeleted => (
        Icons.delete_outline,
        AppColors.danger,
      ),
      ActivityEventType.stockAdjustment => (
        Icons.tune_rounded,
        AppColors.warning,
      ),
      ActivityEventType.receipt => (Icons.south_west, AppColors.success),
      ActivityEventType.issue => (Icons.north_east, AppColors.danger),
      ActivityEventType.returnItem => (
        Icons.assignment_return_outlined,
        AppColors.success,
      ),
      ActivityEventType.transfer => (
        Icons.swap_horiz_rounded,
        AppColors.primary,
      ),
    };

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withAlpha(26),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.type.label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (entry.context.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.context,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (entry.quantityLabel.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  entry.quantityLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _time(entry.occurredAt),
          style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  String _time(DateTime dateTime) {
    final date = dateTime.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour < 12 ? 'AM' : 'PM'}';
  }
}
