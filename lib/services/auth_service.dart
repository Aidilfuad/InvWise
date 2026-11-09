import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_tracking_service.dart';
import 'login_preferences_service.dart';
import 'security_session_tracker.dart';
import 'system_activity_log_service.dart';

/// Error thrown by [AuthService] with a message that is safe to show in the UI.
class AuthServiceException implements Exception {
  const AuthServiceException(this.message);

  final String message;

  @override
  String toString() => 'AuthServiceException: $message';
}

/// Thin wrapper around Supabase Auth. UI code should use this class instead
/// of calling Supabase directly.
class AuthService {
  AuthService({
    LoginTrackingService? loginTrackingService,
    SupabaseClient? client,
    LoginPreferencesService? loginPreferencesService,
  }) : _client = client ?? Supabase.instance.client,
       _loginTrackingService = loginTrackingService ?? LoginTrackingService(),
       _loginPreferences =
           loginPreferencesService ?? LoginPreferencesService.instance,
       _activityLog = SystemActivityLogService(
         client: client ?? Supabase.instance.client,
       );

  final SupabaseClient _client;
  final LoginTrackingService _loginTrackingService;
  final LoginPreferencesService _loginPreferences;
  final SystemActivityLogService _activityLog;

  String? lastTrackingWarning;

  /// Signs in with an email or resolves an employee ID to its account email.
  ///
  /// Supabase Auth always receives an email and the supplied password.
  Future<User?> signInWithIdentifier({
    required String identifier,
    required String password,
    bool rememberMe = false,
  }) async {
    final trimmedIdentifier = identifier.trim();
    if (trimmedIdentifier.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Please enter your Employee ID or email and password.',
      );
    }
    if (trimmedIdentifier.contains('@') && !_isValidEmail(trimmedIdentifier)) {
      throw const AuthServiceException(
        'Enter a valid Employee ID or email address.',
      );
    }
    if (_isValidEmail(trimmedIdentifier)) {
      return signInWithEmail(
        email: trimmedIdentifier,
        password: password,
        rememberMe: rememberMe,
      );
    }

    String? email;
    try {
      final response = await _client.rpc(
        'resolve_login_email_by_employee_id',
        params: {'p_employee_id': trimmedIdentifier},
      );
      if (response is String) email = response;
    } catch (error) {
      debugPrint('[AuthService] Employee ID lookup failed: $error');
      throw const AuthServiceException(
        'Unable to verify your Employee ID. Check your connection and try '
        'again.',
      );
    }

