import 'dart:developer' as dev;
import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiLogInterceptor {
  final Ref ref;

  ApiLogInterceptor(this.ref);

  void processLog(String logMessage) {
    try {
      final statsTracker = ref.read(cacheStatsProvider);

      if (logMessage.contains('[Source: 🔵 CACHE HIT ✅]')) {
        statsTracker.trackCacheHit();
      } else if (logMessage.contains('[Source: 🔵 CACHE MISS ❌]')) {
        statsTracker.trackCacheMiss();
      } else if (logMessage.contains('[Source: 🔵 CACHE EXPIRED ⏰]')) {
        statsTracker.trackCacheExpired();
      } else if (logMessage.contains('[Source: 🔵 NETWORK')) {
        statsTracker.trackNetworkRequest();
      }
    } catch (e) {
      dev.log('Error processing log for stats: $e');
    }
  }
}
