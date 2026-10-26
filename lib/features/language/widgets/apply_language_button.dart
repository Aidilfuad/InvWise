import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';

class ApplyLanguageButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const ApplyLanguageButton({super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      child: const Text(
        'Apply Language',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }
}