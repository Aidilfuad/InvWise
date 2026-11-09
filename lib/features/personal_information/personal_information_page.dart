import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/profile_service.dart';
import '../settings/widgets/edit_profile_sheet.dart';
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
  final ProfileService _profileService = ProfileService();
  ProfileLookupResult? _profile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        if (profile == null) {
          _errorMessage = 'Sign in to view your profile.';
        }
      });
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load profile: $error';
        _isLoading = false;
      });
    }
  }

  void _onBack() {
    Navigator.pop(context);
  }

  Future<void> _onEditInformationTap() async {
    final profile = _profile;
    if (profile == null) return;
    final updatedProfile = await EditProfileDialog.show(
      context,
      profile: profile,
      onSave: _profileService.updateCurrentProfile,
      onProfileUpdated: (updated) {
        if (mounted) setState(() => _profile = updated);
      },
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final profile = _profile;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            PersonalInformationHeader(onBack: _onBack),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : profile == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _errorMessage ?? 'Profile not found.',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            TextButton(
                              onPressed: _loadProfile,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          ProfileSummaryCard(
                            profile: profile,
                            onProfileUpdated: (updated) {
                              if (mounted) setState(() => _profile = updated);
                            },
                          ),
                          SizedBox(height: AppSpacing.md),
                          PersonalDetailsCard(profile: profile),
                          SizedBox(height: AppSpacing.md),
                          WorkInformationCard(profile: profile),
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
                  onPressed: profile == null || _isLoading
                      ? null
                      : _onEditInformationTap,
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
