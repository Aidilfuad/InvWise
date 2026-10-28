import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

class AddStockUnitDialog extends StatefulWidget {
  const AddStockUnitDialog({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialAbbreviation,
    this.initialDescription,
  });

  final Future<String?> Function(
    String name,
    String abbreviation,
    String description,
  )
  onSave;

  /// When [initialName] is set the dialog opens in edit mode.
  final String? initialName;
  final String? initialAbbreviation;
  final String? initialDescription;

  bool get isEdit => initialName != null;

  static Future<void> show(
    BuildContext context, {
    required Future<String?> Function(
      String name,
      String abbreviation,
      String description,
    )
    onSave,
    String? initialName,
    String? initialAbbreviation,
    String? initialDescription,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddStockUnitDialog(
        onSave: onSave,
        initialName: initialName,
        initialAbbreviation: initialAbbreviation,
        initialDescription: initialDescription,
      ),
    );
  }

  @override
  State<AddStockUnitDialog> createState() => _AddStockUnitDialogState();
}

class _AddStockUnitDialogState extends State<AddStockUnitDialog> {
  static const int _maxDescription = 200;

  late final TextEditingController _nameController;
  late final TextEditingController _abbreviationController;
  late final TextEditingController _descriptionController;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _abbreviationFocus = FocusNode();
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _abbreviationController = TextEditingController(
      text: widget.initialAbbreviation ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialDescription ?? '',
    );
    _nameFocus.addListener(() => setState(() {}));
    _abbreviationFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _abbreviationController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    _abbreviationFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final error = await widget.onSave(
      _nameController.text,
      _abbreviationController.text,
      _descriptionController.text,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = false;
      _errorText = error;
    });
  }

  Widget _singleLineField({
    required TextTheme textTheme,
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool enabled,
  }) {
    final focused = focusNode.hasFocus;

    return Container(
      height: 56,
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: focused ? AppColors.primary : AppColors.border,
          width: focused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        enabled: enabled,
        style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          isCollapsed: true,
          border: InputBorder.none,
          hintText: hint,
          hintStyle: textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isEdit = widget.isEdit;

    return Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    isEdit ? 'Edit Unit' : 'Add Unit',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: _isSaving ? null : () => Navigator.pop(context),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              isEdit
                  ? 'Update the name, abbreviation and description of this unit.'
                  : 'Create a measurement unit to keep inventory consistent '
                        'across your warehouse.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Unit Name',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _singleLineField(
              textTheme: textTheme,
              controller: _nameController,
              focusNode: _nameFocus,
              enabled: !_isSaving,
              hint: 'Enter unit name',
            ),
            SizedBox(height: 6),
            Text(
              'Use a clear, unique unit name.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              'Abbreviation',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            _singleLineField(
              textTheme: textTheme,
              controller: _abbreviationController,
              focusNode: _abbreviationFocus,
              enabled: !_isSaving,
              hint: 'e.g. PCS',
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Text(
                  'Description',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Spacer(),
                Text(
                  'Optional',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _descriptionController,
                enabled: !_isSaving,
                maxLength: _maxDescription,
                minLines: 3,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  counterText: '',
                  hintText: 'Describe this unit',
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_descriptionController.text.length} / $_maxDescription',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            if (_errorText != null) ...[
              Text(
                _errorText!,
                style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
              SizedBox(height: AppSpacing.md),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(minimumSize: Size(0, 48)),
                  child: Text(
                    'Cancel',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(104, 48),
                    shape: StadiumBorder(),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Save',
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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
