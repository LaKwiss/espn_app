import 'package:hive/hive.dart';

part 'hive_cache_entry.g.dart';

@HiveType(typeId: 0)
class HiveCacheEntry extends HiveObject {
  @HiveField(0)
  final String body;

  @HiveField(1)
  final int statusCode;

  @HiveField(2)
  final Map<String, String> headers;

  @HiveField(3)
  final int expiryTimestamp;

  HiveCacheEntry({
    required this.body,
    required this.statusCode,
    required this.headers,
    required this.expiryTimestamp,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiryTimestamp;
}
