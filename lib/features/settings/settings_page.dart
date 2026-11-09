import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/routes/app_routes.dart';
import '../../app/theme/app_theme_controller.dart';
import '../../services/currency_service.dart';
import '../../services/auth_service.dart';
import '../../services/login_preferences_service.dart';
import '../../services/profile_service.dart';
import '../../services/role_access_service.dart';
import '../../widgets/offline_sync_indicator.dart';
import 'widgets/edit_profile_sheet.dart';
import 'widgets/settings_header.dart';
import 'widgets/settings_profile_card.dart';
import 'widgets/settings_section.dart';
import 'widgets/settings_tile.dart';
import 'currency_settings_page.dart';
import '../inventory_category/inventory_categories_page.dart';
import '../units_page/stock_units_page.dart';
import '../support_center/support_center_page.dart';
import '../personal_information/personal_information_page.dart';
import '../warehouse_location/warehouse_locations_page.dart';
import '../security/security_page.dart';
import '../language/language_page.dart';
import '../user_management/user_management_page.dart';

/// Settings screen with live profile data and app configuration links.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _maxContentWidth = 1600;
  static const double _sectionGap = AppSpacing.xxxl;

  final ProfileService _profileService = ProfileService();
  final RoleAccessService _roleAccess = RoleAccessService.instance;
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
      _roleAccess.updateRole(profile?.role);
      String? currencyError;
      if (profile != null) {
        try {
          await CurrencyService.instance.loadForProfile(profile.id);
        } on CurrencyServiceException catch (error) {
          currencyError = error.message;
        } catch (error) {
          currencyError = 'Unable to load currency settings: $error';
        }
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        if (profile == null) {
          _profileError = 'No profile is linked to the signed-in user.';
        }
        _isLoadingProfile = false;
      });
      if (currencyError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(currencyError)));
      }
    } on ProfileServiceException catch (error) {
      if (!mounted) return;
      _roleAccess.updateRole(null);
      setState(() {
        _profileError = error.message;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) return;
      _roleAccess.updateRole(null);
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
      onProfileUpdated: (updated) {
        if (mounted) setState(() => _profile = updated);
      },
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

  void _onCurrencyTap() {
    final profileId = _profile?.id;
    if (profileId == null ||
        !_roleAccess.allows(AppPermission.viewCurrencySettings)) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CurrencySettingsPage(profileId: profileId),
      ),
    );
  }

  void _onSecurityTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.accessPersonalSecurity,
          child: const SecurityPage(),
        ),
      ),
    );
  }

  void _onWarehouseLocationsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.manageWarehouses,
          child: const WarehouseLocationsPage(),
        ),
      ),
    );
  }

  void _onStockUnitsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.manageUnits,
          child: const StockUnitsPage(),
        ),
      ),
    );
  }

  void _onInventoryCategoriesTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.manageCategories,
          child: const InventoryCategoriesPage(),
        ),
      ),
    );
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewSupportCenter,
          child: const SupportCenterPage(),
        ),
      ),
    );
  }

  void _onRegistrationApprovalsTap() {
    Navigator.of(context).pushNamed(AppRoutes.registrationApprovals);
  }

  void _onUserManagementTap() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const UserManagementPage()));
  }

  void _onSystemInformationTap() {
    Navigator.of(context).pushNamed(AppRoutes.systemInformation);
  }

  void _onBackupRestoreTap() {
    Navigator.of(context).pushNamed(AppRoutes.backupRestore);
  }

  void _onVersionTap() {
    Navigator.of(context).pushNamed(AppRoutes.appVersion);
  }

  Future<void> _onSignOutTap() async {
    try {
      await AuthService().signOut();
    } on AuthServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final overlayStyle = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxContentWidth),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const OfflineSyncIndicator(),
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
                            if (_roleAccess.allows(
                              AppPermission.accessPersonalSecurity,
                            ))
                              SettingsTile(
                                icon: Icons.lock_outline_rounded,
                                title: 'Security',
                                subtitle: 'Password and biometrics',
                                onTap: _onSecurityTap,
                              ),
                            if (_roleAccess.allows(
                              AppPermission.viewActivityLog,
                            ))
                              SettingsTile(
                                icon: Icons.history_rounded,
                                title: 'Activity Logs',
                                subtitle: 'Review recent system activity',
                                onTap: () =>
                                    Navigator.of(context)
                                        .pushNamed(AppRoutes.activityLogs),
                              ),
                          ],
                        ),
                        const SizedBox(height: _sectionGap),
                        SettingsSection(
                          title: 'Warehouse Config',
                          children: [
                            if (_roleAccess.allows(
                              AppPermission.manageWarehouses,
                            ))
                              SettingsTile(
                                icon: Icons.warehouse_rounded,
                                title: 'Warehouse Locations',
                                subtitle: 'Manage your warehouse locations',
                                onTap: _onWarehouseLocationsTap,
                              ),
                            if (_roleAccess.allows(AppPermission.manageUnits))
                              SettingsTile(
                                icon: Icons.inventory_2_outlined,
                                title: 'Stock Units',
                                subtitle: 'Standardized measurement units',
                                onTap: _onStockUnitsTap,
                              ),
                            if (_roleAccess.allows(
                              AppPermission.manageCategories,
                            ))
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
                            AnimatedBuilder(
                              animation: LoginPreferencesService.instance,
                              builder: (context, child) {
                                final preferences =
                                    LoginPreferencesService.instance;
                                final messenger = ScaffoldMessenger.of(context);
                                return SettingsTile(
                                  icon: Icons.login_rounded,
                                  title: 'Login Preferences',
                                  subtitle:
                                      'Remember Me: '
                                      '${preferences.rememberMe ? 'ON' : 'OFF'}',
                                  trailing: Switch.adaptive(
                                    value: preferences.rememberMe,
                                    onChanged: (enabled) async {
                                      try {
                                        await preferences.setRememberMe(
                                          enabled,
                                        );
                                      } catch (error) {
                                        if (!mounted) return;
                                        messenger
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Unable to save login '
                                                'preference: $error',
                                              ),
                                            ),
                                          );
                                      }
                                    },
                                  ),
                                );
                              },
                            ),
                            if (_profile != null &&
                                _roleAccess.allows(
                                  AppPermission.viewCurrencySettings,
                                ))
                              AnimatedBuilder(
                                animation: CurrencyService.instance,
                                builder: (context, child) => SettingsTile(
                                  icon: Icons.attach_money_rounded,
                                  title: 'Currency',
                                  subtitle:
                                      'Display: ${CurrencyService.instance.currencyCode}',
                                  onTap: _onCurrencyTap,
                                ),
                              ),
                            SettingsTile(
                              icon: Icons.settings_backup_restore_outlined,
                              title: 'Backup Settings',
                              subtitle:
                                  'Export, import, or restore preferences',
                              onTap: _onBackupRestoreTap,
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
                            if (_roleAccess.allows(AppPermission.manageUsers))
                              SettingsTile(
                                icon: Icons.manage_accounts_outlined,
                                title: 'User Management',
                                subtitle:
                                    'Manage user roles and account status',
                                onTap: _onUserManagementTap,
                              ),
                            if (_roleAccess.allows(
                              AppPermission.manageRegistrationRequests,
                            ))
                              SettingsTile(
                                icon: Icons.how_to_reg_outlined,
                                title: 'Registration Approvals',
                                subtitle: 'Review pending account requests',
                                onTap: _onRegistrationApprovalsTap,
                              ),
                            if (_roleAccess.allows(
                              AppPermission.viewSupportCenter,
                            ))
                              SettingsTile(
                                icon: Icons.help_outline_rounded,
                                title: 'Support Center',
                                subtitle: 'Contact system administrator.',
                                onTap: _onSupportCenterTap,
                              ),
                            SettingsTile(
                              icon: Icons.monitor_heart_outlined,
                              title: 'System Information',
                              subtitle: 'Review connection and service status',
                              onTap: _onSystemInformationTap,
                            ),
                            SettingsTile(
                              icon: Icons.system_update_alt,
                              title: 'Version Information',
                              subtitle:
                                  'Check the installed and latest version',
                              onTap: _onVersionTap,
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
