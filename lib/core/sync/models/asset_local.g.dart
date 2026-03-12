// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetLocalAdapter extends TypeAdapter<AssetLocal> {
  @override
  final int typeId = 11;

  @override
  AssetLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetLocal(
      id: fields[0] as String,
      companyId: fields[1] as String,
      name: fields[2] as String,
      category: fields[3] as String,
      status: fields[4] as String,
      purchasePrice: fields[7] as double,
      currentValue: fields[8] as double,
      depreciationMethod: fields[9] as String,
      version: fields[14] as int,
      updatedAtMs: fields[16] as int,
      location: fields[5] as String?,
      assignedTo: fields[6] as String?,
      department: fields[18] as String?,
      vendor: fields[19] as String?,
      description: fields[10] as String?,
      usefulLife: fields[11] as int?,
      salvageValue: fields[12] as double?,
      purchaseDateMs: fields[13] as int?,
      warrantyExpiryMs: fields[17] as int?,
      latitude: fields[20] as double?,
      longitude: fields[21] as double?,
      lastScannedAtMs: fields[22] as int?,
      isDirty: fields[15] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, AssetLocal obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.companyId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.assignedTo)
      ..writeByte(18)
      ..write(obj.department)
      ..writeByte(19)
      ..write(obj.vendor)
      ..writeByte(7)
      ..write(obj.purchasePrice)
      ..writeByte(8)
      ..write(obj.currentValue)
      ..writeByte(9)
      ..write(obj.depreciationMethod)
      ..writeByte(10)
      ..write(obj.description)
      ..writeByte(11)
      ..write(obj.usefulLife)
      ..writeByte(12)
      ..write(obj.salvageValue)
      ..writeByte(13)
      ..write(obj.purchaseDateMs)
      ..writeByte(14)
      ..write(obj.version)
      ..writeByte(15)
      ..write(obj.isDirty)
      ..writeByte(16)
      ..write(obj.updatedAtMs)
      ..writeByte(17)
      ..write(obj.warrantyExpiryMs)
      ..writeByte(20)
      ..write(obj.latitude)
      ..writeByte(21)
      ..write(obj.longitude)
      ..writeByte(22)
      ..write(obj.lastScannedAtMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
