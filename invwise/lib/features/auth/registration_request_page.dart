import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/registration_request_service.dart';
import '../../services/workspace_access_service.dart';
import '../../widgets/searchable_dropdown_form_field.dart';
import 'registration_request_validation.dart';

const _workspaceRoleOrder = [
  'Super Admin',
  'Director',
  'Factory 1 Manager',
  'Factory 2 Manager',
  'Warehouse Manager',
  'Manager',
  'Supervisor',
  'Production Supervisor',
  'Quality Assurance / QC Supervisor',
  'Maintenance & Automation Lead',
  'Inventory Controller',
  'Warehouse Supervisor',
  'Storekeeper',
  'Viewer',
];

class RegistrationRequestPage extends StatefulWidget {
  const RegistrationRequestPage({super.key});

  @override
  State<RegistrationRequestPage> createState() =>
      _RegistrationRequestPageState();
}

class _RegistrationRequestPageState extends State<RegistrationRequestPage> {
  static const double _maxContentWidth = 480;
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _reasonController = TextEditingController();
  final _service = RegistrationRequestService();
  final _accessService = WorkspaceAccessService();

  String? _requestedRole;
  String? _department;
  List<String> _departments = const [];
  List<String> _roles = const [];
  bool _obscurePassword = true;
  bool _obscureConfirmation = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final departments = await _accessService.getDepartments();
      var roles = await _accessService.getRoles();
      if (departments.isEmpty) {
        _departments = const [
          'Warehouse Operations',
          'Inventory Control',
          'Telemetry & Maintenance',
          'Logistics & Distribution',
          'Quality & Compliance',
          'Administration',
        ];
      } else {
        _departments = departments.map((item) => item.name).toList();
      }
      roles = roles.where((role) => role.name != 'Super Admin').toList();
      roles.sort((left, right) {
        final leftIndex = _workspaceRoleOrder.indexOf(left.name);
        final rightIndex = _workspaceRoleOrder.indexOf(right.name);
        final leftRank = leftIndex < 0 ? _workspaceRoleOrder.length : leftIndex;
        final rightRank = rightIndex < 0
            ? _workspaceRoleOrder.length
            : rightIndex;
        return leftRank.compareTo(rightRank);
      });
      _roles = roles.isEmpty
          ? _workspaceRoleOrder.where((role) => role != 'Super Admin').toList()
          : roles.map((role) => role.name).toList(growable: false);
      _requestedRole = _roles.contains('Viewer') ? 'Viewer' : _roles.first;
    } catch (_) {
      _departments = const [
        'Warehouse Operations',
        'Inventory Control',
        'Telemetry & Maintenance',
        'Logistics & Distribution',
        'Quality & Compliance',
        'Administration',
      ];
      _roles = _workspaceRoleOrder
          .where((role) => role != 'Super Admin')
          .toList(growable: false);
      _requestedRole = 'Viewer';
    } finally {
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _employeeIdController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting || !(_formKey.currentState?.validate() ?? false)) return;
    final role = _requestedRole;
    final department = _department;
    if (role == null || department == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await _service.submitRequest(
        fullName: _fullNameController.text,
        employeeId: _employeeIdController.text,
        email: _emailController.text,
        department: department,
        requestedRole: role,
        reason: _reasonController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Your registration request has been submitted.'),
          ),
        );
      Navigator.of(context).pop();
    } on RegistrationRequestServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isSubmitting = false;
      });
    }
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction textInputAction = TextInputAction.next,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      obscureText: obscureText,
      enabled: !_isSubmitting,
      validator: validator ?? RegistrationRequestValidation.required,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registration Request'),
        backgroundColor: AppColors.surface,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Request an Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Submit your details and requested role. This form only '
                  'stores a request; it does not create an account. If '
                  'approved, you will receive an invitation to set your '
                  'password.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                _textField(
                  label: 'Full Name',
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: AppSpacing.md),
                _textField(
                  label: 'Employee ID',
                  controller: _employeeIdController,
                ),
                const SizedBox(height: AppSpacing.md),
                _textField(
                  label: 'Email',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: RegistrationRequestValidation.email,
                ),
                const SizedBox(height: AppSpacing.md),
                SearchableDropdownFormField(
                  initialValue: _department,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    border: OutlineInputBorder(),
                  ),
                  options: _departments,
                  enabled: !_isSubmitting,
                  validator: (value) => value == null
                      ? RegistrationRequestValidation.required(null)
                      : null,
                  onChanged: (value) => setState(() => _department = value),
                ),
                const SizedBox(height: AppSpacing.md),
                SearchableDropdownFormField(
                  initialValue: _requestedRole,
                  decoration: const InputDecoration(
                    labelText: 'Requested Role',
                    border: OutlineInputBorder(),
                  ),
                  options: _roles,
                  enabled: !_isSubmitting,
                  validator: (value) => value == null
                      ? RegistrationRequestValidation.required(null)
                      : null,
                  onChanged: (role) => setState(() => _requestedRole = role),
                ),
                const SizedBox(height: AppSpacing.md),
                _textField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) {
                    final password = value ?? '';
                    if (password.length < 8 ||
                        !RegExp(r'[A-Za-z]').hasMatch(password) ||
                        !RegExp(r'\d').hasMatch(password)) {
                      return 'Use at least 8 characters, including a letter and a number.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                _textField(
                  label: 'Confirm Password',
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmation,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirmation
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () => setState(
                      () => _obscureConfirmation = !_obscureConfirmation,
                    ),
                    icon: Icon(
                      _obscureConfirmation
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                  validator: (value) =>
                      RegistrationRequestValidation.confirmation(
                        password: _passwordController.text,
                        confirmation: value,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Your chosen password is used only while your request is '
                  'pending. If approved, your initial password becomes your '
                  'Employee ID as entered (surrounding spaces removed). Sign in with it, then change it in '
                  'Settings > Security > Change Password.',
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _reasonController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  validator: RegistrationRequestValidation.required,
                  decoration: const InputDecoration(
                    labelText: 'Reason for access',
                    border: OutlineInputBorder(),
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
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Request'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
