import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/security_history_service.dart';

class LoginActivityCard extends StatelessWidget {
  final LoginEvent? latestLogin;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRecentHistory;

  const LoginActivityCard({
    super.key,
    required this.latestLogin,
    this.isLoading = false,
    this.errorMessage,
    this.onRecentHistory,
  });

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} $hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
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
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(26),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.history, size: 16, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Text(
                'Last Login',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else if (errorMessage != null)
            Text(
              errorMessage!,
              style: TextStyle(fontSize: 12, color: AppColors.danger),
            )
          else
            Text(
              latestLogin == null
                  ? 'No successful login recorded.'
                  : _formatDateTime(latestLogin!.occurredAt),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 12),
          Divider(height: 1, thickness: 1, color: AppColors.border),
          InkWell(
            onTap: onRecentHistory,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent Login History',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 20, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
