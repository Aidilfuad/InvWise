import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/support_articles.dart';
import 'widgets/contact_support_sheet.dart';
import 'widgets/quick_help_card.dart';
import 'widgets/support_contact_card.dart';
import 'widgets/support_header.dart';
import 'widgets/support_search_bar.dart';

class SupportCenterPage extends StatefulWidget {
  const SupportCenterPage({super.key});

  @override
  State<SupportCenterPage> createState() => _SupportCenterPageState();
}

class _SupportCenterPageState extends State<SupportCenterPage> {
  static const String _supportEmail = 'support@invwise.com';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.pop(context);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value.trim().toLowerCase());
  }

  void _onQuickHelpTap(SupportArticle article) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(article.title),
        content: SingleChildScrollView(child: Text(article.content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _onEmailSupportTap() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': 'InvWise Support Request'},
    );
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
          mounted) {
        _showMessage('No email app is available on this device.');
      }
    } catch (error) {
      if (mounted) _showMessage('Unable to open email: $error');
    }
  }

  Future<void> _onContactItSupportTap() async {
    final submitted = await ContactSupportSheet.show(context);
    if (submitted && mounted) {
      _showMessage('Your support request has been submitted.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  List<SupportArticle> get _filteredArticles {
    if (_searchQuery.isEmpty) return SupportArticles.all;
    return SupportArticles.all.where((article) {
      final searchable = [
        article.title,
        article.description,
        article.content,
        ...article.keywords,
      ].join(' ').toLowerCase();
      return searchable.contains(_searchQuery);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final articles = _filteredArticles;

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
                    SupportSearchBar(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                    SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      title: 'Help Topics',
                      trailing: _searchQuery.isEmpty
                          ? 'Browse by topic'
                          : '${articles.length} result${articles.length == 1 ? '' : 's'}',
                    ),
                    SizedBox(height: AppSpacing.md),
                    if (articles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xl,
                        ),
                        child: Center(
                          child: Text(
                            'No help topics match your search.',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                      )
                    else
                      for (var index = 0; index < articles.length; index += 2)
                        Padding(
                          padding: EdgeInsets.only(
                            bottom: index + 2 < articles.length
                                ? AppSpacing.md
                                : 0,
                          ),
                          child: _quickHelpRow(
                            articles[index],
                            index + 1 < articles.length
                                ? articles[index + 1]
                                : null,
                          ),
                        ),
                    SizedBox(height: AppSpacing.lg),
                    _SectionHeader(
                      title: 'Contact Support',
                      trailing: "We're here to help",
                    ),
                    SizedBox(height: AppSpacing.md),
                    SupportContactCard(
                      icon: Icons.mail_outline,
                      title: 'IT Support',
                      subtitle: _supportEmail,
                      buttonLabel: 'Email Support',
                      onPressed: _onEmailSupportTap,
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

  Widget _quickHelpRow(SupportArticle left, SupportArticle? right) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: QuickHelpCard(
              article: left,
              onTap: () => _onQuickHelpTap(left),
            ),
          ),
          if (right != null) ...[
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: QuickHelpCard(
                article: right,
                onTap: () => _onQuickHelpTap(right),
              ),
            ),
          ] else
            const Spacer(),
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