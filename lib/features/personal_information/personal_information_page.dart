import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../settings/data/settings_mock_data.dart';
import '../settings/widgets/edit_profile_sheet.dart';
import 'data/personal_information_mock_data.dart';
import 'widgets/account_information_card.dart';
import 'widgets/personal_details_card.dart';
import 'widgets/personal_information_header.dart';
import 'widgets/profile_summary_card.dart';
import 'widgets/work_information_card.dart';

class PersonalInformationPage extends StatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  State<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState extends State<PersonalInformationPage> {
  void _onBack() {
    Navigator.pop(context);
  }

  void _onEditInformationTap() {
    final data = PersonalInformationMockData.profile;

    EditProfileSheet.show(
      context,
      SettingsProfile(
        name: data.fullName,
        role: data.role,
        accessLabel: data.accessLevel,
        initials: data.initials,
        employeeId: data.employeeId,
        email: data.email,
        phone: data.phone,
        department: data.department,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = PersonalInformationMockData.profile;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PersonalInformationHeader(onBack: _onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    ProfileSummaryCard(data: data),
                    SizedBox(height: AppSpacing.md),
                    PersonalDetailsCard(data: data),
                    SizedBox(height: AppSpacing.md),
                    WorkInformationCard(data: data),
                    SizedBox(height: AppSpacing.md),
                    AccountInformationCard(data: data),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              color: AppColors.background,
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _onEditInformationTap,
                  label: Text(
                    'Edit Information',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}