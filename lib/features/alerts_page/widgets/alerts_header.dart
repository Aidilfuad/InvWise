import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

class AlertsHeader extends StatelessWidget {
  const AlertsHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              Icons.arrow_back,
              size: 22,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Alerts & Tasks',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}