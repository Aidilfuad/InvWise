import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum OfflineSyncState { starting, syncing, synced, offline, cacheUnavailable }

class OfflineCacheService extends ChangeNotifier with WidgetsBindingObserver {
  OfflineCacheService._();

  static final OfflineCacheService instance = OfflineCacheService._();
  static const String _boxName = 'invwise_offline_cache';
  static const int _maxEntryBytes = 8 * 1024 * 1024;
  static const int _maxCacheBytes = 32 * 1024 * 1024;
  static const int _maxBoxEntries = 64;

  Box<String>? _box;
  final Map<String, String> _memoryCache = {};
  OfflineSyncState _syncState = OfflineSyncState.starting;
  DateTime? _lastSyncedAt;
  String? _lastError;
  String? _storageError;
  String? _activeUserScope;
  int _revision = 0;
  int _estimatedCacheBytes = 0;
  String? _lastChangedKey;
  final Map<String, Future<void> Function()> _syncActions = {};
  final Set<String> _activeSyncs = {};
  bool _isObservingLifecycle = false;

  OfflineSyncState get syncState => _syncState;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  String? get lastError => _lastError ?? _storageError;
  int get revision => _revision;
  String? get lastChangedKey => _lastChangedKey;
  bool get isPersistent => _box?.isOpen == true;

  String get _userScope =>
      Supabase.instance.client.auth.currentUser?.id ?? 'signed-out';

  Future<void> initialize({String? directory}) async {
    if (_box?.isOpen == true) return;
    if (!_isObservingLifecycle) {
      WidgetsBinding.instance.addObserver(this);
      _isObservingLifecycle = true;
    }
    try {
      if (directory == null) {
        await Hive.initFlutter();
      } else {
        Hive.init(directory);
      }
      _box = await Hive.openBox<String>(_boxName);
      _estimatedCacheBytes = _box!.values.fold<int>(
        0,
        (total, value) => total + utf8.encode(value).length,
      );
      _activeUserScope = _userScope;
      final storedSyncTime = _get(_scopedKey('sync.last_success'));
      if (storedSyncTime != null) {
        _lastSyncedAt = DateTime.tryParse(storedSyncTime);
        if (_lastSyncedAt != null) _syncState = OfflineSyncState.synced;
      }
    } catch (error) {
      _storageError =
          'Persistent offline storage is unavailable; cached data will only '
          'remain until the app closes: $error';
      _setCacheUnavailable(_storageError!);
    }
    notifyListeners();
  }

  void initializeInMemoryForTesting() {
    _memoryCache.clear();
    _estimatedCacheBytes = 0;
    _activeUserScope = _userScope;
    _lastSyncedAt = null;
    _lastError = null;
    _storageError = null;
    _syncState = OfflineSyncState.starting;
    notifyListeners();
  }

  String _scopedKey(String key, {String? scopeId}) =>
      '${scopeId ?? _userScope}::$key';

