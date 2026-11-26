import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/constants/app_colors.dart';
import '../../services/profile_service.dart';
import '../../services/workspace_access_service.dart';
import '../../widgets/searchable_dropdown_form_field.dart';

const _noRoleChange = 'No role change';
const _noDepartmentChange = 'No department change';

bool _canReview(String? role) {
  final normalized = role?.trim().toLowerCase().replaceAll(
    RegExp(r'[_-]+'),
    ' ',
  );
  return {
    'manager',
    'factory 1 manager',
    'factory 2 manager',
    'warehouse manager',
    'director',
    'super admin',
  }.contains(normalized);
}

class ProfileChangeRequestsPage extends StatefulWidget {
  const ProfileChangeRequestsPage({super.key});

  @override
  State<ProfileChangeRequestsPage> createState() =>
      _ProfileChangeRequestsPageState();
}

class _ProfileChangeRequestsPageState extends State<ProfileChangeRequestsPage> {
  final _client = Supabase.instance.client;
  final _profileService = ProfileService();
  final _accessService = WorkspaceAccessService();
  final _reasonController = TextEditingController();
  final _reviewNoteController = TextEditingController();
  ProfileLookupResult? _profile;
  List<String> _roles = const [];
  List<String> _departments = const [];
  List<Map<String, dynamic>> _requests = const [];
  String _requestedRole = _noRoleChange;
  String _requestedDepartment = _noDepartmentChange;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _statusMessage;

