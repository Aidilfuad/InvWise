import 'package:flutter/material.dart';

import '../services/offline_cache_service.dart';

class OfflineSyncIndicator extends StatelessWidget {
  const OfflineSyncIndicator({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OfflineCacheService.instance,
    builder: (context, _) {
      final cache = OfflineCacheService.instance;
      final (label, color, icon) = switch (cache.syncState) {
        OfflineSyncState.starting => (
          'Waiting to sync',
          Colors.blueGrey,
          Icons.cloud_outlined,
        ),
        OfflineSyncState.syncing => (
          'Syncing',
          Colors.blue,
          Icons.sync_rounded,
        ),
        OfflineSyncState.synced => (
          'Synced • Last synced ${_relativeTime(cache.lastSyncedAt)}',
          Colors.green,
          Icons.cloud_done_outlined,
        ),
        OfflineSyncState.offline => (
          'Offline mode • Showing cached data',
          Colors.orange.shade800,
          Icons.cloud_off_outlined,
        ),
        OfflineSyncState.cacheUnavailable => (
          'Local cache unavailable • Online only',
          Colors.red,
          Icons.storage_rounded,
        ),
      };
      return Tooltip(
        message: cache.lastError ?? label,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );

  String _relativeTime(DateTime? time) {
    if (time == null) return 'just now';
    final elapsed = DateTime.now().difference(time);
    if (elapsed.inSeconds < 60) return 'just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes} min ago';
    if (elapsed.inHours < 24) return '${elapsed.inHours} hr ago';
    return '${elapsed.inDays} days ago';
  }
}
