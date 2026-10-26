import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import 'data/stock_adjustment_mock_data.dart';
import 'widgets/adjustment_type_selector.dart';
import 'widgets/item_summary_card.dart';
import 'widgets/location_card.dart';
import 'widgets/reason_code_selector.dart';

/// Stock Adjustment screen. UI only, backed by dummy data.
class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({
    super.key,
    this.item = StockAdjustmentMockData.item,
    this.initialType = AdjustmentType.remove,
  });

  final StockAdjustmentItem item;

  /// Which adjustment type is selected when the screen opens.
  final AdjustmentType initialType;

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  static const double _maxContentWidth = 600;

  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  // Defaults match the reference design.
  late AdjustmentType _type = widget.initialType;
  ReasonCode _reason = ReasonCode.restock;

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onCloseTap() {
    // Pops back to Item Details.
    Navigator.of(context).maybePop();
  }

  void _onHelpTap() {
    // TODO: Show help for stock adjustments.
  }

  void _onTypeChanged(AdjustmentType type) {
    setState(() => _type = type);
  }

  void _onReasonChanged(ReasonCode reason) {
    setState(() => _reason = reason);
  }

  void _onLocationTap() {
    // TODO: Open the warehouse location picker.
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final item = widget.item;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: _onCloseTap,
        ),
        title: Text(
          'Stock Adjustment',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: _onHelpTap,
          ),
          AppSpacing.gapSm,
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xxl + bottomInset,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ItemSummaryCard(
                  sku: item.sku,
                  name: item.name,
                  quantityLabel: item.quantityLabel,
                ),
                AppSpacing.gapXxl,
                _SectionLabel('Adjustment Type', large: true),
                AppSpacing.gapLg,
                AdjustmentTypeSelector(
                  selected: _type,
                  onChanged: _onTypeChanged,
                ),
                AppSpacing.gapXxl,
                const _SectionLabel('Quantity to Adjust'),
                AppSpacing.gapMd,
                _buildQuantityRow(textTheme, item),
                AppSpacing.gapXxl,
                const _SectionLabel('Reason Code'),
                AppSpacing.gapMd,
                ReasonCodeSelector(
                  selected: _reason,
                  onChanged: _onReasonChanged,
                ),
                AppSpacing.gapXxl,
                const _SectionLabel('Notes (Optional)'),
                AppSpacing.gapMd,
                _buildNotesField(),
                AppSpacing.gapXxl,
                LocationCard(
                  location: item.location,
                  onTap: _onLocationTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityRow(TextTheme textTheme, StockAdjustmentItem item) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantityController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: textTheme.bodyLarge,
            decoration: const InputDecoration(
              hintText: '0',
              contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              prefixIcon: Icon(
                Icons.edit_note_rounded,
                size: AppSpacing.iconMd,
                color: AppColors.textPrimary,
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: 48,
                minHeight: AppSpacing.iconMd,
              ),
            ),
          ),
        ),
        AppSpacing.gapMd,
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppSpacing.borderRadiusLg,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            item.unitLabel,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesField() {
    return TextField(
      controller: _notesController,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      minLines: 1,
      maxLines: 4,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: const InputDecoration(
        hintText: 'Add additional details about this adjustment...',
        hintMaxLines: 2,
        contentPadding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        prefixIcon: Icon(
          Icons.mail_outline_rounded,
          size: AppSpacing.iconMd,
          color: AppColors.textPrimary,
        ),
        prefixIconConstraints: BoxConstraints(
          minWidth: 40,
          minHeight: AppSpacing.iconMd,
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final base = large ? textTheme.titleMedium : textTheme.titleSmall;

    return Text(
      text,
      style: base?.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}