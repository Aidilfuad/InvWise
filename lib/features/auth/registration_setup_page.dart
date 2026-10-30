import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/routes/app_routes.dart';
import 'registration_request_validation.dart';

class RegistrationSetupPage extends StatefulWidget {
  const RegistrationSetupPage({super.key});

  @override
  State<RegistrationSetupPage> createState() => _RegistrationSetupPageState();
}

class _RegistrationSetupPageState extends State<RegistrationSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _isSubmitting = false;
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  String? _errorMessage;

  String? get _requestId =>
      Supabase
              .instance
              .client
              .auth
              .currentUser
              ?.userMetadata?['registration_request_id']
          as String?;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final requestId = _requestId;
    if (requestId == null) {
      setState(() {
        _errorMessage = 'This invitation is not linked to a registration.';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final client = Supabase.instance.client;
      final invitedUser = client.auth.currentUser;
      final email = invitedUser?.email;
      if (invitedUser == null || email == null || email.isEmpty) {
        throw Exception('Accept the invitation again to continue setup.');
      }
      await client.auth.updateUser(
        UserAttributes(password: _passwordController.text),
      );
      final passwordSession = await client.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );
      if (passwordSession.user?.id != invitedUser.id) {
        throw Exception('Unable to verify the invited account.');
      }
      final response = await client.functions.invoke(
        'complete-registration-setup',
        body: {'request_id': requestId},
      );
      if (response.status < 200 || response.status >= 300) {
        final message = response.data is Map
            ? (response.data as Map)['error']?.toString()
            : null;
        throw Exception(message ?? 'Unable to complete account setup.');
      }

      await client.auth.signOut();
      if (!mounted) return;
      Navigator.of(context)
          .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Account setup complete. Sign in with your email.'),
          ),
        );
    } on FunctionException catch (error) {
      if (!mounted) return;
      final details = error.details;
      final message = details is Map ? details['error']?.toString() : null;
      setState(() {
        _isSubmitting = false;
        _errorMessage = message ?? 'Unable to complete account setup.';
      });
    } on AuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasInvite = _requestId != null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Your Password'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              shrinkWrap: true,
              children: [
                Text(
                  hasInvite
                      ? 'Complete Account Setup'
                      : 'Invitation Unavailable',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  hasInvite ? 'Choose a password for your InvWise account.' : 'Open this page from the invitation email on this device.',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
                if (hasInvite) ...[
                  const SizedBox(height: AppSpacing.lg),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      final requiredError =
                          RegistrationRequestValidation.required(value);
                      if (requiredError != null) return requiredError;
                      if (value!.length < 8) {
                        return 'Use at least 8 characters.';
                      }
                      return null;
                    },
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _confirmationController,
                    obscureText: _obscureConfirmation,
                    enabled: !_isSubmitting,
                    validator: (value) =>
                        RegistrationRequestValidation.confirmation(
                          password: _passwordController.text,
                          confirmation: value,
                        ),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        onPressed: () => setState(
                          () => _obscureConfirmation = !_obscureConfirmation,
                        ),
                        icon: Icon(
                          _obscureConfirmation
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: AppColors.danger),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Set Password'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
