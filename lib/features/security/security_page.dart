import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/auth_service.dart';
import '../../services/security_history_service.dart';
import 'active_sessions_page.dart';
import 'data/security_mock_data.dart';
import 'login_history_page.dart';
import 'widgets/account_protection_card.dart';
import 'widgets/biometric_card.dart';
import 'widgets/current_device_card.dart';
import 'widgets/login_activity_card.dart';
import 'widgets/password_card.dart';
import 'widgets/security_header.dart';

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final SecurityHistoryService _historyService = SecurityHistoryService();
  LoginEvent? _latestLogin;
  List<DeviceSession> _activeSessions = const [];
  String? _loginError;
  String? _sessionsError;
  bool _isLoadingLogin = true;
  bool _isLoadingSessions = true;

  @override
  void initState() {
    super.initState();
    _loadLatestLogin();
    _loadActiveSessions();
  }

  Future<void> _loadLatestLogin() async {
    try {
      final login = await _historyService.getLatestSuccessfulLogin();
      if (!mounted) return;
      setState(() {
        _latestLogin = login;
        _loginError = null;
        _isLoadingLogin = false;
      });
    } on SecurityHistoryServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _loginError = error.message;
        _isLoadingLogin = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loginError = 'Unable to load the last login: $error';
        _isLoadingLogin = false;
      });
    }
  }

  Future<void> _loadActiveSessions() async {
    try {
      final sessions = await _historyService.getActiveSessions();
      if (!mounted) return;
      setState(() {
        _activeSessions = sessions;
        _sessionsError = null;
        _isLoadingSessions = false;
      });
    } on SecurityHistoryServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionsError = error.message;
        _isLoadingSessions = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sessionsError = 'Unable to load active sessions: $error';
        _isLoadingSessions = false;
      });
    }
  }

  Future<void> _onChangePassword({
    required String currentPassword,
    required String newPassword,
  }) => AuthService().changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
  );

  void _onViewActiveSessionsTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const ActiveSessionsPage()));
  }

  void _onRecentLoginHistoryTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const LoginHistoryPage()));
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
                PasswordCard(onChangePassword: _onChangePassword),
                const SizedBox(height: 12),
                const BiometricCard(
                  initialValue: SecurityMockData.biometricEnabled,
                ),
                const SizedBox(height: 12),
                CurrentDeviceCard(
                  sessions: _activeSessions,
                  isLoading: _isLoadingSessions,
                  errorMessage: _sessionsError,
                  onViewSessions: _onViewActiveSessionsTap,
                ),
                const SizedBox(height: 12),
                LoginActivityCard(
                  latestLogin: _latestLogin,
                  isLoading: _isLoadingLogin,
                  errorMessage: _loginError,
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
