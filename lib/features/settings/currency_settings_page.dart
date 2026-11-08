import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/currency_service.dart';
import '../../services/role_access_service.dart';

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
    final controller = TextEditingController(
      text: _currencyService.exchangeRateUsdMyr.toString(),
    );
    final formKey = GlobalKey<FormState>();
    final rate = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Exchange Rate'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('1 USD = '),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      autofocus: true,
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
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogContext, double.parse(controller.text));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (rate == null || !mounted) return;

    try {
      await _currencyService.setExchangeRateUsdMyr(rate);
      _showMessage('Exchange rate updated.');
    } on CurrencyServiceException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Unable to save exchange rate: $error');
    }
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
  });

  final double rate;
  final bool canManage;
  final VoidCallback onUpdate;

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
                  onPressed: onUpdate,
                  child: const Text('Update Exchange Rate'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
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
