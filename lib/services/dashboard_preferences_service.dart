import 'package:flutter/foundation.dart';

import 'offline_cache_service.dart';

enum DashboardMode { full, compact }

class DashboardPreferencesService extends ChangeNotifier {
  DashboardPreferencesService._();

  static final DashboardPreferencesService instance =
      DashboardPreferencesService._();
  static const String _compactCardsKey = 'dashboard.compact_mode';

  String? _profileId;
  bool _compactCards = false;

  bool get compactCards => _compactCards;
  DashboardMode get mode =>
      _compactCards ? DashboardMode.compact : DashboardMode.full;

  Future<void> loadForProfile(String profileId) async {
    if (profileId.trim().isEmpty) return;
    _profileId = profileId;
    _compactCards =
        await OfflineCacheService.instance.readValue(
          _compactCardsKey,
          scopeId: profileId,
        ) ==
        true;
    notifyListeners();
  }

  Future<void> setCompactCards(bool enabled) async {
    final profileId = _profileId;
    if (profileId == null) {
      throw StateError('Load the current dashboard preference first.');
    }
    await OfflineCacheService.instance.writeValue(
      _compactCardsKey,
      enabled,
      scopeId: profileId,
    );
    _compactCards = enabled;
    notifyListeners();
  }

  Future<void> setMode(DashboardMode mode) =>
      setCompactCards(mode == DashboardMode.compact);
}
