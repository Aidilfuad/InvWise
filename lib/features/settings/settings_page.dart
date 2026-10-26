import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../app/routes/app_routes.dart';
import 'data/settings_mock_data.dart';
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

/// Settings screen. UI only, backed by dummy data.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const double _maxContentWidth = 600;
  static const double _sectionGap = AppSpacing.xxxl;

  bool _darkMode = false;

  void _onCloseTap() {
    Navigator.of(context).maybePop();
  }

  void _onPersonalInformationTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PersonalInformationPage(),
      ),
    );
  }

  void _onSecurityTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SecurityPage(),
      ),
    );
  }

  void _onWarehouseLocationsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const WarehouseLocationsPage(),
      ),
    );
  }

  void _onStockUnitsTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StockUnitsPage()),
    );
  }

  void _onInventoryCategoriesTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InventoryCategoriesPage()),
    );
  }

  void _onDarkModeChanged(bool value) {
    setState(() => _darkMode = value);
    // TODO: Apply the dark theme (AppTheme only has a light theme for now).
  }

  void _onLanguageTap() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const LanguagePage(),
      ),
    );
  }

  void _onSupportCenterTap() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SupportCenterPage()),
    );
  }

  void _onSignOutTap() {
    // Navigation only: no authentication or session handling exists yet.
    // Clears every route so the back button cannot return to the app.
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
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
                        SettingsProfileCard(
                          profile: SettingsMockData.profile,
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
                              subtitle: SettingsMockData.warehouseLocation,
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
                            SettingsTile(
                              icon: Icons.dark_mode_rounded,
                              title: 'Dark Mode',
                              trailing: Switch(
                                value: _darkMode,
                                onChanged: _onDarkModeChanged,
                              ),
                              onTap: () => _onDarkModeChanged(!_darkMode),
                            ),
                            SettingsTile(
                              icon: Icons.language_rounded,
                              title: 'Language',
                              subtitle: SettingsMockData.language,
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