import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/theme/app_theme_controller.dart';
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
  String _selectedId = AppThemeController.instance.languageCode;
  bool _isSaving = false;

  void _onOptionTap(String id) {
    if (!_isSaving) setState(() => _selectedId = id);
  }

  Future<void> _onApplyTap() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    try {
      await AppThemeController.instance.setLanguageCode(_selectedId);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Language preference updated.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              AppThemeController.instance.errorMessage ??
                  'Unable to save language preference: $error',
            ),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppThemeController.instance,
      builder: (context, child) {
        final currentLanguage =
            _languageLabel(AppThemeController.instance.languageCode);
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
                    CurrentLanguageCard(
                      language: currentLanguage,
                      status: 'Active',
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
                    for (final option in _languageOptions) ...[
                      LanguageOptionCard(
                        label: option.$2,
                        selected: option.$1 == _selectedId,
                        onTap: () => _onOptionTap(option.$1),
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
                  child: ApplyLanguageButton(
                    onPressed: _isSaving ? null : _onApplyTap,
                    isLoading: _isSaving,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const List<(String, String)> _languageOptions = [
    ('en', 'English (en)'),
    ('ms', 'Bahasa Melayu (ms)'),
  ];

  String _languageLabel(String code) {
    return _languageOptions
        .firstWhere((option) => option.$1 == code)
        .$2;
  }
}