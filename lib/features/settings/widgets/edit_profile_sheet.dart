import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/profile_service.dart';

typedef ProfileSaveCallback = Future<ProfileLookupResult> Function({
  required String fullName,
  required String phoneNumber,
});

class EditProfileDialog extends StatefulWidget {
  const EditProfileDialog({
    super.key,
    required this.profile,
    required this.onSave,
  });

  final ProfileLookupResult profile;
  final ProfileSaveCallback onSave;

  static Future<ProfileLookupResult?> show(
    BuildContext context, {
    required ProfileLookupResult profile,
    required ProfileSaveCallback onSave,
  }) {
    return showDialog<ProfileLookupResult>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: EditProfileDialog(profile: profile, onSave: onSave),
      ),
    );
  }

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _employeeIdController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameController = TextEditingController(text: p.fullName ?? '');
    _employeeIdController = TextEditingController(text: p.employeeId ?? '');
    _emailController = TextEditingController(text: p.email ?? '');
    _phoneController = TextEditingController(text: p.phoneNumber ?? '');
    _roleController = TextEditingController(text: p.role ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final profile = await widget.onSave(
        fullName: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      if (mounted) Navigator.of(context).pop(profile);
    } on ProfileServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to save profile: $error');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onCancel() {
    Navigator.of(context).pop();
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            style: TextStyle(
              fontSize: 14,
              color: readOnly ? AppColors.textSecondary : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: readOnly
                  ? AppColors.surfaceVariant
                  : AppColors.surface,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              suffixIcon: readOnly
                  ? Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    )
                  : null,
              border: _border(AppColors.border),
              enabledBorder: _border(AppColors.border),
              focusedBorder: _border(
                readOnly ? AppColors.border : AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        maxWidth: 480,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Update your profile details.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            _field(label: 'Full Name', controller: _nameController),
            _field(
              label: 'Employee ID',
              controller: _employeeIdController,
              readOnly: true,
            ),
            _field(
              label: 'Email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              readOnly: true,
            ),
            _field(
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),
            _field(label: 'Role', controller: _roleController, readOnly: true),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                style: TextStyle(color: AppColors.danger, fontSize: 13),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSaving ? null : _onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _isSaving ? null : _onSave,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 52),
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
