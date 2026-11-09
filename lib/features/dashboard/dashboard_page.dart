import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/dashboard_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/profile_service.dart';
import '../../services/role_access_service.dart';
import '../activity_log/activity_logs_page.dart';
import '../alerts_page/alerts_page.dart';
import '../inventory/inventory_page.dart';
import '../inventory_item/inventory_item_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import 'data/dashboard_data.dart';
import 'widgets/full_dashboard_content.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const double _maxContentWidth = 1600;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _service = DashboardService();
  final ProfileService _profileService = ProfileService();
  final RoleAccessService _roleAccess = RoleAccessService.instance;
  DashboardData? _data;
  ProfileLookupResult? _profile;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    OfflineCacheService.instance.addListener(_onOfflineCacheChanged);
    _loadDashboard();
  }

  void _onOfflineCacheChanged() {
    if (OfflineCacheService.instance.lastChangedKey != 'dashboard.data') {
      return;
    }
    _refreshDashboardFromCache();
  }

  Future<void> _refreshDashboardFromCache() async {
    final data = await _service.readCachedDashboard();
    if (!mounted || data == null) return;
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    OfflineCacheService.instance.removeListener(_onOfflineCacheChanged);
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() {
      if (_data == null) _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _service.loadDashboard();
      if (!mounted) return;
      ProfileLookupResult? profile;
      String? profileError;
      try {
        profile = await _profileService.getCurrentProfile();
      } on ProfileServiceException catch (error) {
        profileError = error.message;
      }
      if (!mounted) return;
      _roleAccess.updateRole(profile?.role);
      setState(() {
        _data = data;
        _profile = profile;
        _isLoading = false;
      });
      if (profileError != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(profileError)));
      }
    } on DashboardServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load dashboard data: $error';
        _isLoading = false;
      });
    }
  }

  void _onNotificationsTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewAlerts,
          child: const AlertsPage(),
        ),
      ),
    );
  }

  Future<void> _onProfileTap(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoleAccessGuard(
          permission: AppPermission.viewSettings,
          child: const SettingsPage(),
        ),
      ),
    );
  }

  Future<void> _onQuickActionTap(
    BuildContext context,
    QuickActionItem action,
  ) async {
    switch (action.type) {
      case QuickActionType.addItem:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoleAccessGuard(
              permission: AppPermission.createInventory,
              child: const InventoryItemPage(),
            ),
          ),
        );
        if (mounted) await _loadDashboard();
      case QuickActionType.inventory:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoleAccessGuard(
              permission: AppPermission.viewInventory,
              child: const InventoryPage(),
            ),
          ),
        );
        if (mounted) await _loadDashboard();
      case QuickActionType.reports:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoleAccessGuard(
              permission: AppPermission.viewReports,
              child: const ReportsPage(),
            ),
          ),
        );
      case QuickActionType.activityLog:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RoleAccessGuard(
              permission: AppPermission.viewActivityLog,
              child: const ActivityLogsPage(),
            ),
          ),
        );
    }
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _userName {
    final profileName = _profile?.fullName?.trim();
    if (profileName?.isNotEmpty == true) return profileName!;
    final user = Supabase.instance.client.auth.currentUser;
    final metadataName =
        user?.userMetadata?['full_name'] as String? ??
        user?.userMetadata?['name'] as String?;
    if (metadataName?.trim().isNotEmpty == true) return metadataName!.trim();
    final email = user?.email;
    if (email != null && email.contains('@')) return email.split('@').first;
    return 'Inventory User';
  }

  String get _userInitials {
    final parts = _userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'IU';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final userRole = _profile?.role?.trim().isNotEmpty == true
        ? _profile!.role!.trim()
        : Supabase.instance.client.auth.currentUser?.userMetadata?['role']
                  as String? ??
              'Inventory workspace';
    final overlayStyle = Theme.of(context).brightness == Brightness.dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: DashboardPage._maxContentWidth,
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _errorMessage != null
                  ? _buildErrorState()
                  : RefreshIndicator(
                      onRefresh: _loadDashboard,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          MediaQuery.sizeOf(context).width > 1200 ? 32 : 20,
                          16,
                          20,
                          24 + bottomInset,
                        ),
                        child: _buildDashboard(context, _data!, userRole),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    DashboardData data,
    String userRole,
  ) {
    final visibleActions = dashboardQuickActions
        .where((action) {
          final permission = switch (action.type) {
            QuickActionType.addItem => AppPermission.createInventory,
            QuickActionType.inventory => AppPermission.viewInventory,
            QuickActionType.reports => AppPermission.viewReports,
            QuickActionType.activityLog => AppPermission.viewActivityLog,
          };
          return _roleAccess.allows(permission);
        })
        .toList(growable: false);

    void openActivityLogs() {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => RoleAccessGuard(
            permission: AppPermission.viewActivityLog,
            child: const ActivityLogsPage(),
          ),
        ),
      );
    }

    return FullDashboardContent(
      data: data,
      greeting: _greeting,
      name: _userName,
      role: userRole,
      initials: _userInitials,
      visibleActions: visibleActions,
      activityPermission: _roleAccess.allows(AppPermission.viewActivityLog),
      onNotificationsTap: () => _onNotificationsTap(context),
      onProfileTap: () => _onProfileTap(context),
      onActivityTap: openActivityLogs,
      onQuickActionTap: (action) => _onQuickActionTap(context, action),
    );
  }

  Widget _buildErrorState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton(onPressed: _loadDashboard, child: const Text('Retry')),
        ],
      ),
    ),
  );
}
