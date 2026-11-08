import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/currency_service.dart';
import '../../services/role_access_service.dart';
import '../../services/password_confirmation_service.dart';

class CurrencySettingsPage extends StatelessWidget {
  const CurrencySettingsPage({super.key, required this.profileId});

  final String profileId;

  @override
  Widget build(BuildContext context) {
    return RoleAccessGuard(
      permission: AppPermission.viewCurrencySettings,
      child: _CurrencySettingsContent(profileId: profileId),
    );
  }
}

class _CurrencySettingsContent extends StatefulWidget {
  const _CurrencySettingsContent({required this.profileId});

  final String profileId;

  @override
  State<_CurrencySettingsContent> createState() =>
      _CurrencySettingsContentState();
}

class _CurrencySettingsContentState extends State<_CurrencySettingsContent> {
  final _currencyService = CurrencyService.instance;
  bool _isLoading = true;
  bool _isSavingCurrency = false;
  bool _isSavingExchangeRate = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await _currencyService.loadForProfile(widget.profileId, refresh: true);
    } on CurrencyServiceException catch (error) {
      _loadError = error.message;
    } catch (error) {
      _loadError = 'Unable to load currency settings: $error';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _onCurrencyChanged(DisplayCurrency? currency) async {
    if (currency == null || _isSavingCurrency) return;
    setState(() => _isSavingCurrency = true);
    try {
      await _currencyService.setDisplayCurrency(
        profileId: widget.profileId,
        currency: currency,
      );
    } on CurrencyServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to save currency preference: $error');
    } finally {
      if (mounted) setState(() => _isSavingCurrency = false);
    }
  }

  Future<void> _showExchangeRateDialog() async {
    if (!await PasswordConfirmationService.confirm(
      context,
      action: 'change the exchange rate',
    )) {
      return;
    }
    if (!mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ExchangeRateDialog(
        initialRate: _currencyService.exchangeRateUsdMyr,
        onSave: _currencyService.setExchangeRateUsdMyr,
        onSavingChanged: (saving) {
          if (mounted) setState(() => _isSavingExchangeRate = saving);
        },
      ),
    );
    if (saved == true && mounted) _showMessage('Exchange rate updated.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Currency')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: AnimatedBuilder(
            animation: _currencyService,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.all(AppSpacing.xl),
              children: [
                Text(
                  'Display Currency',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Choose how inventory financial values are shown.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.lg),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  Column(
                    children: [
                      if (_loadError != null ||
                          _currencyService.errorMessage != null)
                        _LoadError(
                          message: _loadError ?? _currencyService.errorMessage!,
                          onRetry: _loadSettings,
                        ),
                      if (_currencyService.errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Text(
                            'Showing the default currency until settings can '
                            'be loaded.',
                            style: TextStyle(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Card(
                        clipBehavior: Clip.antiAlias,
                        child: RadioGroup<DisplayCurrency>(
                          groupValue: _currencyService.displayCurrency,
                          onChanged: _onCurrencyChanged,
                          child: Column(
                            children: [
                              for (final currency in DisplayCurrency.values)
                                RadioListTile<DisplayCurrency>(
                                  value: currency,
                                  title: Text(currency.code),
                                  subtitle: Text(currency.name),
                                  secondary: Text(
                                    currency.symbol,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      _ExchangeRateCard(
                        rate: _currencyService.exchangeRateUsdMyr,
                        canManage: RoleAccessService.instance.allows(
                          AppPermission.manageExchangeRate,
                        ),
                        onUpdate: _showExchangeRateDialog,
                        isUpdating: _isSavingExchangeRate,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExchangeRateCard extends StatelessWidget {
  const _ExchangeRateCard({
    required this.rate,
    required this.canManage,
    required this.onUpdate,
    required this.isUpdating,
  });

  final double rate;
  final bool canManage;
  final VoidCallback onUpdate;
  final bool isUpdating;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exchange Rate',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '1 USD = ${rate.toString()} MYR',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (canManage) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: isUpdating ? null : onUpdate,
                  child: Text(isUpdating ? 'Saving…' : 'Update Exchange Rate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExchangeRateDialog extends StatefulWidget {
  const _ExchangeRateDialog({
    required this.initialRate,
    required this.onSave,
    required this.onSavingChanged,
  });

  final double initialRate;
  final Future<void> Function(double rate) onSave;
  final ValueChanged<bool> onSavingChanged;

  @override
  State<_ExchangeRateDialog> createState() => _ExchangeRateDialogState();
}

class _ExchangeRateDialogState extends State<_ExchangeRateDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialRate.toString());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    widget.onSavingChanged(true);
    try {
      await widget.onSave(double.parse(_controller.text.trim()));
      if (mounted) Navigator.of(context).pop(true);
    } on CurrencyServiceException catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error.message;
          _isSaving = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Unable to save the exchange rate: $error';
          _isSaving = false;
        });
      }
    } finally {
      widget.onSavingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Exchange Rate'),
    content: Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('1 USD = '),
              Expanded(
                child: TextFormField(
                  controller: _controller,
                  autofocus: true,
                  enabled: !_isSaving,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'MYR',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final parsed = double.tryParse(value?.trim() ?? '');
                    if (parsed == null || !parsed.isFinite || parsed <= 0) {
                      return 'Enter a value greater than zero';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _isSaving ? null : _save,
        child: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Save'),
      ),
    ],
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        message,
        style: TextStyle(color: AppColors.danger),
        textAlign: TextAlign.center,
      ),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}
