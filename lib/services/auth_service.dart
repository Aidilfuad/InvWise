import 'package:flutter/foundation.dart'; // TEMP-DEBUG
import 'package:supabase_flutter/supabase_flutter.dart';

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
  AuthService();

  final SupabaseClient _client = Supabase.instance.client;

  /// Signs in with [email] and [password].
  ///
  /// Returns the signed-in [User], or null if Supabase returned no user.
  /// Throws [AuthServiceException] on invalid input or failure.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const AuthServiceException(
        'Please enter your email and password.',
      );
    }

    if (kDebugMode) {
      // TEMP-DEBUG
      debugPrint('[AUTH-DEBUG] signInWithPassword start: '
          'email="$trimmedEmail" passwordLength=${password.length}');
    }

    try {
      final response = await _client.auth.signInWithPassword(
        email: trimmedEmail,
        password: password,
      );
      if (kDebugMode) {
        // TEMP-DEBUG
        debugPrint('[AUTH-DEBUG] success: userId=${response.user?.id} '
            'sessionNull=${response.session == null}');
      }
      return response.user;
    } on AuthException catch (e) {
      if (kDebugMode) {
        // TEMP-DEBUG
        debugPrint('[AUTH-DEBUG] AuthException type=${e.runtimeType} '
            'status=${e.statusCode} message="${e.message}"');
        debugPrint('[AUTH-DEBUG] mapped to: "${_friendlyMessage(e)}"');
      }
      throw AuthServiceException(_friendlyMessage(e));
    } catch (e, st) { // TEMP-DEBUG (was: catch (_))
      if (kDebugMode) {
        // TEMP-DEBUG
        debugPrint('[AUTH-DEBUG] non-auth error type=${e.runtimeType} '
            'error=$e');
        debugPrint('$st');
      }
      throw const AuthServiceException(
        'Unable to sign in. Please check your connection and try again.',
      );
    }
  }

  /// Signs out the current user and clears the stored session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } on AuthException catch (e) {
      throw AuthServiceException(_friendlyMessage(e));
    } catch (_) {
      throw const AuthServiceException(
        'Unable to sign out. Please try again.',
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
      return 'Invalid email or password.';
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
}