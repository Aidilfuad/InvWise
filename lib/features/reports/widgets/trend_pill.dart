import 'package:flutter/material.dart';

import '../../../app/constants/app_spacing.dart';
import '../data/reports_mock_data.dart';

/// Small colored pill: direction arrow + short label (e.g. "▲ 4.2% vs Jun").
/// The color reflects whether the change is good or bad, not its direction.
class TrendPill extends StatelessWidget {
  const TrendPill({super.key, required this.delta});

  final TrendDelta delta;

  @override
  Widget build(BuildContext context) {
    final foreground = delta.tone.foreground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: delta.tone.background,
        borderRadius: AppSpacing.borderRadiusFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(delta.direction.icon, size: 12, color: foreground),
          const SizedBox(width: 3),
          Text(
            delta.label,
            maxLines: 1,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: foreground,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
