// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mastery_level.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MasteryLevelAdapter extends TypeAdapter<MasteryLevel> {
  @override
  final int typeId = 5;

  @override
  MasteryLevel read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return MasteryLevel.notStarted;
      case 1:
        return MasteryLevel.developing;
      case 2:
        return MasteryLevel.proficient;
      case 3:
        return MasteryLevel.advanced;
      default:
        return MasteryLevel.notStarted;
    }
  }

  @override
  void write(BinaryWriter writer, MasteryLevel obj) {
    switch (obj) {
      case MasteryLevel.notStarted:
        writer.writeByte(0);
        break;
      case MasteryLevel.developing:
        writer.writeByte(1);
        break;
      case MasteryLevel.proficient:
        writer.writeByte(2);
        break;
      case MasteryLevel.advanced:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryLevelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
