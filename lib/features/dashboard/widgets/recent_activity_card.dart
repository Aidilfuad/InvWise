import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/stock_movement_service.dart';

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    required this.dateLabel,
    required this.entries,
  });

  final String dateLabel;
  final List<StockMovement> entries;

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
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) ...[
            const SizedBox(height: 14),
            Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 14),
          ],
          _ActivityRow(entry: entries[i]),
        ],
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final StockMovement entry;

  @override
  Widget build(BuildContext context) {
    final (label, icon, color, change) = switch (entry.type) {
      StockMovementType.receipt => (
        'Receipt',
        Icons.south_west,
        AppColors.success,
        '+${_quantity(entry.quantity)} units',
      ),
      StockMovementType.issue => (
        'Issue',
        Icons.north_east,
        AppColors.danger,
        '−${_quantity(entry.quantity)} units',
      ),
      StockMovementType.transfer => (
        'Transfer',
        Icons.swap_horiz_rounded,
        AppColors.primary,
        '${_quantity(entry.quantity)} units',
      ),
      StockMovementType.returnItem => (
        'Return',
        Icons.assignment_return_outlined,
        AppColors.success,
        '+${_quantity(entry.quantity)} units',
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
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.itemName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${entry.sku} · ${entry.description}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: color,
                ),
              ),
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

  String _quantity(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  String _time(DateTime dateTime) {
    final date = dateTime.toLocal();
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')} '
        '${date.hour < 12 ? 'AM' : 'PM'}';
  }
}
