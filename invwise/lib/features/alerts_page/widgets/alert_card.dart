import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/alerts_mock_data.dart';

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.entry,
    this.onActionTap,
  });

  final AlertEntry entry;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Row(
            crossAxisAlignment: entry.subtitle.isEmpty
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: entry.iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(entry.icon, size: 20, color: entry.iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (entry.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        entry.subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: entry.subtitleIsCritical
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (entry.sku != null || entry.location != null) ...[
            const SizedBox(height: 16),
            if (entry.sku != null)
              Text(
                'SKU: ${entry.sku}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            if (entry.sku != null && entry.location != null)
              const SizedBox(height: 6),
            if (entry.location != null)
              Text(
                'Location: ${entry.location}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
          if (entry.expected != null && entry.actual != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _ValueBox(label: 'Expected: ${entry.expected}'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ValueBox(label: 'Actual: ${entry.actual}'),
                ),
              ],
            ),
          ],
          if (entry.dueLabel != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      entry.dueLabel!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (entry.actionLabel != null) ...[
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 1, color: AppColors.border),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: onActionTap,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  backgroundColor: entry.primaryButton
                      ? AppColors.primary
                      : AppColors.primaryContainer,
                  foregroundColor: entry.primaryButton
                      ? AppColors.textOnPrimary
                      : AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.actionLabel!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ValueBox extends StatelessWidget {
  const _ValueBox({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}