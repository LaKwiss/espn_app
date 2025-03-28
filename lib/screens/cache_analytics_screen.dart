import 'package:espn_app/services/hive_cache_service.dart';
import 'package:espn_app/widgets/cache_statistics_widget.dart';
import 'package:espn_app/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CacheAnalyticsScreen extends ConsumerStatefulWidget {
  const CacheAnalyticsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CacheAnalyticsScreen> createState() =>
      _CacheAnalyticsScreenState();
}

class _CacheAnalyticsScreenState extends ConsumerState<CacheAnalyticsScreen> {
  List<MapEntry<dynamic, dynamic>> _cacheEntries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCacheEntries();
  }

  Future<void> _loadCacheEntries() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final cacheService = HiveCacheService();

      // Get all keys and their corresponding entries
      final entries = <MapEntry<dynamic, dynamic>>[];

      for (final key in cacheService.box.keys) {
        final value = cacheService.box.get(key);
        if (value != null) {
          entries.add(MapEntry(key, value));
        }
      }

      // Sort by expiry time
      entries.sort((a, b) {
        final aExpiry = a.value.expiryTimestamp as int;
        final bExpiry = b.value.expiryTimestamp as int;
        return bExpiry.compareTo(aExpiry); // Most recent first
      });

      setState(() {
        _cacheEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading cache entries: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getUrlCategory(String url) {
    if (url.contains('/leagues/')) {
      return 'League';
    } else if (url.contains('/events/')) {
      return 'Event';
    } else if (url.contains('/athletes/')) {
      return 'Athlete';
    } else if (url.contains('/teams/')) {
      return 'Team';
    } else if (url.contains('/positions/')) {
      return 'Position';
    } else {
      return 'Other';
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'League':
        return Colors.purple;
      case 'Event':
        return Colors.blue;
      case 'Athlete':
        return Colors.orange;
      case 'Team':
        return Colors.green;
      case 'Position':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatExpiryTime(int timestamp) {
    final now = DateTime.now();
    final expiry = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final difference = expiry.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays}d ${difference.inHours % 24}h';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m';
    } else {
      return '${difference.inMinutes}m';
    }
  }

  String _truncateUrl(String url) {
    const maxLength = 40;
    if (url.length <= maxLength) return url;
    return '${url.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Cache Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCacheEntries,
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  // Statistics card
                  CacheStatisticsWidget(),

                  // Cache entries list
                  Expanded(
                    child:
                        _cacheEntries.isEmpty
                            ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.storage_outlined,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No Cache Entries Found',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Browse the app to start caching data',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )
                            : ListView.builder(
                              itemCount: _cacheEntries.length,
                              itemBuilder: (context, index) {
                                final entry = _cacheEntries[index];
                                final url = entry.key as String;
                                final cacheData = entry.value;
                                final category = _getUrlCategory(url);
                                final categoryColor = _getCategoryColor(
                                  category,
                                );
                                final expiryTime = _formatExpiryTime(
                                  cacheData.expiryTimestamp,
                                );
                                final isExpired =
                                    DateTime.now().millisecondsSinceEpoch >
                                    cacheData.expiryTimestamp;

                                return Card(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    leading: CircleAvatar(
                                      backgroundColor: categoryColor
                                          .withOpacity(0.2),
                                      child: Text(
                                        category[0],
                                        style: TextStyle(color: categoryColor),
                                      ),
                                    ),
                                    title: Text(_truncateUrl(url)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 4),
                                        Text('Category: $category'),
                                        Text(
                                          'Expires: $expiryTime',
                                          style: TextStyle(
                                            color:
                                                isExpired ? Colors.red : null,
                                            fontWeight:
                                                isExpired
                                                    ? FontWeight.bold
                                                    : null,
                                          ),
                                        ),
                                        Text(
                                          'Size: ${cacheData.body.length ~/ 1024} KB',
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () async {
                                        final cacheService = HiveCacheService();
                                        await cacheService.invalidate(url);
                                        _loadCacheEntries();
                                      },
                                    ),
                                    onTap: () {
                                      // Show detailed view of cache entry
                                      showDialog(
                                        context: context,
                                        builder:
                                            (context) => AlertDialog(
                                              title: Text(
                                                'Cache Entry Details',
                                              ),
                                              content: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'URL:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(url),
                                                    const SizedBox(height: 8),
                                                    Text('Category: $category'),
                                                    Text(
                                                      'Status Code: ${cacheData.statusCode}',
                                                    ),
                                                    Text(
                                                      'Content Size: ${(cacheData.body.length / 1024).toStringAsFixed(2)} KB',
                                                    ),
                                                    Text(
                                                      'Expiry: ${DateTime.fromMillisecondsSinceEpoch(cacheData.expiryTimestamp)}',
                                                    ),
                                                    const SizedBox(height: 16),
                                                    Text(
                                                      'Response Headers:',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    ...cacheData.headers.entries
                                                        .map(
                                                          (e) => Text(
                                                            '${e.key}: ${e.value}',
                                                          ),
                                                        )
                                                        .toList(),
                                                  ],
                                                ),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed:
                                                      () =>
                                                          Navigator.of(
                                                            context,
                                                          ).pop(),
                                                  child: Text(l10n.closeButton),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final hiveCacheService = HiveCacheService();
          await hiveCacheService.clearAll();
          _loadCacheEntries();

          // Show snackbar
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
          }
        },
        child: const Icon(Icons.delete_sweep),
        tooltip: l10n.clearCache,
      ),
    );
  }
}
