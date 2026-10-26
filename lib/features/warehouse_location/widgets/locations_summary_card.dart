import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../data/warehouse_locations_mock_data.dart';

class LocationsSummaryCard extends StatelessWidget {
  final WarehouseLocationsSummary summary;

  const LocationsSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(
      fontSize: 11,
      color: AppColors.textSecondary,
    );
    final valueStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
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
              Icon(Icons.warehouse_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                'Active Locations: ',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${summary.activeLocations}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(
                TextSpan(
                  text: 'Total Capacity: ',
                  style: labelStyle,
                  children: [
                    TextSpan(
                      text: '${summary.totalCapacity} Items',
                      style: valueStyle,
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  text: 'Utilization: ',
                  style: labelStyle,
                  children: [
                    TextSpan(
                      text: '${summary.utilizationPercent}%',
                      style: valueStyle.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: summary.utilizationPercent / 100,
              minHeight: 6,
              backgroundColor: AppColors.primary.withAlpha(26),
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}