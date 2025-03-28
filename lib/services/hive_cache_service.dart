import 'package:hive_flutter/hive_flutter.dart';
import 'package:espn_app/models/hive_cache_entry.dart';

class HiveCacheService {
  static const String _boxName = 'apiCacheBox';
  late Box<HiveCacheEntry> _box;

  static final HiveCacheService _instance = HiveCacheService._internal();
  factory HiveCacheService() => _instance;
  HiveCacheService._internal();

  static Future<void> init() async {
    _instance._box = await Hive.openBox<HiveCacheEntry>(_boxName);
    _instance._cleanExpiredEntries();
  }

  Box<HiveCacheEntry> get box => _box;

  void _cleanExpiredEntries() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiredKeys =
        _box.keys.where((key) {
          final entry = _box.get(key);
          return entry != null && entry.expiryTimestamp < now;
        }).toList();

    if (expiredKeys.isNotEmpty) {
      _box.deleteAll(expiredKeys);
    }
  }

  Future<void> clearAll() async {
    await _box.clear();
  }

  Future<void> invalidate(String key) async {
    if (_box.containsKey(key)) {
      await _box.delete(key);
    }
  }

  Future<void> dispose() async {
    await _box.close();
  }
}
