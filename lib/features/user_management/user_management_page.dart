import 'package:flutter/material.dart';

import '../../app/constants/app_spacing.dart';
import '../../services/role_access_service.dart';
import '../../services/password_confirmation_service.dart';
import '../../services/user_management_service.dart';
import '../../widgets/profile_avatar.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) => RoleAccessGuard(
    permission: AppPermission.manageUsers,
    child: const _UserManagementContent(),
  );
}

class _UserManagementContent extends StatefulWidget {
  const _UserManagementContent();

  @override
  State<_UserManagementContent> createState() => _UserManagementContentState();
}

class _UserManagementContentState extends State<_UserManagementContent> {
  final UserManagementService _service = UserManagementService();
  final TextEditingController _searchController = TextEditingController();
  List<ManagedUser> _users = const [];
  final Set<String> _updatingUserIds = {};
  String? _selectedRole;
  bool? _selectedStatus;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final users = await _service.getUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } on UserManagementServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load users. $error';
        _isLoading = false;
      });
    }
  }

  List<ManagedUser> get _filteredUsers => _users
      .where(
        (user) => user.matches(
          query: _searchController.text,
          roleFilter: _selectedRole,
          activeFilter: _selectedStatus,
        ),
      )
      .toList(growable: false);

  Future<void> _changeRole(ManagedUser user) async {
    var selectedRole = user.role;
    final role = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Change user role'),
          content: DropdownButtonFormField<String>(
            initialValue: selectedRole,
            decoration: const InputDecoration(labelText: 'Role'),
            items: [
              for (final role in ManagedUser.roles)
                DropdownMenuItem(value: role, child: Text(role)),
            ],
            onChanged: (value) {
              if (value != null) {
                setDialogState(() => selectedRole = value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, selectedRole),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (role == null || role == user.role || !mounted) return;
    if (!await PasswordConfirmationService.confirm(
      context,
      action: 'change this user role',
    )) {
      return;
    }
    await _runUserUpdate(
      user,
      () => _service.changeRole(
        userId: user.id,
        role: role,
        userName: user.fullName,
        oldRole: user.role,
      ),
      'User role updated.',
    );
  }

  Future<void> _toggleActive(ManagedUser user) async {
    final activate = !user.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(activate ? 'Activate account?' : 'Deactivate account?'),
        content: Text(
          activate
              ? 'Allow ${user.fullName} to sign in and use InvWise?'
              : 'Block ${user.fullName} from signing in to InvWise?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(activate ? 'Activate' : 'Deactivate'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runUserUpdate(
      user,
      () => _service.setActive(
        userId: user.id,
        isActive: activate,
        userName: user.fullName,
      ),
      activate ? 'Account activated.' : 'Account deactivated.',
    );
  }

  Future<void> _runUserUpdate(
    ManagedUser user,
    Future<void> Function() update,
    String successMessage,
  ) async {
    setState(() => _updatingUserIds.add(user.id));
    try {
      await update();
      await _loadUsers();
      if (!mounted) return;
      final refreshError = _errorMessage;
      _showMessage(
        refreshError == null
            ? successMessage
            : 'Account updated, but the list could not be refreshed. '
                  '$refreshError',
      );
    } on UserManagementServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (error) {
      if (mounted) _showMessage('Unable to update this account. $error');
    } finally {
      if (mounted) setState(() => _updatingUserIds.remove(user.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatLastLogin(BuildContext context, DateTime? lastLogin) {
    if (lastLogin == null) return 'Never';
    final local = lastLogin.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(local));
    return '$date, $time';
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            tooltip: 'Refresh users',
            onPressed: _isLoading ? null : _loadUsers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1600),
          child: _isLoading && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null && _users.isEmpty
              ? _LoadError(message: _errorMessage!, onRetry: _loadUsers)
              : RefreshIndicator(
                  onRefresh: _loadUsers,
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    children: [
                      Text(
                        'Users',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Search accounts, review access, and manage roles.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Search users',
                          hintText: 'Name, email, employee ID, or role',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          SizedBox(
                            width: 260,
                            child: DropdownButtonFormField<String?>(
                              initialValue: _selectedRole,
                              decoration: const InputDecoration(
                                labelText: 'Filter by role',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  child: Text('All roles'),
                                ),
                                for (final role in ManagedUser.roles)
                                  DropdownMenuItem<String?>(
                                    value: role,
                                    child: Text(role),
                                  ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedRole = value),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<bool?>(
                              initialValue: _selectedStatus,
                              decoration: const InputDecoration(
                                labelText: 'Filter by status',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem<bool?>(
                                  child: Text('All statuses'),
                                ),
                                DropdownMenuItem<bool?>(
                                  value: true,
                                  child: Text('Active'),
                                ),
                                DropdownMenuItem<bool?>(
                                  value: false,
                                  child: Text('Inactive'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _selectedStatus = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Text(
                            '${filteredUsers.length} '
                            '${filteredUsers.length == 1 ? 'user' : 'users'}',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          if (_isLoading) ...[
                            const SizedBox(width: AppSpacing.sm),
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        ],
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      if (filteredUsers.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(AppSpacing.xxl),
                          child: Text(
                            _users.isEmpty
                                ? 'No user accounts found.'
                                : 'No users match these filters.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (MediaQuery.sizeOf(context).width > 1200)
                        _usersTable(filteredUsers, compact: false)
                      else if (MediaQuery.sizeOf(context).width >= 600)
                        _usersTable(filteredUsers, compact: true)
                      else
                        for (final user in filteredUsers) _userCard(user),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _usersTable(
    List<ManagedUser> users, {
    required bool compact,
  }) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: DataTable(
      columnSpacing: compact ? 20 : 32,
      columns: compact
          ? const [
              DataColumn(label: Text('User')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Account')),
              DataColumn(label: Text('Actions')),
            ]
          : const [
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Employee ID')),
              DataColumn(label: Text('Role')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Last login')),
              DataColumn(label: Text('Actions')),
            ],
      rows: [
        for (final user in users)
          DataRow(
            cells: compact
                ? [
                    DataCell(
                      SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [_userIdentity(user, includeEmail: true)],
                        ),
                      ),
                    ),
                    DataCell(Text(user.role)),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(user.isActive ? 'Active' : 'Inactive'),
                          Text(
                            _formatLastLogin(context, user.lastLoginAt),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    DataCell(_userActions(user)),
                  ]
                : [
                    DataCell(_userIdentity(user, includeEmail: false)),
                    DataCell(SelectableText(user.email)),
                    DataCell(Text(user.employeeId ?? '—')),
                    DataCell(Text(user.role)),
                    DataCell(_StatusBadge(isActive: user.isActive)),
                    DataCell(Text(_formatLastLogin(context, user.lastLoginAt))),
                    DataCell(_userActions(user)),
                  ],
          ),
      ],
    ),
  );

  Widget _userActions(ManagedUser user) {
    final isUpdating = _updatingUserIds.contains(user.id);
    if (isUpdating) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Change role',
          onPressed: user.isSelf ? null : () => _changeRole(user),
          icon: const Icon(Icons.manage_accounts_outlined),
        ),
        IconButton(
          tooltip: user.isActive ? 'Deactivate' : 'Activate',
          onPressed: user.isSelf ? null : () => _toggleActive(user),
          icon: Icon(
            user.isActive
                ? Icons.person_off_outlined
                : Icons.person_add_alt_1_outlined,
          ),
        ),
      ],
    );
  }

  Widget _userIdentity(ManagedUser user, {required bool includeEmail}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ProfileAvatar(
        name: user.fullName.isEmpty ? user.email : user.fullName,
        avatarUrl: user.avatarUrl,
        size: 32,
      ),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (includeEmail)
              Text(
                user.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
      ),
    ],
  );

  Widget _userCard(ManagedUser user) {
    final theme = Theme.of(context);
    final isUpdating = _updatingUserIds.contains(user.id);
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProfileAvatar(
                  name: user.fullName.isEmpty ? user.email : user.fullName,
                  avatarUrl: user.avatarUrl,
                  size: 44,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName.isEmpty ? 'Unnamed user' : user.fullName,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      SelectableText(user.email),
                    ],
                  ),
                ),
                _StatusBadge(isActive: user.isActive),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xl,
              runSpacing: AppSpacing.sm,
              children: [
                _UserDetail(
                  label: 'Employee ID',
                  value: user.employeeId?.isNotEmpty == true
                      ? user.employeeId!
                      : '—',
                ),
                _UserDetail(label: 'Role', value: user.role),
                _UserDetail(
                  label: 'Last login',
                  value: _formatLastLogin(context, user.lastLoginAt),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: isUpdating || user.isSelf
                      ? null
                      : () => _changeRole(user),
                  icon: const Icon(Icons.manage_accounts_outlined),
                  label: const Text('Change role'),
                ),
                FilledButton.tonalIcon(
                  onPressed: isUpdating || user.isSelf
                      ? null
                      : () => _toggleActive(user),
                  icon: Icon(
                    user.isActive
                        ? Icons.person_off_outlined
                        : Icons.person_add_alt_1_outlined,
                  ),
                  label: Text(user.isActive ? 'Deactivate' : 'Activate'),
                ),
                if (isUpdating)
                  const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
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
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(
      isActive ? Icons.check_circle_outline : Icons.block_outlined,
      size: 18,
    ),
    label: Text(isActive ? 'Active' : 'Inactive'),
    visualDensity: VisualDensity.compact,
  );
}

class _UserDetail extends StatelessWidget {
  const _UserDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: Theme.of(context).textTheme.labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
      Text(value, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}
