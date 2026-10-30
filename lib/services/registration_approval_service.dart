import 'package:supabase_flutter/supabase_flutter.dart';

import 'profile_service.dart';
import 'role_access_service.dart';

enum RegistrationRequestStatus { pending, approved, rejected }

class RegistrationRequest {
  const RegistrationRequest({
    required this.id,
    required this.fullName,
    required this.employeeId,
    required this.email,
    required this.requestedRole,
    required this.status,
    required this.createdAt,
    this.department,
  });

  final String id;
  final String fullName;
  final String employeeId;
  final String email;
  final String? department;
  final String requestedRole;
  final RegistrationRequestStatus status;
  final DateTime createdAt;

  factory RegistrationRequest.fromMap(Map<String, dynamic> map) {
    final status = switch (map['status']) {
      'pending' => RegistrationRequestStatus.pending,
      'approved' => RegistrationRequestStatus.approved,
      'rejected' => RegistrationRequestStatus.rejected,
      _ => throw const RegistrationApprovalServiceException(
        'The registration request has an invalid status.',
      ),
    };
    final createdAtValue = map['created_at'] as String?;
    if (createdAtValue == null) {
      throw const RegistrationApprovalServiceException(
        'The registration request has no creation date.',
      );
    }

    return RegistrationRequest(
      id: map['id'] as String,
      fullName: map['full_name'] as String,
      employeeId: map['employee_id'] as String,
      email: map['email'] as String,
      department: map['department'] as String?,
      requestedRole: map['requested_role'] as String,
      status: status,
      createdAt: DateTime.parse(createdAtValue),
    );
  }
}

class RegistrationApprovalServiceException implements Exception {
  const RegistrationApprovalServiceException(this.message);

  final String message;

  @override
  String toString() => 'RegistrationApprovalServiceException: $message';
}

class RegistrationApprovalService {
  RegistrationApprovalService({
    SupabaseClient? client,
    ProfileService? profileService,
    RoleAccessService? roleAccess,
  }) : _client = client ?? Supabase.instance.client,
       _profileService = profileService ?? ProfileService(),
       _roleAccess = roleAccess ?? RoleAccessService.instance;

  static const String _table = 'registration_requests';

  final SupabaseClient _client;
  final ProfileService _profileService;
  final RoleAccessService _roleAccess;

  Future<List<RegistrationRequest>> getPendingRequests() async {
    _requireAdmin();
    try {
      final rows = await _client
          .from(_table)
          .select(
            'id, full_name, employee_id, email, department, requested_role, '
            'status, created_at',
          )
          .eq('status', 'pending')
          .order('created_at', ascending: true);
      return rows
          .map(
            (row) =>
                RegistrationRequest.fromMap(Map<String, dynamic>.from(row)),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw RegistrationApprovalServiceException(
        _friendlyMessage(error, 'load registration requests'),
      );
    } on RegistrationApprovalServiceException {
      rethrow;
    } catch (error) {
      throw RegistrationApprovalServiceException(
        'Unable to load registration requests. $error',
      );
    }
  }

  Future<void> updateRequestStatus({
    required String requestId,
    required RegistrationRequestStatus status,
  }) async {
    if (status == RegistrationRequestStatus.pending) {
      throw const RegistrationApprovalServiceException(
        'A request can only be approved or rejected.',
      );
    }
    _requireAdmin();

    try {
      final profile = await _profileService.getCurrentProfile();
      if (profile == null) {
        throw const RegistrationApprovalServiceException(
          'Unable to identify the approving administrator.',
        );
      }
      final updated = await _client
          .from(_table)
          .update({
            'status': status.name,
            'approved_at': DateTime.now().toUtc().toIso8601String(),
            'approved_by': profile.id,
          })
          .eq('id', requestId)
          .eq('status', RegistrationRequestStatus.pending.name)
          .select('id')
          .maybeSingle();
      if (updated == null) {
        throw const RegistrationApprovalServiceException(
          'This request is no longer pending. Refresh the list and try again.',
        );
      }
    } on ProfileServiceException catch (error) {
      throw RegistrationApprovalServiceException(error.message);
    } on PostgrestException catch (error) {
      throw RegistrationApprovalServiceException(
        _friendlyMessage(error, 'update the registration request'),
      );
    } on RegistrationApprovalServiceException {
      rethrow;
    } catch (error) {
      throw RegistrationApprovalServiceException(
        'Unable to update the registration request. $error',
      );
    }
  }

  void _requireAdmin() {
    if (!_roleAccess.allows(AppPermission.manageRegistrationRequests)) {
      throw const RegistrationApprovalServiceException(
        'Only an Inventory Administrator can manage registration requests.',
      );
    }
  }

  String _friendlyMessage(PostgrestException error, String action) {
    if (error.code == '42501' ||
        error.message.toLowerCase().contains('row-level security')) {
      return 'You do not have permission to $action.';
    }
    return 'Unable to $action. ${error.message}';
  }
}
