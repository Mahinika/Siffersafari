// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'operation_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OperationTypeAdapter extends TypeAdapter<OperationType> {
  @override
  final int typeId = 2;

  @override
  OperationType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OperationType.addition;
      case 1:
        return OperationType.subtraction;
      case 2:
        return OperationType.multiplication;
      case 3:
        return OperationType.division;
      case 4:
        return OperationType.mixed;
      default:
        return OperationType.addition;
    }
  }

  @override
  void write(BinaryWriter writer, OperationType obj) {
    switch (obj) {
      case OperationType.addition:
        writer.writeByte(0);
        break;
      case OperationType.subtraction:
        writer.writeByte(1);
        break;
      case OperationType.multiplication:
        writer.writeByte(2);
        break;
      case OperationType.division:
        writer.writeByte(3);
        break;
      case OperationType.mixed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
