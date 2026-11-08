import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/dashboard_data.dart';

class AttentionRequiredCard extends StatelessWidget {
  const AttentionRequiredCard({
    super.key,
    required this.items,
    this.compact = false,
  });

  final List<AttentionItem> items;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Divider(height: 1, thickness: 1, color: AppColors.border),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 16,
                vertical: compact ? 7 : 14,
              ),
              child: Row(
                children: [
                  Container(
                    width: compact ? 28 : 40,
                    height: compact ? 28 : 40,
                    decoration: BoxDecoration(
                      color: items[i].background,
                      borderRadius: BorderRadius.circular(compact ? 8 : 12),
                    ),
                    child: Icon(
                      items[i].icon,
                      size: compact ? 16 : 20,
                      color: items[i].color,
                    ),
                  ),
                  SizedBox(width: compact ? 8 : 12),
                  Expanded(
                    child: compact
                        ? Text(
                            items[i].title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                items[i].title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[i].subtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    items[i].count,
                    style: TextStyle(
                      fontSize: compact ? 17 : 22,
                      fontWeight: FontWeight.w800,
                      color: items[i].color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
