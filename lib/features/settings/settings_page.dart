import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme_controller.dart';
import '../../services/profile_service.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_profile_card.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import '../inventory_category/inventory_categories_page.dart';
import '../units_page/stock_units_page.dart';
import '../support_center/support_center_page.dart';
import '../personal_information/personal_information_page.dart';
import '../warehouse_location/warehouse_locations_page.dart';
import '../security/security_page.dart';
import '../language/language_page.dart';

/// Settings screen with live profile data and app configuration links.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _maxContentWidth = 600;
  static const double _sectionGap = AppSpacing.xxxl;

  final ProfileService _profileService = ProfileService();
  ProfileLookupResult? _profile;
  String? _profileError;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    try {
      final profile = await _profileService.getCurrentProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (profile == null) {
          _profileError = 'No profile is linked to the signed-in user.';
        }
        _isLoadingProfile = false;
      });
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = error.message;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _profileError = 'Unable to load profile: $error';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _onEditProfileTap() async {
    final profile = _profile;
    if (profile == null) return;
    final updatedProfile = await EditProfileDialog.show(
      context,
      profile: profile,
      onSave: _profileService.updateCurrentProfile,
    );
    if (updatedProfile != null && mounted) {
      setState(() => _profile = updatedProfile);
    }
  }

  void _onCloseTap() {
    Navigator.of(context).maybePop();
  }

  Future<void> _onPersonalInformationTap() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PersonalInformationPage()));
    if (mounted) await _loadProfile();
  }

  void _onSecurityTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SecurityPage()));
  }

  void _onWarehouseLocationsTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WarehouseLocationsPage()));
  }

  void _onStockUnitsTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const StockUnitsPage()));
  }

  void _onInventoryCategoriesTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InventoryCategoriesPage()));
  }

  Future<void> _onThemeTap() async {
    final controller = AppThemeController.instance;
    final selectedMode = await showDialog<ThemeMode>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Choose theme'),
        children: [
          RadioGroup<ThemeMode>(
            groupValue: controller.themeMode,
            onChanged: (value) {
              if (value != null) {
                Navigator.of(dialogContext).pop(value);
              }
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in [
                  ThemeMode.light,
                  ThemeMode.dark,
                  ThemeMode.system,
                ])
                  RadioListTile<ThemeMode>(
                    value: mode,
                    title: Text(_themeModeLabel(mode)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (selectedMode == null || !mounted) return;

    try {
      await controller.setThemeMode(selectedMode);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(controller.errorMessage ?? '$error')),
        );
    }
  }

  String _themeModeLabel(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
      ThemeMode.system => 'System',
    };
  }

  void _onLanguageTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const LanguagePage()));
  }

  void _onSupportCenterTap() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SupportCenterPage()));
  }

  void _onSignOutTap() {
    // Navigation only: no authentication or session handling exists yet.
    // Clears every route so the back button cannot return to the app.
    Navigator.of(context)
        .pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final overlayStyle = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SettingsHeader(onCloseTap: _onCloseTap),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xxxl + bottomInset,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isLoadingProfile)
                          const Center(child: CircularProgressIndicator())
                        else if (_profileError != null)
                          Column(
                            children: [
                              Text(
                                _profileError!,
                                style: TextStyle(color: AppColors.danger),
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: _loadProfile,
                                child: const Text('Retry'),
                              ),
                            ],
                          )
                        else if (_profile != null)
                          SettingsProfileCard(
                            profile: _profile!,
                            onEdit: _onEditProfileTap,
                          ),
                        const SizedBox(height: 28),
                        SettingsSection(
                          title: 'Account & Security',
                          children: [
                            SettingsTile(
                              icon: Icons.person_outline_rounded,
                              title: 'Personal Information',
                              subtitle: 'Manage your profile details',
                              onTap: _onPersonalInformationTap,
                            ),
                            SettingsTile(
                              icon: Icons.lock_outline_rounded,
                              title: 'Security',
                              subtitle: 'Password and biometrics',
                              onTap: _onSecurityTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                        SettingsSection(
                          title: 'Warehouse Config',
                          children: [
                            SettingsTile(
                              icon: Icons.warehouse_rounded,
                              title: 'Warehouse Locations',
                              subtitle: 'Manage your warehouse locations',
                              onTap: _onWarehouseLocationsTap,
                            ),
                            SettingsTile(
                              icon: Icons.inventory_2_outlined,
                              title: 'Stock Units',
                              subtitle: 'Standardized measurement units',
                              onTap: _onStockUnitsTap,
                            ),
                            SettingsTile(
                              icon: Icons.category_outlined,
                              title: 'Inventory Categories',
                              subtitle: 'Organize items by category',
                              onTap: _onInventoryCategoriesTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                        SettingsSection(
                          title: 'Preferences',
                          children: [
                            AnimatedBuilder(
                              animation: AppThemeController.instance,
                              builder: (context, child) {
                                final themeController =
                                    AppThemeController.instance;
                                final error = themeController.errorMessage;
                                return SettingsTile(
                                  icon: Icons.palette_outlined,
                                  title: 'Theme',
                                  subtitle: error == null
                                      ? 'Current: ${_themeModeLabel(themeController.themeMode)}'
                                      : 'Theme unavailable: $error',
                                  onTap: _onThemeTap,
                                );
                              },
                            ),
                            SettingsTile(
                              icon: Icons.language_rounded,
                              title: 'Language',
                              subtitle: 'Choose your preferred language',
                              onTap: _onLanguageTap,
                            ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                        SettingsSection(
                          title: 'System',
                          children: [
                            SettingsTile(
                              icon: Icons.help_outline_rounded,
                              title: 'Support Center',
                              subtitle: 'Contact system administrator.',
                              onTap: _onSupportCenterTap,
                            ),
                            SettingsTile(
                              icon: Icons.info_outline_rounded,
                              title: 'Version',
                              subtitle: 'v1.0.0',
                              trailing: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                        Center(
                          child: FilledButton(
                            onPressed: _onSignOutTap,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.danger,
                              foregroundColor: AppColors.textOnPrimary,
                              minimumSize: const Size(116, 38),
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                              ),
                              textStyle: textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: const Text('Sign Out'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
