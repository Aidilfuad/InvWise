import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/support_request_service.dart';

class ContactItSheet extends StatefulWidget {
  const ContactItSheet({super.key});

  static Future<bool> show(BuildContext context) async {
    return await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const ContactItSheet(),
    ) ?? false;
  }

  @override
  State<ContactItSheet> createState() => _ContactItSheetState();
}

class _ContactItSheetState extends State<ContactItSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _problemController = TextEditingController();
  final _supportRequestService = SupportRequestService();
  bool _isSending = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _employeeIdController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  Future<void> _onSendRequest() async {
    if (_isSending || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final message = [
      'Contact email: ${_emailController.text.trim()}',
      'Employee ID: ${_employeeIdController.text.trim()}',
      '',
      _problemController.text.trim(),
    ].join('\n');

    try {
      await _supportRequestService.createRequest(
        subject: 'IT support request',
        message: message,
      );
      if (mounted) Navigator.of(context).pop(true);
    } on SupportRequestServiceException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isSending = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to send the support request: $error';
          _isSending = false;
        });
      }
    }
  }

  void _onClose() {
    Navigator.of(context).pop();
  }

  OutlineInputBorder _border(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color),
    );
  }

  Widget _field({
    required String hint,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: !_isSending,
        keyboardType: keyboardType,
        minLines: maxLines,
        maxLines: maxLines,
        style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.background,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          border: _border(AppColors.border),
          enabledBorder: _border(AppColors.border),
          focusedBorder: _border(AppColors.primary),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return hint == 'Describe the problem'
                ? 'Describe the problem.'
                : 'This field is required.';
          }
          if (hint == 'IT support email' &&
              !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                  .hasMatch(value.trim())) {
            return 'Enter a valid email address.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 58,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textPrimary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Contact IT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Send a support request to your company IT team. '
                'Your Employee ID and message will be included.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              _field(
                hint: 'IT support email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              _field(
                hint: 'Employee ID',
                controller: _employeeIdController,
              ),
              _field(
                hint: 'Describe the problem',
                controller: _problemController,
                keyboardType: TextInputType.multiline,
                maxLines: 4,
              ),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  style: TextStyle(color: AppColors.danger),
                ),
                const SizedBox(height: 12),
              ],
              FilledButton(
                onPressed: _isSending ? null : _onSendRequest,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Send request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isSending ? null : _onClose,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}