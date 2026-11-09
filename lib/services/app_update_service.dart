import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'offline_cache_service.dart';
import 'system_activity_log_service.dart';

const String githubReleaseApi =
    'https://api.github.com/repos/Aidilfuad/InvWise/releases';

enum AppUpdateStatus { latest, available, required, unavailable }

class AppVersionRelease {
  const AppVersionRelease({
    required this.version,
    required this.apkUrl,
    required this.releaseNotes,
    required this.forceUpdate,
    required this.createdAt,
  });

  final String version;
  final String? apkUrl;
  final String releaseNotes;
  final bool forceUpdate;
  final DateTime createdAt;

  factory AppVersionRelease.fromMap(Map<String, dynamic> map) =>
      AppVersionRelease(
        version: _releaseVersion(map),
        apkUrl: _apkUrl(map),
        releaseNotes: _releaseNotes(map),
        forceUpdate: _forceUpdate(map),
        createdAt: DateTime.parse(
          (map['published_at'] ?? map['created_at']) as String,
        ),
      );

  static String _releaseVersion(Map<String, dynamic> map) =>
      (map['tag_name'] ?? map['version']) as String;

  static String? _apkUrl(Map<String, dynamic> map) {
    final oldUrl = map['apk_url'];
    if (oldUrl is String && oldUrl.trim().isNotEmpty) return oldUrl;
    final assets = map['assets'];
    if (assets is! List) return null;
    for (final asset in assets) {
      if (asset is Map &&
          asset['name'] is String &&
          (asset['name'] as String).toLowerCase().endsWith('.apk') &&
          asset['browser_download_url'] is String) {
        return asset['browser_download_url'] as String;
      }
    }
    return null;
  }

