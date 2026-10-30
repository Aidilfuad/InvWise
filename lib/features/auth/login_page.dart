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

/// Login screen with Supabase email/password authentication.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

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
      final user = await _authService.signInWithEmail(
        email: _employeeIdController.text.trim(),
        password: _passwordController.text,
      );
      debugPrint(
        '[LOGIN-DEBUG] AuthService returned: '
        'userIsNull=${user == null} userId=${user?.id}',
      );

      if (!mounted) {
        debugPrint(
          '[LOGIN-DEBUG] LoginPage unmounted after AuthService returned',
        );
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
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pushReplacementNamed(AppRoutes.dashboard);
      final trackingWarning = _authService.lastTrackingWarning;
      if (trackingWarning != null) {
        messenger.showSnackBar(SnackBar(content: Text(trackingWarning)));
      }
      debugPrint('[LOGIN-DEBUG] Navigator.pushReplacementNamed returned');
    } on AuthServiceException catch (e, st) {
      debugPrint(
        '[LOGIN-DEBUG] AuthServiceException caught: '
        'type=${e.runtimeType} message="${e.message}"',
      );
      debugPrint('[LOGIN-DEBUG] AuthServiceException stack trace:\n$st');
      if (!mounted) return;

      final trackingWarning = _authService.lastTrackingWarning;
      final message = trackingWarning == null
          ? e.message
          : '${e.message} $trackingWarning';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
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

  Future<void> _onForgotPassword() async {
    final controller = TextEditingController(
      text: _employeeIdController.text.contains('@')
          ? _employeeIdController.text.trim()
          : '',
    );
    final formKey = GlobalKey<FormState>();
    var isSending = false;
    String? errorMessage;
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reset Password'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Enter your account email to receive a reset link.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  enabled: !isSending,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    if (email.isEmpty ||
                        !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email)) {
                      return 'Enter a valid email address.';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSending
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSending
                  ? null
                  : () async {
                      if (!(formKey.currentState?.validate() ?? false)) return;
                      setDialogState(() {
                        isSending = true;
                        errorMessage = null;
                      });
                      try {
                        await AuthService().resetPasswordForEmail(
                          controller.text,
                        );
                        if (dialogContext.mounted) {
                          Navigator.of(dialogContext)
                              .pop(controller.text.trim());
                        }
                      } on AuthServiceException catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSending = false;
                            errorMessage = error.message;
                          });
                        }
                      } catch (_) {
                        if (dialogContext.mounted) {
                          setDialogState(() {
                            isSending = false;
                            errorMessage =
                                'Network error. Check your connection and '
                                'try again.';
                          });
                        }
                      }
                    },
              child: isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send Reset Link'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();

    if (email != null && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'If an account exists for that email, a password reset link '
              'has been sent.',
            ),
          ),
        );
    }
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
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
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
