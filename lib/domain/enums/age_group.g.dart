// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'age_group.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AgeGroupAdapter extends TypeAdapter<AgeGroup> {
  @override
  final int typeId = 1;

  @override
  AgeGroup read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AgeGroup.young;
      case 1:
        return AgeGroup.middle;
      case 2:
        return AgeGroup.older;
      default:
        return AgeGroup.young;
    }
  }

  @override
  void write(BinaryWriter writer, AgeGroup obj) {
    switch (obj) {
      case AgeGroup.young:
        writer.writeByte(0);
        break;
      case AgeGroup.middle:
        writer.writeByte(1);
        break;
      case AgeGroup.older:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AgeGroupAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
