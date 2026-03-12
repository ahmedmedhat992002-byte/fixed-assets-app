// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_timeline_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetTimelineLocalAdapter extends TypeAdapter<AssetTimelineLocal> {
  @override
  final int typeId = 7;

  @override
  AssetTimelineLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetTimelineLocal(
      id: fields[0] as String,
      assetId: fields[1] as String,
      action: fields[2] as String,
      userId: fields[3] as String?,
      timestamp: fields[4] as DateTime,
      details: (fields[5] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, AssetTimelineLocal obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.action)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.timestamp)
      ..writeByte(5)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetTimelineLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
