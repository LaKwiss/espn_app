import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'package:espn_app/models/hive_cache_entry.dart';
import 'package:espn_app/providers/provider_factory.dart';
import 'package:espn_app/services/hive_cache_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client _client;
  final HiveCacheService? _cacheService;
  final bool _cacheEnabled;
  final Duration _defaultCacheDuration;
  final bool _logCacheHits;
  final Ref? _providerRef;

  ApiService({
    http.Client? client,
    HiveCacheService? cacheService,
    bool cacheEnabled = true,
    Duration? defaultCacheDuration,
    bool logCacheHits = true,
    Ref? providerRef,
  }) : _client = client ?? http.Client(),
       _cacheService = cacheService,
       _cacheEnabled = cacheEnabled,
       _defaultCacheDuration = defaultCacheDuration ?? const Duration(hours: 4),
       _logCacheHits = logCacheHits,
       _providerRef = providerRef;

  void _logRequest(
    String method,
    String url,
    String source, {
    String? details,
    String? cacheDuration,
  }) {
    final logMessage = StringBuffer();
    logMessage.write('📡 $method $url');
    logMessage.write(' [Source: 🔵 $source]');

    if (cacheDuration != null) {
      logMessage.write(' [Cache duration: $cacheDuration]');
    }

    if (details != null) {
      logMessage.write(' - $details');
    }

    dev.log(logMessage.toString());
  }

  void _updateStats(String statType) {
    if (_providerRef == null) return;

    try {
      final statsTracker = _providerRef.read(cacheStatsProvider);

      switch (statType) {
        case 'hit':
          statsTracker.trackCacheHit();
          break;
        case 'miss':
          statsTracker.trackCacheMiss();
          break;
        case 'expired':
          statsTracker.trackCacheExpired();
          break;
        case 'network':
          statsTracker.trackNetworkRequest();
          break;
      }
    } catch (e) {
      dev.log('Error updating cache stats: $e');
    }
  }

  Future<http.Response> get(
    String url, {
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    if (!_cacheEnabled || _cacheService == null || !useCache) {
      _logRequest('GET', url, 'NETWORK', details: 'Cache disabled or skipped');
      _updateStats('network');
      return await _client.get(Uri.parse(url));
    }

    final cacheKey = url;

    final cachedEntry = _cacheService.box.get(cacheKey);

    if (cachedEntry != null && !cachedEntry.isExpired) {
      if (_logCacheHits) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(
          cachedEntry.expiryTimestamp,
        );
        final now = DateTime.now();
        final expiresIn = expiry.difference(now);
        _logRequest(
          'GET',
          url,
          'CACHE HIT ✅',
          details:
              'Expires in ${expiresIn.inMinutes} min (${expiresIn.inHours} hours)',
        );
      }

      _updateStats('hit');

      return http.Response(
        cachedEntry.body,
        cachedEntry.statusCode,
        headers: cachedEntry.headers,
      );
    }

    if (_logCacheHits) {
      if (cachedEntry != null) {
        _logRequest(
          'GET',
          url,
          'CACHE EXPIRED ⏰',
          details: 'Fetching from network',
        );
        _updateStats('expired');
      } else {
        _logRequest(
          'GET',
          url,
          'CACHE MISS ❌',
          details: 'Fetching from network',
        );
        _updateStats('miss');
      }
    }

    _updateStats('network');
    final response = await _client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final effectiveCacheDuration = cacheDuration ?? _defaultCacheDuration;
      final expiryTimestamp =
          DateTime.now().millisecondsSinceEpoch +
          effectiveCacheDuration.inMilliseconds;

      final cacheEntry = HiveCacheEntry(
        body: response.body,
        statusCode: response.statusCode,
        headers: response.headers,
        expiryTimestamp: expiryTimestamp,
      );

      await _cacheService.box.put(cacheKey, cacheEntry);

      if (_logCacheHits) {
        _logRequest(
          'GET',
          url,
          'NETWORK STORED 💾',
          cacheDuration:
              '${effectiveCacheDuration.inHours}h ${effectiveCacheDuration.inMinutes % 60}m',
        );
      }
    }

    return response;
  }

  Future<http.Response> post(
    String url,
    dynamic body, {
    bool cacheable = false,
    Duration? cacheDuration,
  }) async {
    if (!cacheable) {
      _logRequest('POST', url, 'NETWORK', details: 'Not cacheable');
      _updateStats('network');
    }

    final response = await _client.post(
      Uri.parse(url),
      body: body,
      headers: {'Content-Type': 'application/json'},
    );

    if (_cacheEnabled &&
        _cacheService != null &&
        cacheable &&
        response.statusCode == 200) {
      final effectiveCacheDuration = cacheDuration ?? _defaultCacheDuration;
      final expiryTimestamp =
          DateTime.now().millisecondsSinceEpoch +
          effectiveCacheDuration.inMilliseconds;

      final cacheEntry = HiveCacheEntry(
        body: response.body,
        statusCode: response.statusCode,
        headers: response.headers,
        expiryTimestamp: expiryTimestamp,
      );

      final cacheKey = "${url}_${jsonEncode(body)}";
      await _cacheService.box.put(cacheKey, cacheEntry);

      if (_logCacheHits) {
        _logRequest(
          'POST',
          url,
          'NETWORK STORED 💾',
          cacheDuration:
              '${effectiveCacheDuration.inHours}h ${effectiveCacheDuration.inMinutes % 60}m',
        );
      }
    }

    return response;
  }

  Future<void> invalidateCache(String url) async {
    if (_cacheEnabled && _cacheService != null) {
      await _cacheService.invalidate(url);
      if (_logCacheHits) {
        _logRequest('INVALIDATE', url, 'CACHE CLEARED 🗑️');
      }
    }
  }

  bool shouldCacheResponse(http.Response response) {
    final contentType = response.headers['content-type'] ?? '';

    return response.statusCode == 200 &&
        (contentType.contains('application/json') ||
            contentType.contains('image/') ||
            contentType.contains('text/css') ||
            contentType.contains('text/html'));
  }

  void dispose() {
    _client.close();
  }
}
