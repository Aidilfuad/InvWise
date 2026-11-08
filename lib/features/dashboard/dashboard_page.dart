import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/dashboard_service.dart';
import '../../services/dashboard_preferences_service.dart';
import '../../services/offline_cache_service.dart';
import '../../services/profile_service.dart';
import '../../services/role_access_service.dart';
import '../../widgets/offline_sync_indicator.dart';
import '../activity_log/activity_log_page.dart';
import '../activity_log/activity_logs_page.dart';
import '../alerts_page/alerts_page.dart';
import '../inventory/inventory_page.dart';
import '../inventory_item/inventory_item_page.dart';
import '../reports/reports_page.dart';
import '../settings/settings_page.dart';
import 'data/dashboard_data.dart';
import 'widgets/attention_required_card.dart';
import 'widgets/dashboard_home_header.dart';
import 'widgets/dashboard_section_header.dart';
import 'widgets/full_dashboard_content.dart';
import 'widgets/inventory_overview_card.dart';
import 'widgets/inventory_health_card.dart';
import 'widgets/kpi_grid.dart';
import 'widgets/monthly_insights_card.dart';
import 'widgets/quick_actions_grid.dart';
import 'widgets/recent_activity_card.dart';
import 'widgets/recent_system_activity_card.dart';
import 'widgets/sensor_monitoring_card.dart';
import 'widgets/system_alerts_card.dart';
import 'widgets/system_health_summary_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  static const double _maxContentWidth = 1600;
  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1200;

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
    DashboardPreferencesService.instance.addListener(
      _onDashboardPreferenceChanged,
    );
    _loadDashboard();
  }

  void _onOfflineCacheChanged() {
    if (OfflineCacheService.instance.lastChangedKey != 'dashboard.data') {
      return;
    }
    _refreshDashboardFromCache();
  }

  void _onDashboardPreferenceChanged() {
    if (mounted) setState(() {});
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
    DashboardPreferencesService.instance.removeListener(
      _onDashboardPreferenceChanged,
    );
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
        if (profile != null) {
          await DashboardPreferencesService.instance.loadForProfile(profile.id);
        }
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
                          MediaQuery.sizeOf(context).width >
                                  DashboardPage.desktopBreakpoint
                              ? 32
                              : 20,
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth < DashboardPage.mobileBreakpoint
            ? 1
            : constraints.maxWidth <= DashboardPage.desktopBreakpoint
            ? 2
            : 3;
        final compact = DashboardPreferencesService.instance.compactCards;
        final verticalGap = compact ? AppSpacing.sm : AppSpacing.md;
        final spacing = compact
            ? AppSpacing.sm
            : columns == 1
            ? AppSpacing.lg
            : AppSpacing.md;
        final tileWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        final activityPermission = _roleAccess.allows(
          AppPermission.viewActivityLog,
        );
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

        if (!compact) {
          return FullDashboardContent(
            data: data,
            greeting: _greeting,
            name: _userName,
            role: userRole,
            initials: _userInitials,
            visibleActions: visibleActions,
            activityPermission: activityPermission,
            onNotificationsTap: () => _onNotificationsTap(context),
            onProfileTap: () => _onProfileTap(context),
            onActivityTap: openActivityLogs,
            onQuickActionTap: (action) => _onQuickActionTap(context, action),
          );
        }

        final sections = <Widget>[
          _dashboardTile(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InventoryOverviewCard(summary: data, compact: compact),
                SizedBox(height: compact ? 6 : AppSpacing.md),
                KpiGrid(stats: data.kpis, compact: compact),
              ],
            ),
            tileWidth,
          ),
          _dashboardTile(
            InventoryHealthCard(summary: data.summary, compact: compact),
            tileWidth,
          ),
          _dashboardTile(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'Attention Required',
                  actionLabel: 'View Alerts',
                  onActionTap: () => _onNotificationsTap(context),
                  compact: compact,
                ),
                SizedBox(height: verticalGap),
                AttentionRequiredCard(
                  items: data.attentionItems,
                  compact: compact,
                ),
              ],
            ),
            tileWidth,
          ),
          SizedBox(
            width: tileWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'System Alerts',
                  compact: compact,
                ),
                SizedBox(height: verticalGap),
                SystemAlertsCard(compact: compact),
              ],
            ),
          ),
          _dashboardTile(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'Recent Activity',
                  actionLabel: activityPermission ? 'View All' : null,
                  onActionTap: activityPermission ? openActivityLogs : null,
                  compact: compact,
                ),
                SizedBox(height: verticalGap),
                RecentSystemActivityCard(
                  entries: data.systemActivities,
                  compact: compact,
                ),
              ],
            ),
            tileWidth,
          ),
          SizedBox(
            width: constraints.maxWidth,
            child: SensorMonitoringCard(compact: compact),
          ),
          _dashboardTile(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DashboardSectionHeader(
                  title: 'Live Inventory Summary',
                  compact: compact,
                ),
                SizedBox(height: verticalGap),
                MonthlyInsightsCard(
                  month: data.insightsMonth,
                  range: 'Current totals',
                  insights: data.insights,
                  compact: compact,
                ),
              ],
            ),
            tileWidth,
          ),
          _dashboardTile(SystemHealthSummaryCard(compact: compact), tileWidth),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OfflineSyncIndicator(),
            DashboardHomeHeader(
              greeting: _greeting,
              name: _userName,
              role: userRole,
              initials: _userInitials,
              onNotificationsTap: () => _onNotificationsTap(context),
              onProfileTap: () => _onProfileTap(context),
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            Wrap(spacing: spacing, runSpacing: spacing, children: sections),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            DashboardSectionHeader(
              title: 'Recent Stock Movements',
              compact: compact,
              actionLabel: activityPermission ? 'View All' : null,
              onActionTap: activityPermission
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RoleAccessGuard(
                          permission: AppPermission.viewActivityLog,
                          child: const ActivityLogPage(),
                        ),
                      ),
                    )
                  : null,
            ),
            SizedBox(height: verticalGap),
            RecentActivityCard(
              dateLabel: 'LATEST MOVEMENTS',
              entries: data.recentMovements,
              compact: compact,
            ),
            SizedBox(height: compact ? AppSpacing.md : AppSpacing.xl),
            DashboardSectionHeader(title: 'Quick Actions', compact: compact),
            SizedBox(height: verticalGap),
            QuickActionsGrid(
              actions: visibleActions,
              onActionTap: (action) => _onQuickActionTap(context, action),
              compact: compact,
            ),
          ],
        );
      },
    );
  }

  Widget _dashboardTile(Widget child, double width) =>
      SizedBox(width: width, child: child);

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
