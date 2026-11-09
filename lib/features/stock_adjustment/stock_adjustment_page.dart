import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/inventory_service.dart';
import '../../services/role_access_service.dart';
import 'data/stock_adjustment_options.dart';
import 'widgets/adjustment_type_selector.dart';
import 'widgets/item_summary_card.dart';
import 'widgets/location_card.dart';
import 'widgets/reason_code_selector.dart';

class StockAdjustmentPage extends StatefulWidget {
  const StockAdjustmentPage({
    super.key,
    required this.itemId,
    this.initialType = AdjustmentType.remove,
  });

  final String itemId;
  final AdjustmentType initialType;

  @override
  State<StockAdjustmentPage> createState() => _StockAdjustmentPageState();
}

class _StockAdjustmentPageState extends State<StockAdjustmentPage> {
  static const double _maxContentWidth = 1600;

  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  final _service = InventoryService();
  final RoleAccessService _roleAccess = RoleAccessService.instance;

  late AdjustmentType _type = widget.initialType;
  ReasonCode _reason = ReasonCode.restock;
  InventoryItem? _item;
  List<InventoryLocation> _locations = const [];
  String? _locationId;
  double _locationQuantity = 0;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isLoadingLocationQuantity = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadItem() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _service.getItemById(widget.itemId),
        _service.getLocations(),
      ]);
      final item = results[0] as InventoryItem;
      final locations = results[1] as List<InventoryLocation>;
      if (!mounted) return;

      final selectedLocationId =
          locations.any((location) => location.id == item.locationId)
          ? item.locationId
          : locations.firstOrNull?.id;
      setState(() {
        _item = item;
        _locations = locations;
        _locationId = selectedLocationId;
        _isLoading = false;
      });
      if (selectedLocationId != null) {
        await _loadLocationQuantity(selectedLocationId);
      }
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadLocationQuantity(String locationId) async {
    final item = _item;
    if (item == null) return;
    setState(() => _isLoadingLocationQuantity = true);
    try {
      final quantity = await _service.getStockQuantity(
        itemId: item.id,
        locationId: locationId,
      );
      if (!mounted) return;
      setState(() {
        _locationQuantity = quantity;
        _isLoadingLocationQuantity = false;
      });
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoadingLocationQuantity = false;
      });
    }
  }

  Future<void> _onLocationTap() async {
    if (_locations.isEmpty || _isSaving) return;
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final location in _locations)
              ListTile(
                title: Text(location.name),
                trailing: location.id == _locationId
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.pop(context, location.id),
              ),
          ],
        ),
      ),
    );
    if (selectedId == null || !mounted || selectedId == _locationId) return;
    setState(() {
      _locationId = selectedId;
      _errorMessage = null;
    });
    await _loadLocationQuantity(selectedId);
  }

  Future<void> _onSaveTap() async {
    final allowedPermissions = switch (_type) {
      AdjustmentType.add => const {
        AppPermission.receiveStock,
        AppPermission.adjustStock,
      },
      AdjustmentType.remove => const {
        AppPermission.issueStock,
        AppPermission.adjustStock,
      },
    };
    if (!_roleAccess.allowsAny(allowedPermissions)) {
      _showMessage('Your role does not have permission to adjust stock.');
      return;
    }
    if (_isSaving || _item == null || _locationId == null) return;
    final quantity = double.tryParse(_quantityController.text.trim());
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      _showMessage('Enter a valid quantity greater than zero.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedQuantity = await _service.adjustStock(
        itemId: _item!.id,
        locationId: _locationId!,
        quantity: quantity,
        add: _type == AdjustmentType.add,
      );
      if (!mounted) return;
      setState(() => _locationQuantity = updatedQuantity);
      final activityWarning = _service.lastActivityLogWarning;
      if (activityWarning != null) {
        _showMessage(activityWarning);
      }
      Navigator.of(context).pop(true);
    } on InventoryServiceException catch (e) {
      if (!mounted) return;
      _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatQuantity(double value) =>
      value.toStringAsFixed(3).replaceFirst(RegExp(r'\.?0+$'), '');

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final item = _item;
    final location = _locations
        .where((location) => location.id == _locationId)
        .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Stock Adjustment',
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : item == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _errorMessage ?? 'Inventory item not found.',
                          textAlign: TextAlign.center,
                        ),
                        AppSpacing.gapMd,
                        FilledButton(
                          onPressed: _loadItem,
                          child: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xl,
                          AppSpacing.xl + bottomInset,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.lg,
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppColors.danger,
                                  ),
                                ),
                              ),
                            ItemSummaryCard(
                              sku: item.sku,
                              name: item.name,
                              quantityLabel:
                                  '${_formatQuantity(_locationQuantity)} '
                                  '${item.unitLabel}',
                            ),
                            AppSpacing.gapXxl,
                            _SectionLabel('Adjustment Type', large: true),
                            AppSpacing.gapLg,
                            AdjustmentTypeSelector(
                              selected: _type,
                              onChanged: (type) => setState(() => _type = type),
                            ),
                            AppSpacing.gapXxl,
                            _SectionLabel(
                              'Available at location: '
                              '${_formatQuantity(_locationQuantity)} '
                              '${item.unitLabel}',
                            ),
                            AppSpacing.gapMd,
                            _buildQuantityRow(textTheme, item),
                            AppSpacing.gapXxl,
                            const _SectionLabel('Reason Code'),
                            AppSpacing.gapMd,
                            ReasonCodeSelector(
                              selected: _reason,
                              onChanged: (reason) =>
                                  setState(() => _reason = reason),
                            ),
                            AppSpacing.gapXxl,
                            const _SectionLabel('Notes (Optional)'),
                            AppSpacing.gapMd,
                            _buildNotesField(),
                            AppSpacing.gapXxl,
                            if (_isLoadingLocationQuantity)
                              const LinearProgressIndicator()
                            else
                              LocationCard(
                                location:
                                    location?.name ??
                                    'Select a warehouse location',
                                onTap: _onLocationTap,
                              ),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton(
                            onPressed:
                                _isSaving ||
                                    _isLoadingLocationQuantity ||
                                    location == null
                                ? null
                                : _onSaveTap,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(_type.label),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildQuantityRow(TextTheme textTheme, InventoryItem item) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,3}')),
            ],
            style: textTheme.bodyLarge,
            decoration: InputDecoration(
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
      decoration: InputDecoration(
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
