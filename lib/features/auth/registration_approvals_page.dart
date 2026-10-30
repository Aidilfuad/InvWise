import 'package:flutter/material.dart';

import '../../app/constants/app_colors.dart';
import '../../app/constants/app_spacing.dart';
import '../../services/registration_approval_service.dart';
import '../../services/role_access_service.dart';

class RegistrationApprovalsPage extends StatelessWidget {
  const RegistrationApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleAccessGuard(
      permission: AppPermission.manageRegistrationRequests,
      child: const _RegistrationApprovalsView(),
    );
  }
}

class _RegistrationApprovalsView extends StatefulWidget {
  const _RegistrationApprovalsView();

  @override
  State<_RegistrationApprovalsView> createState() =>
      _RegistrationApprovalsViewState();
}

class _RegistrationApprovalsViewState
    extends State<_RegistrationApprovalsView> {
  final _service = RegistrationApprovalService();
  List<RegistrationRequest> _requests = const [];
  String? _errorMessage;
  bool _isLoading = true;
  String? _updatingRequestId;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final requests = await _service.getPendingRequests();
      if (!mounted) return;
      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } on RegistrationApprovalServiceException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _updateStatus(
    RegistrationRequest request,
    RegistrationRequestStatus status,
  ) async {
    if (_updatingRequestId != null) return;
    setState(() => _updatingRequestId = request.id);
    try {
      await _service.updateRequestStatus(requestId: request.id, status: status);
      if (!mounted) return;
      setState(() {
        _requests = _requests.where((item) => item.id != request.id).toList();
        _updatingRequestId = null;
      });
      _showMessage(
        status == RegistrationRequestStatus.approved
            ? 'Registration request approved.'
            : 'Registration request rejected.',
      );
    } on RegistrationApprovalServiceException catch (error) {
      if (!mounted) return;
      setState(() => _updatingRequestId = null);
      _showMessage(error.message);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Registration Approvals'),
        backgroundColor: AppColors.surface,
        actions: [
          IconButton(
            tooltip: 'Refresh pending requests',
            onPressed: _isLoading || _updatingRequestId != null
                ? null
                : _loadRequests,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildError()
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: _requests.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      children: const [
                        SizedBox(height: 100),
                        Center(
                          child: Text('No pending registration requests.'),
                        ),
                      ],
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _requests.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) {
                        final request = _requests[index];
                        return _RequestCard(
                          request: request,
                          createdDate: _formatDate(request.createdAt),
                          isUpdating: _updatingRequestId == request.id,
                          onApprove: () => _updateStatus(
                            request,
                            RegistrationRequestStatus.approved,
                          ),
                          onReject: () => _updateStatus(
                            request,
                            RegistrationRequestStatus.rejected,
                          ),
                        );
                      },
                    ),
            ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          FilledButton(onPressed: _loadRequests, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.createdDate,
    required this.isUpdating,
    required this.onApprove,
    required this.onReject,
  });

  final RegistrationRequest request;
  final String createdDate;
  final bool isUpdating;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              request.fullName,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _RequestDetail(label: 'Employee ID', value: request.employeeId),
            _RequestDetail(label: 'Email', value: request.email),
            _RequestDetail(
              label: 'Department',
              value: request.department?.trim().isNotEmpty == true
                  ? request.department!
                  : '—',
            ),
            _RequestDetail(
              label: 'Requested Role',
              value: request.requestedRole,
            ),
            const _RequestDetail(label: 'Status', value: 'Pending'),
            _RequestDetail(label: 'Created Date', value: createdDate),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isUpdating ? null : onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton(
                    onPressed: isUpdating ? null : onApprove,
                    child: isUpdating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
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

class _RequestDetail extends StatelessWidget {
  const _RequestDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
