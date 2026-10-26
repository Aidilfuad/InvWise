import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'widgets/company_sso_card.dart';
import 'widgets/contact_it_sheet.dart';
import 'widgets/login_brand_header.dart';
import 'widgets/login_field.dart';
import 'widgets/login_options_row.dart';

/// Login screen. UI only: no authentication or backend logic yet.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isSigningIn = false;

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onSignIn() async {
    if (_isSigningIn) return;

    setState(() => _isSigningIn = true);

    try {
      debugPrint('[LOGIN-DEBUG] Calling AuthService.signInWithEmail');
      final user = await AuthService().signInWithEmail(
        email: _employeeIdController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint(
        '[LOGIN-DEBUG] AuthService returned: '
        'userIsNull=${user == null} userId=${user?.id}',
      );

      if (!mounted) {
        debugPrint('[LOGIN-DEBUG] LoginPage unmounted after AuthService returned');
        return;
      }

      debugPrint('[LOGIN-DEBUG] Checking user == null: ${user == null}');
      if (user == null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Unable to sign in. Please try again.'),
            ),
          );
        return;
      }

      debugPrint(
        '[LOGIN-DEBUG] Calling Navigator.pushReplacementNamed: '
        'route=${AppRoutes.dashboard}',
      );
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      debugPrint('[LOGIN-DEBUG] Navigator.pushReplacementNamed returned');
    } on AuthServiceException catch (e, st) {
      debugPrint(
        '[LOGIN-DEBUG] AuthServiceException caught: '
        'type=${e.runtimeType} message="${e.message}"',
      );
      debugPrint('[LOGIN-DEBUG] AuthServiceException stack trace:\n$st');
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e, st) {
      debugPrint(
        '[LOGIN-DEBUG] Unexpected exception caught: '
        'type=${e.runtimeType} error=$e',
      );
      debugPrint('[LOGIN-DEBUG] Exception stack trace:\n$st');
      rethrow;
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _onForgotPassword() {
    // TODO: Forgot password flow.
  }

  void _onCompanySso() {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Company SSO will be available after backend integration.',
          ),
        ),
      );
  }

  void _onContactIt() {
    ContactItSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: 480,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.xl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const LoginBrandHeader(),
                            const SizedBox(height: 28),
                            _buildLoginCard(),
                            const SizedBox(height: 24),
                            Center(
                              child: Text(
                                'OR CONTINUE WITH',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.4,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            CompanySsoCard(onTap: _onCompanySso),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xxl),
                          child: _buildSupportFooter(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Welcome Back',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Sign in to access your inventory dashboard',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          LoginField(
            label: 'Employee ID',
            hint: 'Enter Employee ID',
            controller: _employeeIdController,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),
          LoginField(
            label: 'Password',
            hint: 'Enter Password',
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onSignIn(),
            trailing: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 16),
          LoginOptionsRow(
            rememberMe: _rememberMe,
            onRememberChanged: (value) => setState(() => _rememberMe = value),
            onForgotPassword: _onForgotPassword,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _isSigningIn ? null : _onSignIn,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: _isSigningIn
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.textOnPrimary,
                    ),
                  )
                : const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportFooter() {
    return Column(
      children: [
        Text(
          'Need technical support?',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        InkWell(
          onTap: _onContactIt,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              'Contact IT',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
