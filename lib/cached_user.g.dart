// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_user.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedUserAdapter extends TypeAdapter<CachedUser> {
  @override
  final int typeId = 0;

  @override
  CachedUser read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedUser(
      displayName: fields[0] as String,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, CachedUser obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.displayName)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedUserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
