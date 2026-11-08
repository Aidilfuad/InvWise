import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:invwise/services/app_update_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'compares semantic versions without treating build numbers as release',
    () {
      expect(AppUpdateService.isNewer('1.10.0', '1.9.9'), isTrue);
      expect(AppUpdateService.isNewer('2.0.0', '1.99.99'), isTrue);
      expect(AppUpdateService.isNewer('1.0.0+2', '1.0.0+1'), isFalse);
      expect(AppUpdateService.isNewer('1.0.0', '1.0.0'), isFalse);
      expect(
        () => AppUpdateService.isNewer('invalid', '1.0.0'),
        throwsFormatException,
      );
    },
  );

  test('derives latest, available, and required update states', () {
    final release = AppVersionRelease(
      version: '1.0.1',
      apkUrl: 'https://downloads.example/invwise.apk',
      releaseNotes: 'Fixes',
      forceUpdate: false,
      createdAt: DateTime.utc(2026, 11, 9),
    );
    expect(
      AppUpdateService.statusFor(release, '1.0.1'),
      AppUpdateStatus.latest,
    );
    expect(
      AppUpdateService.statusFor(release, '1.0.0'),
      AppUpdateStatus.available,
    );
    expect(
      AppUpdateService.statusFor(
        AppVersionRelease(
          version: release.version,
          apkUrl: release.apkUrl,
          releaseNotes: release.releaseNotes,
          forceUpdate: true,
          createdAt: release.createdAt,
        ),
        '1.0.0',
      ),
      AppUpdateStatus.required,
    );
    expect(
      AppUpdateService.statusFor(null, '1.0.0'),
      AppUpdateStatus.unavailable,
    );
  });

  test('rejects empty, malformed, and non-HTTPS update URLs', () {
    for (final url in [null, '', 'not a url', 'http://downloads.example/app']) {
      expect(
        () => AppUpdateService.validateUpdateUrl(url),
        throwsA(isA<UpdateUrlException>()),
      );
    }
    expect(
      AppUpdateService.validateUpdateUrl('https://downloads.example/app').host,
      'downloads.example',
    );
  });

  test('tries platform-default launcher when external launch fails', () async {
    final client = _clientWithActivityLog();
    final modes = <LaunchMode>[];
    final service = AppUpdateService(
      client: client,
      urlLauncher: (url, mode) async {
        expect(url.scheme, 'https');
        modes.add(mode);
        return mode == LaunchMode.platformDefault;
      },
    );
    addTearDown(service.dispose);

    await service.launchUpdate(_release());

    expect(modes, [LaunchMode.externalApplication, LaunchMode.platformDefault]);
  });

  test('URL diagnostics confirm reachability and opening', () async {
    final client = _clientWithActivityLog();
    final httpClient = MockClient((request) async {
      expect(request.url.scheme, 'https');
      expect(request.method, 'HEAD');
      return http.Response('', 200, request: request);
    });
    final service = AppUpdateService(
      client: client,
      httpClient: httpClient,
      urlLauncher: (url, mode) async => true,
    );
    addTearDown(httpClient.close);

    final result = await service.validateAndOpenUpdateUrl(_release());

    expect(result.passed, isTrue);
    expect(result.reachable, isTrue);
    expect(result.opened, isTrue);
  });

  test(
    'URL diagnostics fail clearly when the update host is unreachable',
    () async {
      final client = _clientWithActivityLog();
      var launchAttempted = false;
      final httpClient = MockClient((request) async {
        throw http.ClientException('network unavailable');
      });
      final service = AppUpdateService(
        client: client,
        httpClient: httpClient,
        urlLauncher: (url, mode) async {
          launchAttempted = true;
          return true;
        },
      );
      addTearDown(httpClient.close);

      final result = await service.validateAndOpenUpdateUrl(_release());

      expect(result.passed, isFalse);
      expect(result.reachable, isFalse);
      expect(result.reason, contains('Could not reach'));
      expect(launchAttempted, isFalse);
    },
  );

  test('release history reads stable GitHub releases newest first', () async {
    final httpClient = MockClient((request) async {
      expect(request.url.host, 'api.github.com');
      expect(request.url.path, '/repos/Aidilfuad/InvWise/releases');
      expect(request.url.queryParameters['per_page'], '100');
      return http.Response(
        jsonEncode([
          _githubRelease(
            tag: 'v2.0.0',
            notes: 'Final release',
            date: '2026-11-09T00:00:00Z',
          ),
          _githubRelease(
            tag: 'v1.0.0',
            notes: 'Initial Production Release',
            date: '2026-11-08T00:00:00Z',
          ),
          {..._githubRelease(tag: 'v3.0.0'), 'prerelease': true},
        ]),
        200,
        headers: {'content-type': 'application/json'},
        request: request,
      );
    });
    final service = AppUpdateService(
      client: _clientWithActivityLog(),
      httpClient: httpClient,
    );

    final releases = await service.releaseHistory();

    expect(releases.map((release) => release.version), ['v2.0.0', 'v1.0.0']);
    expect(releases.first.releaseNotes, 'Final release');
    expect(releases.last.releaseNotes, 'Initial Production Release');
    expect(releases.first.createdAt, DateTime.parse('2026-11-09T00:00:00Z'));
    httpClient.close();
  });

  test(
    'loads latest GitHub release APK, notes, date, and force marker',
    () async {
      final httpClient = MockClient((request) async {
        expect(request.url.path, endsWith('/releases/latest'));
        return http.Response(
          jsonEncode(
            _githubRelease(
              tag: 'v2.1.0',
              notes: 'Enterprise improvements\nforce_update: true',
              date: '2026-11-09T00:00:00Z',
            ),
          ),
          200,
          headers: {'content-type': 'application/json'},
          request: request,
        );
      });
      final service = AppUpdateService(
        client: _clientWithActivityLog(),
        httpClient: httpClient,
      );

      final release = await service.latestRelease();

      expect(release?.version, 'v2.1.0');
      expect(release?.forceUpdate, isTrue);
      expect(release?.releaseNotes, 'Enterprise improvements');
      expect(release?.apkUrl, 'https://downloads.example/invwise.apk');
      expect(release?.createdAt, DateTime.parse('2026-11-09T00:00:00Z'));
      httpClient.close();
    },
  );
}

