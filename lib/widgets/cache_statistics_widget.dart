import 'dart:async';
import 'dart:developer' as dev;
import 'package:flutter/material.dart';
import 'package:espn_app/services/hive_cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:espn_app/providers/provider_factory.dart';

class CacheStatisticsWidget extends ConsumerStatefulWidget {
  const CacheStatisticsWidget({super.key});

  @override
  ConsumerState<CacheStatisticsWidget> createState() =>
      _CacheStatisticsWidgetState();
}

class _CacheStatisticsWidgetState extends ConsumerState<CacheStatisticsWidget> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {}); // Force refresh every 2 seconds
      }
    });

    // Initial update of cache size
    _updateCacheSize();
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  Future<void> _updateCacheSize() async {
    try {
      final cacheService = HiveCacheService();
      final statTracker = ref.read(cacheStatsProvider);

      // Update total storage size
      int totalSize = 0;
      final keys = cacheService.box.keys;
      for (var key in keys) {
        final entry = cacheService.box.get(key);
        if (entry != null) {
          // Rough estimate of entry size
          totalSize += entry.body.length;
        }
      }

      statTracker.updateTotalStorage(totalSize);
    } catch (e) {
      dev.log('Error updating cache size: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final statTracker = ref.watch(cacheStatsProvider);

    // Make sure to update the cache size on each build
    _updateCacheSize();

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Cache Statistics',
              style: GoogleFonts.blackOpsOne(
                fontSize: 20,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Cache hit ratio visual indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cache Hit Ratio: ${(statTracker.hitRatio * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: statTracker.hitRatio,
                    minHeight: 12,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getColorForRatio(statTracker.hitRatio),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stats grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatCard(
                  'Cache Hits',
                  statTracker.cacheHits.toString(),
                  Icons.check_circle_outline,
                  Colors.green,
                ),
                _buildStatCard(
                  'Cache Misses',
                  statTracker.cacheMisses.toString(),
                  Icons.remove_circle_outline,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Cache Expired',
                  statTracker.cacheExpired.toString(),
                  Icons.timer_off_outlined,
                  Colors.red,
                ),
                _buildStatCard(
                  'Network Requests',
                  statTracker.networkRequests.toString(),
                  Icons.cloud_download_outlined,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Cache storage
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total Storage:', style: theme.textTheme.titleMedium),
                    Text(
                      _formatBytes(statTracker.totalStorage),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.onPrimary,
                  ),
                  label: Text(l10n.clearCache),
                  onPressed: () async {
                    final hiveCacheService = HiveCacheService();
                    await hiveCacheService.clearAll();
                    statTracker.reset();
                    await _updateCacheSize();
                    setState(() {});
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForRatio(double ratio) {
    if (ratio >= 0.8) return Colors.green;
    if (ratio >= 0.5) return Colors.lightGreen;
    if (ratio >= 0.3) return Colors.orange;
    return Colors.red;
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