  Future<List<Map<String, dynamic>>?> readList(
    String key, {
    String? scopeId,
  }) async {
    final cacheKey = _scopedKey(key, scopeId: scopeId);
    final raw = _get(cacheKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw FormatException('Offline cache entry "$key" is not a list.');
      }
      if (decoded.any((row) => row is! Map)) {
        throw FormatException('Offline cache entry "$key" has invalid rows.');
      }
      return decoded
          .map((row) => Map<String, dynamic>.from(row as Map))
          .toList(growable: false);
    } catch (error) {
      _setOffline('Cached data "$key" is invalid and will be reloaded: $error');
      await _delete(cacheKey);
      return null;
    }
  }

  Future<void> writeList(
    String key,
    List<Map<String, dynamic>> value, {
    String? scopeId,
  }) async {
    final cacheKey = _scopedKey(key, scopeId: scopeId);
    final encoded = jsonEncode(value);
    if (_get(cacheKey) == encoded) return;
    await _put(cacheKey, encoded);
    _notifyDataChanged(key);
  }

  Future<Object?> readValue(String key, {String? scopeId}) async {
    final cacheKey = _scopedKey(key, scopeId: scopeId);
    final raw = _get(cacheKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } catch (error) {
      _setOffline(
        'Cached setting "$key" is invalid and will be reloaded: '
        '$error',
      );
      await _delete(cacheKey);
      return null;
    }
  }

  Future<void> writeValue(String key, Object value, {String? scopeId}) async {
    final cacheKey = _scopedKey(key, scopeId: scopeId);
    final encoded = jsonEncode(value);
    if (_get(cacheKey) == encoded) return;
    await _put(cacheKey, encoded);
    _notifyDataChanged(key);
  }

  Future<T> loadValue<T>({
    required String key,
    required T Function(Object?) decode,
    required Object Function(T) encode,
    required Future<T> Function() fetchRemote,
    String? scopeId,
    bool forceRefresh = false,
  }) async {
    _activateUserScope();
    final syncKey = _scopedKey(key, scopeId: scopeId);
    _syncActions[syncKey] = () => _runBackgroundSync(
      syncKey,
      () => _refreshValueInBackground(
        key: key,
        decode: decode,
        encode: encode,
        fetchRemote: fetchRemote,
        scopeId: scopeId,
      ),
    );
    if (!forceRefresh) {
      final cached = await readValue(key, scopeId: scopeId);
      if (cached != null) {
        try {
          final decoded = decode(cached);
          unawaited(_syncActions[syncKey]!());
          return decoded;
        } catch (error) {
          _setOffline(
            'Cached setting "$key" is invalid and will be reloaded: '
            '$error',
          );
          await remove(key, scopeId: scopeId);
        }
      }
    }
    _setSyncState(OfflineSyncState.syncing);
    try {
      final value = await fetchRemote();
      try {
        await writeValue(key, encode(value), scopeId: scopeId);
        await _markSynced();
      } catch (error) {
        _setCacheUnavailable('Unable to save the local cache: $error');
      }
      return value;
    } catch (error) {
      _setOffline('Unable to sync "$key": $error');
      rethrow;
    }
  }

  Future<void> _refreshValueInBackground<T>({
    required String key,
    required T Function(Object?) decode,
    required Object Function(T) encode,
    required Future<T> Function() fetchRemote,
    required String? scopeId,
  }) async {
    try {
      final value = await fetchRemote();
      try {
        await writeValue(key, encode(value), scopeId: scopeId);
        await _markSynced();
      } catch (error) {
        _setCacheUnavailable('Unable to save the local cache: $error');
      }
    } catch (error) {
      _setOffline('Unable to sync "$key": $error');
    }
  }

  void recordOfflineError(String message) => _setOffline(message);

  Future<void> remove(String key, {String? scopeId}) async {
    final cacheKey = _scopedKey(key, scopeId: scopeId);
    if (_get(cacheKey) == null) return;
    await _delete(cacheKey);
    _notifyDataChanged(key);
  }

  Future<List<T>> loadList<T>({
    required String key,
    required T Function(Map<String, dynamic>) decode,
    required Map<String, dynamic> Function(T) encode,
    required Future<List<T>> Function() fetchRemote,
    String? scopeId,
    bool forceRefresh = false,
  }) async {
    _activateUserScope();
    final syncKey = _scopedKey(key, scopeId: scopeId);
    _syncActions[syncKey] = () => _runBackgroundSync(
      syncKey,
      () => _refreshInBackground(
        key: key,
        decode: decode,
        encode: encode,
        fetchRemote: fetchRemote,
        scopeId: scopeId,
      ),
    );
    if (!forceRefresh) {
      final cached = await readList(key, scopeId: scopeId);
      if (cached != null) {
        try {
          final decoded = cached.map(decode).toList(growable: false);
          unawaited(_syncActions[syncKey]!());
          return decoded;
        } catch (error) {
          _setOffline(
            'Cached data "$key" is invalid and will be reloaded: '
            '$error',
          );
          await remove(key, scopeId: scopeId);
        }
      }
    }
    return _refreshList(
      key: key,
      decode: decode,
      encode: encode,
      fetchRemote: fetchRemote,
      scopeId: scopeId,
    );
  }

  Future<List<T>> _refreshList<T>({
    required String key,
    required T Function(Map<String, dynamic>) decode,
    required Map<String, dynamic> Function(T) encode,
    required Future<List<T>> Function() fetchRemote,
    required String? scopeId,
  }) async {
    _setSyncState(OfflineSyncState.syncing);
    try {
      final items = await fetchRemote();
      try {
        await writeList(
          key,
          items.map(encode).toList(growable: false),
          scopeId: scopeId,
        );
        await _markSynced();
      } catch (error) {
        _setCacheUnavailable('Unable to save the local cache: $error');
      }
      return items;
    } catch (error) {
      _setOffline('Unable to sync "$key": $error');
      rethrow;
    }
  }

  Future<void> _refreshInBackground<T>({
    required String key,
    required T Function(Map<String, dynamic>) decode,
    required Map<String, dynamic> Function(T) encode,
    required Future<List<T>> Function() fetchRemote,
    required String? scopeId,
  }) async {
    try {
      await _refreshList(
        key: key,
        decode: decode,
        encode: encode,
        fetchRemote: fetchRemote,
        scopeId: scopeId,
      );
    } catch (error) {
      _setOffline('Unable to sync "$key": $error');
    }
  }

  Future<void> _markSynced() async {
    _lastSyncedAt = DateTime.now();
    _syncState = OfflineSyncState.synced;
    _lastError = null;
    await _put(
      _scopedKey('sync.last_success'),
      _lastSyncedAt!.toIso8601String(),
    );
    notifyListeners();
  }

  void _setSyncState(OfflineSyncState state) {
    if (_syncState == state) return;
    _syncState = state;
    notifyListeners();
  }

  void _setOffline(String error) {
    _syncState = OfflineSyncState.offline;
    _lastError = error;
    notifyListeners();
  }

  void _setCacheUnavailable(String error) {
    _syncState = OfflineSyncState.cacheUnavailable;
    _lastError = error;
    notifyListeners();
  }

  void _activateUserScope() {
    final currentScope = _userScope;
    if (_activeUserScope == currentScope) return;
    _activeUserScope = currentScope;
    _syncActions.clear();
    _lastSyncedAt = DateTime.tryParse(
      _get('$currentScope::sync.last_success') ?? '',
    );
    _lastError = null;
    _syncState = _lastSyncedAt == null
        ? OfflineSyncState.starting
        : OfflineSyncState.synced;
    notifyListeners();
  }

  Future<void> _runBackgroundSync(
    String key,
    Future<void> Function() action,
  ) async {
    if (!_activeSyncs.add(key)) return;
    try {
      await action();
    } finally {
      _activeSyncs.remove(key);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    for (final sync in _syncActions.values) {
      unawaited(sync());
    }
  }

  void _notifyDataChanged(String key) {
    _revision++;
    _lastChangedKey = key;
    notifyListeners();
  }

  String? _get(String key) {
    final box = _box;
    return box?.isOpen == true ? box!.get(key) : _memoryCache[key];
  }

  Future<void> _put(String key, String value) async {
    if (utf8.encode(value).length > _maxEntryBytes) {
      throw StateError(
        'Offline cache entry exceeds the $_maxEntryBytes-byte limit.',
      );
    }
    final box = _box;
    final oldSize = utf8.encode(_get(key) ?? '').length;
    final newSize = utf8.encode(value).length;
    if (box?.isOpen == true) {
      while ((!box!.containsKey(key) && box.length >= _maxBoxEntries) ||
          _estimatedCacheBytes - oldSize + newSize > _maxCacheBytes) {
        final evictable = box.keys.cast<String>().firstWhere(
          (existingKey) =>
              existingKey != key &&
              !existingKey.contains('.pending') &&
              !existingKey.endsWith('::sync.last_success'),
          orElse: () => '',
        );
        if (evictable.isEmpty) {
          throw StateError(
            'Offline cache reached its $_maxCacheBytes-byte storage limit.',
          );
        }
        final evictedValue = box.get(evictable);
        if (evictedValue != null) {
          _estimatedCacheBytes -= utf8.encode(evictedValue).length;
        }
        await box.delete(evictable);
      }
      await box.put(key, value);
    } else {
      if (_estimatedCacheBytes - oldSize + newSize > _maxCacheBytes) {
        throw StateError(
          'Offline cache reached its $_maxCacheBytes-byte storage limit.',
        );
      }
      _memoryCache[key] = value;
    }
    _estimatedCacheBytes += newSize - oldSize;
  }

  Future<void> _delete(String key) async {
    final box = _box;
    final oldValue = _get(key);
    if (box?.isOpen == true) {
      await box!.delete(key);
    } else {
      _memoryCache.remove(key);
    }
    if (oldValue != null) {
      _estimatedCacheBytes -= utf8.encode(oldValue).length;
    }
  }
}
