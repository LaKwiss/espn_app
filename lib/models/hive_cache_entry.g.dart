part of 'hive_cache_entry.dart';

class HiveCacheEntryAdapter extends TypeAdapter<HiveCacheEntry> {
  @override
  final int typeId = 0;

  @override
  HiveCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return HiveCacheEntry(
      body: fields[0] as String,
      statusCode: fields[1] as int,
      headers: (fields[2] as Map).cast<String, String>(),
      expiryTimestamp: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCacheEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.body)
      ..writeByte(1)
      ..write(obj.statusCode)
      ..writeByte(2)
      ..write(obj.headers)
      ..writeByte(3)
      ..write(obj.expiryTimestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HiveCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