  bool get _isApprover => _canReview(_profile?.role);

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _reviewNoteController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) throw StateError('No signed-in workspace profile.');
      final roles = await _accessService.getRoles();
      final departments = await _accessService.getDepartments();
      final rows = await _client
          .from('profile_change_requests')
          .select(
            'id,profile_id,profile_name,previous_role,requested_role,'
            'current_department,requested_department,reason,status,'
            'created_at,review_note',
          )
          .order('created_at', ascending: false)
          .limit(100);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _roles = roles
            .map((role) => role.name)
            .where((role) => role != 'Super Admin')
            .toList(growable: false);
        _departments = departments
            .map((department) => department.name)
            .toList(growable: false);
        _requests = rows.map((row) => Map<String, dynamic>.from(row)).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load role and department requests: $error';
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final profile = _profile;
    final reason = _reasonController.text.trim();
    if (profile == null || _isSubmitting) return;
    if (reason.isEmpty) {
      setState(() => _errorMessage = 'Enter a reason for your request.');
      return;
    }
    if (
        (_requestedRole == _noRoleChange &&
            _requestedDepartment == _noDepartmentChange)
    ) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });
    try {
      await _client.rpc(
        'submit_profile_change_request',
        params: {
          'p_requested_role': _requestedRole == _noRoleChange
              ? null
              : _requestedRole,
          'p_requested_department':
              _requestedDepartment == _noDepartmentChange
              ? null
              : _requestedDepartment,
          'p_reason': reason,
        },
      );
      _reasonController.clear();
      if (!mounted) return;
      setState(() {
        _requestedRole = _noRoleChange;
        _requestedDepartment = _noDepartmentChange;
        _statusMessage = 'Your request was submitted for Manager-and-above approval.';
      });
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _errorMessage = 'Unable to submit your profile change request: $error',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _review(String requestId, String decision) async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _statusMessage = null;
    });
    try {
      await _client.rpc(
        'review_profile_change_request',
        params: {
          'p_request_id': requestId,
          'p_decision': decision,
          'p_review_note': _reviewNoteController.text.trim().isEmpty
              ? null
              : _reviewNoteController.text.trim(),
        },
      );
      _reviewNoteController.clear();
      if (!mounted) return;
      setState(() => _statusMessage = 'Request $decision.');
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Unable to review this request: $error');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final ownRequests = _requests
        .where((request) => request['profile_id'] == profile?.id)
        .toList(growable: false);
    final pendingRequests = _isApprover
        ? _requests
              .where((request) => request['status'] == 'pending')
              .toList(growable: false)
        : const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Role & Department Requests')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request a profile change',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Current role: ${profile?.role ?? 'Unknown'} · '
                          'Department: ${profile?.department ?? 'Not set'}',
                        ),
                        const SizedBox(height: 16),
                        SearchableDropdownFormField(
                          key: ValueKey(_requestedRole),
                          initialValue: _requestedRole,
                          options: [_noRoleChange, ..._roles],
                          decoration: const InputDecoration(
                            labelText: 'Requested role',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSubmitting,
                          onChanged: (value) => setState(
                            () => _requestedRole = value ?? _noRoleChange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SearchableDropdownFormField(
                          key: ValueKey(_requestedDepartment),
                          initialValue: _requestedDepartment,
                          options: [_noDepartmentChange, ..._departments],
                          decoration: const InputDecoration(
                            labelText: 'Requested department',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_isSubmitting,
                          onChanged: (value) => setState(
                            () => _requestedDepartment =
                                value ?? _noDepartmentChange,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reasonController,
                          enabled: !_isSubmitting,
                          maxLength: 1000,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Reason / notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            onPressed:
                                _isSubmitting ||
                                    (_requestedRole == _noRoleChange &&
                                        _requestedDepartment ==
                                            _noDepartmentChange)
                                ? null
                                : _submit,
                            child: Text(
                              _isSubmitting ? 'Submitting…' : 'Submit request',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_errorMessage != null)
                  _MessageCard(message: _errorMessage!, isError: true),
                if (_statusMessage != null)
                  _MessageCard(message: _statusMessage!, isError: false),
                const SizedBox(height: 8),
                _RequestList(
                  title: 'Your requests',
                  requests: ownRequests,
                  profile: profile,
                  reviewNoteController: _reviewNoteController,
                  isApprover: false,
                  isSubmitting: _isSubmitting,
                  onReview: _review,
                ),
                if (_isApprover) ...[
                  const SizedBox(height: 12),
                  _RequestList(
                    title: 'Pending approval',
                    requests: pendingRequests,
                    profile: profile,
                    reviewNoteController: _reviewNoteController,
                    isApprover: true,
                    isSubmitting: _isSubmitting,
                    onReview: _review,
                  ),
                ],
              ],
            ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.title,
    required this.requests,
    required this.profile,
    required this.reviewNoteController,
    required this.isApprover,
    required this.isSubmitting,
    required this.onReview,
  });

  final String title;
  final List<Map<String, dynamic>> requests;
  final ProfileLookupResult? profile;
  final TextEditingController reviewNoteController;
  final bool isApprover;
  final bool isSubmitting;
  final Future<void> Function(String id, String decision) onReview;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (isApprover && requests.isNotEmpty) ...[
            const SizedBox(height: 12),
            TextField(
              controller: reviewNoteController,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Review note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (requests.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('No requests to display.'),
            )
          else
            for (final request in requests)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${request['profile_name'] ?? 'Workspace user'} · '
                  '${request['previous_role']} → ${request['requested_role']}',
                ),
                subtitle: Text(
                  '${request['current_department'] ?? 'No department'} → '
                  '${request['requested_department'] ?? 'No department'}\n'
                  '${request['reason']}\n'
                  '${request['status']} · ${request['created_at']}'
                  '${request['review_note'] == null ? '' : '\nReview note: ${request['review_note']}'}',
                ),
                isThreeLine: true,
                trailing: isApprover
                    ? Wrap(
                        spacing: 4,
                        children: [
                          IconButton(
                            tooltip: 'Approve request',
                            onPressed: isSubmitting ||
                                    request['profile_id'] == profile?.id
                                ? null
                                : () => onReview(
                                    request['id'] as String,
                                    'approved',
                                  ),
                            icon: const Icon(Icons.check_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Reject request',
                            onPressed: isSubmitting ||
                                    request['profile_id'] == profile?.id
                                ? null
                                : () => onReview(
                                    request['id'] as String,
                                    'rejected',
                                  ),
                            icon: const Icon(Icons.cancel_outlined),
                          ),
                        ],
                      )
                    : Text('${request['status']}'),
              ),
        ],
      ),
    ),
  );
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message, required this.isError});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) => Card(
    color: isError ? Colors.red.shade50 : Colors.green.shade50,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Text(message),
    ),
  );
}
