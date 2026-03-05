// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'company_user_local.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CompanyUserLocalAdapter extends TypeAdapter<CompanyUserLocal> {
  @override
  final int typeId = 12;

  @override
  CompanyUserLocal read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CompanyUserLocal(
      uid: fields[0] as String,
      companyId: fields[1] as String,
      role: fields[2] as String,
      name: fields[3] as String,
      email: fields[4] as String,
      deviceId: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CompanyUserLocal obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.companyId)
      ..writeByte(2)
      ..write(obj.role)
      ..writeByte(3)
      ..write(obj.name)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.deviceId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompanyUserLocalAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
