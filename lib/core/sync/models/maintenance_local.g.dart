// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MaintenanceLocalAdapter extends TypeAdapter<MaintenanceLocal> {
  @override
  final int typeId = 13;

  @override
  MaintenanceLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MaintenanceLocal(
      id: fields[0] as String,
      assetId: fields[1] as String,
      assetName: fields[2] as String,
      dateMs: fields[3] as int,
      type: fields[4] as String,
      cost: fields[5] as double,
      technician: fields[6] as String?,
      vendor: fields[7] as String?,
      notes: fields[8] as String?,
      status: fields[9] as String,
      updatedAtMs: fields[10] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MaintenanceLocal obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.assetName)
      ..writeByte(3)
      ..write(obj.dateMs)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.cost)
      ..writeByte(6)
      ..write(obj.technician)
      ..writeByte(7)
      ..write(obj.vendor)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.updatedAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MaintenanceLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