  static String _releaseNotes(Map<String, dynamic> map) {
    final body = (map['body'] ?? map['release_notes'] ?? '') as String;
    return body
        .replaceAll(
          RegExp(
            r'^\s*force_update\s*:\s*true\s*$',
            multiLine: true,
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  static bool _forceUpdate(Map<String, dynamic> map) {
    if (map['force_update'] == true) return true;
    final body = map['body'];
    return body is String &&
        RegExp(
          r'^\s*force_update\s*:\s*true\s*$',
          multiLine: true,
          caseSensitive: false,
        ).hasMatch(body);
  }
}

class AppUpdateCheckResult {
  const AppUpdateCheckResult({
    required this.installedVersion,
    required this.release,
    required this.status,
    this.message,
  });

  final String installedVersion;
  final AppVersionRelease? release;
  final AppUpdateStatus status;
  final String? message;
}

class _GitHubJsonResponse {
  const _GitHubJsonResponse({required this.payload, this.notice});

  final Object? payload;
  final String? notice;
}

class _CachedGitHubResponse {
  const _CachedGitHubResponse({required this.savedAt, required this.payload});

  final DateTime savedAt;
  final Object? payload;

  bool isFreshAt(DateTime now) {
    final age = now.difference(savedAt);
    return !age.isNegative && age < AppUpdateService._cacheLifetime;
  }
}

class GitHubReleaseException implements Exception {
  const GitHubReleaseException({
    required this.message,
    required this.statusCode,
    required this.isRateLimited,
  });

  final String message;
  final int statusCode;
  final bool isRateLimited;

  @override
  String toString() => message;
}

class UpdateUrlException implements Exception {
  const UpdateUrlException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UpdateUrlDiagnostic {
  const UpdateUrlDiagnostic({
    required this.passed,
    required this.reason,
    this.reachable,
    this.opened,
  });

  final bool passed;
  final String reason;
  final bool? reachable;
  final bool? opened;
}

typedef UpdateUrlLauncher = Future<bool> Function(Uri url, LaunchMode mode);
typedef UpdateCacheReader = Future<Object?> Function(String key);
typedef UpdateCacheWriter = Future<void> Function(String key, Object value);

class AppUpdateService {
  AppUpdateService({
    SupabaseClient? client,
    SystemActivityLogService? activityLog,
    http.Client? httpClient,
    UpdateUrlLauncher? urlLauncher,
    UpdateCacheReader? cacheReader,
    UpdateCacheWriter? cacheWriter,
    DateTime Function()? clock,
  }) : _client = client ?? Supabase.instance.client,
       _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _urlLauncher =
           urlLauncher ?? ((url, mode) => launchUrl(url, mode: mode)),
       _cacheReader = cacheReader ?? _readPersistentCache,
       _cacheWriter = cacheWriter ?? _writePersistentCache,
       _clock = clock ?? DateTime.now {
    _activityLog = activityLog ?? SystemActivityLogService(client: _client);
  }

  static const Duration _cacheLifetime = Duration(hours: 1);
  static const String _cacheScope = 'github-release-cache-v1';
  static const String _latestReleaseCacheKey = 'github.latest_release';
  static const String _releaseHistoryCachePrefix = 'github.release_history.';

  final SupabaseClient _client;
  late final SystemActivityLogService _activityLog;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final UpdateUrlLauncher _urlLauncher;
  final UpdateCacheReader _cacheReader;
  final UpdateCacheWriter _cacheWriter;
  final DateTime Function() _clock;

  String? _latestReleaseNotice;
  String? _releaseHistoryNotice;

  String? get latestReleaseNotice => _latestReleaseNotice;
  String? get releaseHistoryNotice => _releaseHistoryNotice;

  static Future<Object?> _readPersistentCache(String key) =>
      OfflineCacheService.instance.readValue(key, scopeId: _cacheScope);

  static Future<void> _writePersistentCache(String key, Object value) =>
      OfflineCacheService.instance.writeValue(key, value, scopeId: _cacheScope);

  static Future<String> installedVersion() async =>
      (await PackageInfo.fromPlatform()).version;

  Future<AppVersionRelease?> latestRelease() async {
    final response = await _githubJson(
      Uri.parse('$githubReleaseApi/latest'),
      cacheKey: _latestReleaseCacheKey,
      notFoundIsNull: true,
    );
    _latestReleaseNotice = response.notice;
    final decoded = response.payload;
    if (decoded == null) return null;
    if (decoded is! Map) {
      throw const FormatException('GitHub returned an invalid release record.');
    }
    return AppVersionRelease.fromMap(Map<String, dynamic>.from(decoded));
  }

  Future<List<AppVersionRelease>> releaseHistory({int limit = 100}) async {
    if (limit <= 0 || limit > 500) {
      throw ArgumentError.value(limit, 'limit', 'Must be between 1 and 500.');
    }
    final response = await _githubJson(
      Uri.parse('$githubReleaseApi?per_page=$limit'),
      cacheKey: '$_releaseHistoryCachePrefix$limit',
    );
    _releaseHistoryNotice = response.notice;
    final decoded = response.payload;
    if (decoded is! List) {
      throw const FormatException('GitHub returned invalid release history.');
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .where((release) => release['prerelease'] != true)
        .map(AppVersionRelease.fromMap)
        .toList(growable: false);
  }

  Future<_GitHubJsonResponse> _githubJson(
    Uri uri, {
    required String cacheKey,
    bool notFoundIsNull = false,
  }) async {
    final cached = await _readCache(cacheKey);
    if (cached != null && cached.isFreshAt(_clock())) {
      return _GitHubJsonResponse(payload: cached.payload);
    }

    final response = await _httpClient
        .get(uri, headers: _githubHeaders)
        .timeout(const Duration(seconds: 10));
    if (response.statusCode == 403 || response.statusCode == 429) {
      final rateLimited = _isRateLimitResponse(response);
      if (cached != null) {
        return _GitHubJsonResponse(
          payload: cached.payload,
          notice: rateLimited
              ? 'GitHub is temporarily rate-limiting update checks. Showing '
                    'saved release information.'
              : 'GitHub temporarily denied the update request. Showing saved '
                    'release information.',
        );
      }
      throw GitHubReleaseException(
        statusCode: response.statusCode,
        isRateLimited: rateLimited,
        message: rateLimited
            ? 'GitHub is temporarily rate-limiting update checks. Please try '
                  'again later.'
            : 'GitHub temporarily denied the update request. Please try again '
                  'later.',
      );
    }
    if (notFoundIsNull && response.statusCode == 404) {
      return const _GitHubJsonResponse(payload: null);
    }
    if (response.statusCode != 200) {
      throw http.ClientException(
        'GitHub Releases returned HTTP ${response.statusCode}.',
        uri,
      );
    }

    final decoded = jsonDecode(response.body);
    await _writeCache(cacheKey, decoded);
    return _GitHubJsonResponse(payload: decoded);
  }

  Future<_CachedGitHubResponse?> _readCache(String key) async {
    try {
      final value = await _cacheReader(key);
      if (value is! Map) return null;
      final savedAtValue = value['saved_at'];
      if (savedAtValue is! String || !value.containsKey('payload')) {
        return null;
      }
      final savedAt = DateTime.tryParse(savedAtValue);
      if (savedAt == null) return null;
      return _CachedGitHubResponse(savedAt: savedAt, payload: value['payload']);
    } catch (error) {
      debugPrint('Unable to read cached GitHub release data: $error');
      return null;
    }
  }

  Future<void> _writeCache(String key, Object? payload) async {
    if (payload == null) return;
    try {
      await _cacheWriter(key, {
        'saved_at': _clock().toUtc().toIso8601String(),
        'payload': payload,
      });
    } catch (error) {
      debugPrint('Unable to cache GitHub release data: $error');
    }
  }

  static bool _isRateLimitResponse(http.Response response) {
    final remaining = response.headers['x-ratelimit-remaining'];
    final body = response.body.toLowerCase();
    return response.statusCode == 429 ||
        remaining == '0' ||
        body.contains('api rate limit exceeded') ||
        body.contains('rate limit');
  }

  static const Map<String, String> _githubHeaders = {
    'Accept': 'application/vnd.github+json',
    'User-Agent': 'InvWise-App-Updater',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Future<AppUpdateCheckResult> checkForUpdates() async {
    String? installed;
    try {
      installed = await installedVersion();
      final release = await latestRelease();
      await _record(
        action: 'Checked For Updates',
        description: 'Checked for application updates.',
        metadata: {'installed_version': installed},
      );

      final status = statusFor(release, installed);
      final isAvailable =
          status == AppUpdateStatus.available ||
          status == AppUpdateStatus.required;
      final availableRelease = isAvailable ? release : null;
      if (availableRelease != null) {
        await _record(
          action: 'Update Available',
          description: 'Version ${availableRelease.version} is available.',
          metadata: {
            'installed_version': installed,
            'available_version': availableRelease.version,
            'force_update': availableRelease.forceUpdate,
          },
        );
      }

      return AppUpdateCheckResult(
        installedVersion: installed,
        release: release,
        status: status,
        message: _latestReleaseNotice,
      );
    } catch (error) {
      await _record(
        action: 'Update Failed',
        description: 'Unable to check for application updates: $error',
      );
      if (error is GitHubReleaseException && installed != null) {
        return AppUpdateCheckResult(
          installedVersion: installed,
          release: null,
          status: AppUpdateStatus.unavailable,
          message: error.message,
        );
      }
      rethrow;
    }
  }

  static AppUpdateStatus statusFor(
    AppVersionRelease? release,
    String installedVersion,
  ) {
    if (release == null) return AppUpdateStatus.unavailable;
    if (!isNewer(release.version, installedVersion)) {
      return AppUpdateStatus.latest;
    }
    return release.forceUpdate
        ? AppUpdateStatus.required
        : AppUpdateStatus.available;
  }

  static bool isNewer(String candidate, String installed) {
    final candidateParts = _parseVersion(candidate);
    final installedParts = _parseVersion(installed);
    for (var index = 0; index < 3; index++) {
      if (candidateParts[index] != installedParts[index]) {
        return candidateParts[index] > installedParts[index];
      }
    }
    return false;
  }

  static List<int> _parseVersion(String version) {
    final match = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:\+[0-9]+)?$')
        .firstMatch(version.trim());
    if (match == null) {
      throw FormatException('Invalid semantic version: $version');
    }
    return [
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    ];
  }

  static Uri validateUpdateUrl(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      throw const UpdateUrlException('No update download URL is configured.');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || uri.host.isEmpty) {
      throw const UpdateUrlException('The update download URL is invalid.');
    }
    if (uri.scheme.toLowerCase() != 'https') {
      throw const UpdateUrlException(
        'The update download URL must use secure HTTPS.',
      );
    }
    if (uri.userInfo.isNotEmpty) {
      throw const UpdateUrlException(
        'The update download URL cannot contain login credentials.',
      );
    }
    return uri;
  }

  Future<void> launchUpdate(AppVersionRelease release) async {
    await _record(
      action: 'Update Started',
      description: 'Started update to version ${release.version}.',
      metadata: {'version': release.version},
    );
    try {
      final uri = validateUpdateUrl(release.apkUrl);
      var opened = false;
      try {
        opened = await _urlLauncher(uri, LaunchMode.externalApplication);
      } catch (error) {
        debugPrint('External update URL launch failed: $error');
      }
      if (!opened) {
        try {
          opened = await _urlLauncher(uri, LaunchMode.platformDefault);
        } catch (error) {
          debugPrint('Fallback update URL launch failed: $error');
        }
      }
      if (!opened) {
        throw const UpdateUrlException(
          'No browser or supported app could open the update link.',
        );
      }
      await _record(
        action: 'Update URL Opened',
        description: 'Opened the update download URL for ${release.version}.',
        metadata: {'version': release.version, 'url_host': uri.host},
      );
    } catch (error) {
      await _record(
        action: 'Update Failed',
        description: 'Unable to open update ${release.version}: $error',
        metadata: {'version': release.version},
      );
      rethrow;
    }
  }

  Future<UpdateUrlDiagnostic> validateAndOpenUpdateUrl(
    AppVersionRelease release,
  ) async {
    late final Uri uri;
    try {
      uri = validateUpdateUrl(release.apkUrl);
    } on UpdateUrlException catch (error) {
      await _record(
        action: 'Update Failed',
        description: 'Update URL validation failed: ${error.message}',
        metadata: {'version': release.version},
      );
      return UpdateUrlDiagnostic(passed: false, reason: error.message);
    }

    try {
      var response = await _httpClient
          .head(uri)
          .timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) {
        final request = http.Request('GET', uri)
          ..headers['Range'] = 'bytes=0-0';
        final streamedResponse = await _httpClient
            .send(request)
            .timeout(const Duration(seconds: 10));
        await streamedResponse.stream.listen((_) {}).cancel();
        response = http.Response(
          '',
          streamedResponse.statusCode,
          request: request,
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 400) {
        final reason = 'The URL responded with HTTP ${response.statusCode}.';
        await _record(
          action: 'Update Failed',
          description: 'Update URL diagnostic failed: $reason',
          metadata: {'version': release.version},
        );
        return UpdateUrlDiagnostic(
          passed: false,
          reason: reason,
          reachable: false,
        );
      }
    } catch (error) {
      final reason = 'Could not reach the update URL: $error';
      await _record(
        action: 'Update Failed',
        description: 'Update URL diagnostic failed: $reason',
        metadata: {'version': release.version},
      );
      return UpdateUrlDiagnostic(
        passed: false,
        reason: reason,
        reachable: false,
      );
    }

    try {
      await launchUpdate(release);
      return const UpdateUrlDiagnostic(
        passed: true,
        reason: 'URL is reachable and opened successfully.',
        reachable: true,
        opened: true,
      );
    } catch (error) {
      return UpdateUrlDiagnostic(
        passed: false,
        reason: 'URL is reachable, but could not be opened: $error',
        reachable: true,
        opened: false,
      );
    }
  }

  Future<void> _record({
    required String action,
    required String description,
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      await _activityLog.record(
        category: 'App Update',
        action: action,
        description: description,
        entityType: 'app_version',
        metadata: metadata,
      );
    } catch (error) {
      debugPrint('Unable to record app update activity "$action": $error');
    }
  }

  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
  }
}
