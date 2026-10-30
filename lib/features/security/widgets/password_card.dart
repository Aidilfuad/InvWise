import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';
import '../../../services/auth_service.dart';

typedef ChangePasswordCallback = Future<void> Function({
  required String currentPassword,
  required String newPassword,
});

class PasswordCard extends StatefulWidget {
  const PasswordCard({super.key, required this.onChangePassword});

  final ChangePasswordCallback onChangePassword;

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isSaving = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.isEmpty) return 'This field is required.';
    return null;
  }

  String? _validateNewPassword(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (value!.length < 8) return 'Use at least 8 characters.';
    return null;
  }

  String? _validateConfirmation(String? value) {
    final requiredError = _required(value);
    if (requiredError != null) return requiredError;
    if (value != _newPasswordController.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSaving = true);
    try {
      await widget.onChangePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );
      if (!mounted) return;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      _formKey.currentState?.reset();
      _showMessage('Password changed successfully.');
    } on AuthServiceException catch (error) {
      if (mounted) _showMessage(error.message, isError: true);
    } catch (error) {
      if (mounted) {
        _showMessage('Unable to change password. $error', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
        ),
      );
  }

  Widget _passwordField({
    required String label,
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        enabled: !_isSaving,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: IconButton(
            tooltip: obscureText ? 'Show $label' : 'Hide $label',
            onPressed: onToggleVisibility,
            icon: Icon(
              obscureText
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock_outline,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Change Password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _passwordField(
              label: 'Current Password',
              controller: _currentPasswordController,
              obscureText: _obscureCurrentPassword,
              onToggleVisibility: () => setState(
                () => _obscureCurrentPassword = !_obscureCurrentPassword,
              ),
              validator: _required,
            ),
            _passwordField(
              label: 'New Password',
              controller: _newPasswordController,
              obscureText: _obscureNewPassword,
              onToggleVisibility: () =>
                  setState(() => _obscureNewPassword = !_obscureNewPassword),
              validator: _validateNewPassword,
            ),
            _passwordField(
              label: 'Confirm New Password',
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              onToggleVisibility: () => setState(
                () => _obscureConfirmPassword = !_obscureConfirmPassword,
              ),
              validator: _validateConfirmation,
            ),
            OutlinedButton(
              onPressed: _isSaving ? null : _submit,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
                side: BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
