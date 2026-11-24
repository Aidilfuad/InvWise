import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecuritySessionTracker with WidgetsBindingObserver {
  SecuritySessionTracker._();

  static final SecuritySessionTracker instance = SecuritySessionTracker._();

  final SupabaseClient _client = Supabase.instance.client;
  Timer? _timer;
  String? _sessionRowId;
  String? get currentSessionRowId => _sessionRowId;
  bool _isUpdating = false;
  bool _isObserving = false;

  void start(String sessionRowId) {
    stop();
    _sessionRowId = sessionRowId;
    WidgetsBinding.instance.addObserver(this);
    _isObserving = true;
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _touchSession());
    _touchSession();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _sessionRowId = null;
    if (_isObserving) {
      WidgetsBinding.instance.removeObserver(this);
      _isObserving = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _touchSession();
    }
  }

  Future<void> _touchSession() async {
    final sessionRowId = _sessionRowId;
    if (sessionRowId == null ||
        _isUpdating ||
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return;
    }
    _isUpdating = true;
    final now = DateTime.now().toUtc().toIso8601String();
    try {
      final updatedRow = await _client
          .from('device_sessions')
          .update({'last_active_at': now, 'updated_at': now})
          .eq('id', sessionRowId)
          .isFilter('revoked_at', null)
          .select('id')
          .maybeSingle();
      if (updatedRow == null) {
        debugPrint(
          '[SecuritySessionTracker] No active device session row was '
          'updated for the current session.',
        );
      }
    } on PostgrestException catch (error) {
      debugPrint(
        '[SecuritySessionTracker] Unable to update active session: '
        '${error.message}',
      );
    } catch (error) {
      debugPrint(
        '[SecuritySessionTracker] Unable to update active session: $error',
      );
    } finally {
      _isUpdating = false;
    }
  }
}
