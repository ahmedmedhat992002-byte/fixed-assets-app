// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approval_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ApprovalLocalAdapter extends TypeAdapter<ApprovalLocal> {
  @override
  final int typeId = 6;

  @override
  ApprovalLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ApprovalLocal(
      id: fields[0] as String,
      assetId: fields[1] as String,
      requestedBy: fields[2] as String,
      actionType: fields[3] as String,
      status: fields[4] as String,
      approvedBy: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      updatedAt: fields[7] as DateTime,
      details: (fields[8] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, ApprovalLocal obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.assetId)
      ..writeByte(2)
      ..write(obj.requestedBy)
      ..writeByte(3)
      ..write(obj.actionType)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.approvedBy)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.updatedAt)
      ..writeByte(8)
      ..write(obj.details);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ApprovalLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
