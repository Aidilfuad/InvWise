import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import 'item_information_card.dart';

class NotesCard extends StatelessWidget {
  const NotesCard({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InventoryItemCardShell(
      title: 'Notes',
      trailing: 'Optional',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          keyboardType: TextInputType.multiline,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            isCollapsed: true,
            border: InputBorder.none,
            hintText: 'Add notes about this item',
            hintStyle:
                textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}