import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/support_center_mock_data.dart';
import 'widgets/quick_help_card.dart';
import 'widgets/support_about_card.dart';
import 'widgets/support_contact_card.dart';
import 'widgets/support_header.dart';
import 'widgets/support_search_bar.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  void _onBack() {
    Navigator.pop(context);
  }

  void _onSearchChanged(String value) {
    // TODO: Search support articles.
  }

  void _onQuickHelpTap(QuickHelpItem item) {
    // TODO: Open the selected help topic.
  }

  void _onEmailSupportTap() {
    // TODO: Email IT support.
  }

  void _onCallSupportTap() {
    // TODO: Call support.
  }

  void _onContactItSupportTap() {
    // TODO: Contact IT support.
  }

  @override
  Widget build(BuildContext context) {
    final items = SupportCenterMockData.quickHelp;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            SupportHeader(onBack: _onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SupportSearchBar(onChanged: _onSearchChanged),
                    SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      title: 'Quick Help',
                      trailing: 'Browse by topic',
                    ),
                    SizedBox(height: AppSpacing.md),
                    _quickHelpRow(items[0], items[1]),
                    SizedBox(height: AppSpacing.md),
                    _quickHelpRow(items[2], items[3]),
                    SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      title: 'Contact Support',
                      trailing: "We're here to help",
                    ),
                    SizedBox(height: AppSpacing.md),
                    SupportContactCard(
                      icon: Icons.mail_outline,
                      title: 'IT Support',
                      subtitle: SupportCenterMockData.itSupportEmail,
                      buttonLabel: 'Email Support',
                      onPressed: _onEmailSupportTap,
                    ),
                    SizedBox(height: AppSpacing.md),
                    SupportContactCard(
                      icon: Icons.phone_outlined,
                      title: 'Call Support',
                      subtitle: SupportCenterMockData.callSupportPhone,
                      buttonLabel: 'Call Support',
                      onPressed: _onCallSupportTap,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _SectionHeader(title: 'About'),
                    SizedBox(height: AppSpacing.md),
                    SupportAboutCard(
                      version: SupportCenterMockData.appVersion,
                      organization: SupportCenterMockData.organization,
                    ),
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
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _onContactItSupportTap,
                  icon: Icon(Icons.headset_mic_outlined, color: Colors.white),
                  label: Text(
                    'Contact IT Support',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
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

  Widget _quickHelpRow(QuickHelpItem left, QuickHelpItem right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuickHelpCard(
              item: left,
              onTap: () => _onQuickHelpTap(left),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: QuickHelpCard(
              item: right,
              onTap: () => _onQuickHelpTap(right),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Text(
          title,
          style: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Spacer(),
        if (trailing != null)
          Text(
            trailing!,
            style: textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
      ],
    );
  }
}