    final resolvedEmail = email?.trim();
    if (resolvedEmail == null || !_isValidEmail(resolvedEmail)) {
      throw const AuthServiceException(
        'Invalid Employee ID/email or password.',
      );
    }
    return signInWithEmail(
      email: resolvedEmail,
      password: password,
      rememberMe: rememberMe,
      attemptedIdentifier: trimmedIdentifier,
      employeeId: trimmedIdentifier,
    );
  }

  /// Signs in with [email] and [password].
  ///
  /// Returns the signed-in [User], or null if Supabase returned no user.
  /// Throws [AuthServiceException] on invalid input or failure.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
    bool rememberMe = false,
    String? attemptedIdentifier,
    String? employeeId,
  }) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Please enter your Employee ID or email and password.',
      );
    }

    lastTrackingWarning = null;

    try {
      final response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      final user = response.user;
      if (user != null) {
        try {
          await _loginPreferences.rememberLogin(
            email: trimmedEmail,
            enabled: rememberMe,
            employeeId: employeeId,
          );
        } catch (error) {
          lastTrackingWarning =
              'Your login succeeded, but the Remember Me preference could '
              'not be saved.';
          debugPrint('[AuthService] Unable to save login preference: $error');
        }
        try {
          await _loginTrackingService.recordSuccessfulLogin();
        } catch (error) {
          lastTrackingWarning =
              'Your login succeeded, but security activity could not be '
              'recorded.';
          debugPrint(
            '[AuthService] Unable to record successful login activity: '
            '$error',
          );
        }
        try {
          await _activityLog.record(
            category: 'Login',
            action: 'Signed in',
            description: 'Successful sign-in.',
            entityType: 'auth_user',
            entityId: user.id,
          );
        } catch (error) {
          debugPrint('[AuthService] Unable to record login activity: $error');
        }
      }
      return user;
    } on AuthException catch (e) {
      await _recordFailedLogin(
        attemptedIdentifier ?? trimmedEmail,
        _friendlyMessage(e),
      );
      throw AuthServiceException(_friendlyMessage(e));
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[AUTH-DEBUG] non-auth error type=${e.runtimeType}');
        debugPrint('$st');
      }
      await _recordFailedLogin(
        attemptedIdentifier ?? trimmedEmail,
        'Unable to authenticate because of a connection or service error.',
      );
      throw const AuthServiceException(
        'Unable to sign in. Please check your connection and try again.',
      );
    }
  }

  /// Signs out the current user and clears the stored session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      await _loginPreferences.clearStoredIdentity();
      SecuritySessionTracker.instance.stop();
    } on AuthException catch (e) {
      throw AuthServiceException(_friendlyMessage(e));
    } catch (_) {
      throw const AuthServiceException('Unable to sign out. Please try again.');
    }
  }

  Future<void> _recordFailedLogin(
    String attemptedIdentifier,
    String failureReason,
  ) async {
    try {
      await _loginTrackingService.recordFailedLogin(
        attemptedIdentifier: attemptedIdentifier,
        failureReason: failureReason,
      );
    } catch (error) {
      lastTrackingWarning =
          'The failed login attempt could not be recorded in security history.';
      debugPrint(
        '[AuthService] Unable to record failed login activity: $error',
      );
    }
  }

  /// Sends a password recovery email to [email].
  Future<void> resetPasswordForEmail(String email) async {
    final trimmedEmail = email.trim();
    if (!_isValidEmail(trimmedEmail)) {
      throw const AuthServiceException('Enter a valid email address.');
    }

    try {
      await _client.auth.resetPasswordForEmail(trimmedEmail);
    } on AuthRetryableFetchException {
      throw const AuthServiceException(
        'Network error. Check your connection and try again.',
      );
    } on AuthException catch (error) {
      throw AuthServiceException(_passwordResetError(error));
    } catch (_) {
      throw const AuthServiceException(
        'Network error. Check your connection and try again.',
      );
    }
  }

  /// Verifies the current password, then changes it for the signed-in user.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _client.auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw const AuthServiceException(
        'Your account email is unavailable. Sign in again and retry.',
      );
    }

    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AuthServiceException('Current password is incorrect.');
      }
      throw AuthServiceException(_friendlyMessage(e));
    } catch (_) {
      throw const AuthServiceException(
        'Unable to verify your current password. Please try again.',
      );
    }

    try {
      await _client.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw AuthServiceException(_friendlyMessage(e));
    } catch (_) {
      throw const AuthServiceException(
        'Unable to change your password. Please try again.',
      );
    }
  }

  /// The currently signed-in user, or null if nobody is signed in.
  User? getCurrentUser() => _client.auth.currentUser;

  /// The current session, or null if nobody is signed in.
  Session? getCurrentSession() => _client.auth.currentSession;

  /// True when a session exists.
  bool get isLoggedIn => _client.auth.currentSession != null;

  String _friendlyMessage(AuthException e) {
    final message = e.message.toLowerCase();

    if (message.contains('invalid login credentials')) {
      return 'Invalid Employee ID/email or password.';
    }
    if (message.contains('email not confirmed')) {
      return 'Your email has not been confirmed yet.';
    }
    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return 'Authentication failed. Please try again.';
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);

  String _passwordResetError(AuthException error) {
    final message = error.message.toLowerCase();
    if (message.contains('email') &&
        (message.contains('invalid') || message.contains('valid'))) {
      return 'Enter a valid email address.';
    }
    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Too many requests. Wait a moment and try again.';
    }
    return 'Unable to send the password reset email. Please try again.';
  }
}