Map<String, dynamic> _githubRelease({
  String tag = 'v2.0.0',
  String notes = 'Release notes',
  String date = '2026-11-09T00:00:00Z',
}) => {
  'tag_name': tag,
  'body': notes,
  'published_at': date,
  'created_at': date,
  'prerelease': false,
  'assets': [
    {
      'name': 'invwise.apk',
      'browser_download_url': 'https://downloads.example/invwise.apk',
    },
    {
      'name': 'checksums.txt',
      'browser_download_url': 'https://downloads.example/checksums.txt',
    },
  ],
};

AppVersionRelease _release({
  String? url = 'https://downloads.example/app.apk',
}) => AppVersionRelease(
  version: '1.0.1',
  apkUrl: url,
  releaseNotes: 'Update test',
  forceUpdate: false,
  createdAt: DateTime.utc(2026, 11, 9),
);

SupabaseClient _clientWithActivityLog() => SupabaseClient(
  'http://localhost:54321',
  'test-key',
  httpClient: MockClient((request) async {
    if (request.url.path.endsWith('/activity_logs')) {
      return http.Response('', 201, request: request);
    }
    return http.Response(
      jsonEncode({'message': 'Unexpected request'}),
      500,
      headers: {'content-type': 'application/json'},
      request: request,
    );
  }),
  authOptions: FlutterAuthClientOptions(
    autoRefreshToken: false,
    persistSession: false,
    localStorage: const EmptyLocalStorage(),
  ),
);
