import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../services/offline_cache_service.dart';

class SystemHealthSummaryCard extends StatelessWidget {
  const SystemHealthSummaryCard({super.key});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: OfflineCacheService.instance,
    builder: (context, _) {
      final cache = OfflineCacheService.instance;
      final online = cache.syncState == OfflineSyncState.synced;
      final lastSync = cache.lastSyncedAt;
      return Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                online ? Icons.health_and_safety_outlined : Icons.cloud_off,
                color: online ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'System Health',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      online
                          ? 'Data synchronization is healthy'
                          : 'Sync status: ${cache.syncState.name}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (lastSync != null)
                Text(
                  TimeOfDay.fromDateTime(lastSync.toLocal()).format(context),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        ),
      );
    },
  );
}
