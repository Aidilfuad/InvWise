import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/security_mock_data.dart';
import 'widgets/account_protection_card.dart';
import 'widgets/biometric_card.dart';
import 'widgets/current_device_card.dart';
import 'widgets/login_activity_card.dart';
import 'widgets/password_card.dart';
import 'widgets/security_header.dart';

class SecurityPage extends StatelessWidget {
  const SecurityPage({super.key});

  void _onChangePasswordTap() {
    // TODO: Change password (requires authentication).
  }

  void _onViewActiveSessionsTap() {
    // TODO: View active sessions (requires backend).
  }

  void _onRecentLoginHistoryTap() {
    // TODO: Recent login history (requires backend).
  }

  void _onReviewSecuritySettingsTap() {
    // TODO: Review security settings.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const SecurityHeader(),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(AppSpacing.lg),
              children: [
                PasswordCard(
                  lastUpdated: SecurityMockData.passwordLastUpdated,
                  onChangePassword: _onChangePasswordTap,
                ),
                const SizedBox(height: 12),
                const BiometricCard(
                  initialValue: SecurityMockData.biometricEnabled,
                ),
                const SizedBox(height: 12),
                CurrentDeviceCard(
                  deviceName: SecurityMockData.currentDeviceName,
                  lastActive: SecurityMockData.currentDeviceLastActive,
                  onViewSessions: _onViewActiveSessionsTap,
                ),
                const SizedBox(height: 12),
                LoginActivityCard(
                  date: SecurityMockData.lastLoginDate,
                  time: SecurityMockData.lastLoginTime,
                  onRecentHistory: _onRecentLoginHistoryTap,
                ),
                const SizedBox(height: 12),
                const AccountProtectionCard(
                  status: SecurityMockData.protectionStatus,
                  score: SecurityMockData.securityScore,
                ),
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
              child: ElevatedButton.icon(
                onPressed: _onReviewSecuritySettingsTap,
                icon: const Icon(Icons.shield_outlined, size: 18),
                label: const Text(
                  'Review Security Settings',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 54),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}