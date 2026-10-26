import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../app/constants/app_spacing.dart';

class AddCategoryDialog extends StatefulWidget {
  const AddCategoryDialog({
    super.key,
    required this.onSave,
    this.initialName,
    this.initialDescription,
  });

  final void Function(String name, String description) onSave;

  /// When [initialName] is set the dialog opens in edit mode.
  final String? initialName;
  final String? initialDescription;

  bool get isEdit => initialName != null;

  static Future<void> show(
    BuildContext context, {
    required void Function(String name, String description) onSave,
    String? initialName,
    String? initialDescription,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AddCategoryDialog(
        onSave: onSave,
        initialName: initialName,
        initialDescription: initialDescription,
      ),
    );
  }

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  static const int _maxDescription = 200;

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController =
        TextEditingController(text: widget.initialDescription ?? '');
    _nameFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nameFocused = _nameFocus.hasFocus;
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
                    isEdit ? 'Edit Category' : 'Add Category',
                    style: textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => Navigator.pop(context),
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              isEdit
                  ? 'Update the name and description of this category.'
                  : 'Create a group to keep related inventory items organized.',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'Category Name',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Container(
              height: 56,
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: nameFocused ? AppColors.primary : AppColors.border,
                  width: nameFocused ? 2 : 1,
                ),
              ),
              child: TextField(
                controller: _nameController,
                focusNode: _nameFocus,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Enter category name',
                  hintStyle: textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Use a clear, unique category name.',
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
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
                  hintText: 'Describe this category',
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
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
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
                  onPressed: () => widget.onSave(
                    _nameController.text,
                    _descriptionController.text,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: Size(104, 48),
                    shape: StadiumBorder(),
                  ),
                  child: Text(
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