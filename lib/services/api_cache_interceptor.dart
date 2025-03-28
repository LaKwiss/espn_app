import 'dart:developer' as dev;
import 'package:espn_app/providers/provider_factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A class to intercept and process API logs for cache statistics
class ApiLogInterceptor {
  final Ref ref;

  ApiLogInterceptor(this.ref) {
    // Set up the log intercept in debug mode only
    if (kDebugMode) {
      _setupLogInterceptor();
    }
  }

  void _setupLogInterceptor() {
    // We can't directly intercept the developer.log calls,
    // but we can set up a listener for Zone error/log handling
    // in a more complex implementation

    // For simplicity, we'll modify our API service to directly
    // update the stats tracker when it logs cache events
    // This will require a small change to the ApiService
  }

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
