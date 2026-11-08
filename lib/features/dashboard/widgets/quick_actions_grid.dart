import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../data/dashboard_data.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({
    super.key,
    required this.actions,
    required this.onActionTap,
    this.compact = false,
  });

  final List<QuickActionItem> actions;
  final ValueChanged<QuickActionItem> onActionTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < actions.length; i += 2) {
      if (i > 0) rows.add(SizedBox(height: compact ? 6 : 12));
      final hasSecond = i + 1 < actions.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _QuickActionTile(
                  item: actions[i],
                  compact: compact,
                  onTap: () => onActionTap(actions[i]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: hasSecond
                    ? _QuickActionTile(
                        item: actions[i + 1],
                        compact: compact,
                        onTap: () => onActionTap(actions[i + 1]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.item,
    required this.onTap,
    required this.compact,
  });

  final QuickActionItem item;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final highlighted = item.type == QuickActionType.addItem;
    final titleColor = highlighted
        ? AppColors.textOnPrimary
        : AppColors.textPrimary;
    final subtitleColor = highlighted
        ? AppColors.textOnPrimary.withAlpha(210)
        : AppColors.textSecondary;
    final iconColor = highlighted ? AppColors.textOnPrimary : AppColors.primary;

    return Material(
      color: highlighted ? AppColors.primary : AppColors.primaryContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(compact ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(item.icon, size: compact ? 18 : 22, color: iconColor),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    size: 16,
                    color: highlighted
                        ? AppColors.textOnPrimary
                        : AppColors.textSecondary,
                  ),
                ],
              ),
              SizedBox(height: compact ? 6 : 18),
              Text(
                item.label,
                style: TextStyle(
                  fontSize: compact ? 12 : 14,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              if (!compact) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: TextStyle(fontSize: 11, color: subtitleColor),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
