import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/language_mock_data.dart';
import 'widgets/apply_language_button.dart';
import 'widgets/current_language_card.dart';
import 'widgets/language_header.dart';
import 'widgets/language_option_card.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  String _selectedId = LanguageMockData.currentLanguageId;

  void _onOptionTap(String id) {
    setState(() => _selectedId = id);
  }

  void _onApplyTap() {
    // TODO: Apply language (no localization implemented yet).
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const LanguageHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              children: [
                const CurrentLanguageCard(
                  language: LanguageMockData.currentLanguageLabel,
                  status: LanguageMockData.currentLanguageStatus,
                ),
                const SizedBox(height: 28),
                Text(
                  'Available Languages',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                for (final option in LanguageMockData.options) ...[
                  LanguageOptionCard(
                    label: option.label,
                    selected: option.id == _selectedId,
                    onTap: () => _onOptionTap(option.id),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: ApplyLanguageButton(onPressed: _onApplyTap),
            ),
          ),
        ],
      ),
    );
  }
}