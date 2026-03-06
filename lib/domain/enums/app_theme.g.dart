// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_theme.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AppThemeAdapter extends TypeAdapter<AppTheme> {
  @override
  final int typeId = 4;

  @override
  AppTheme read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AppTheme.space;
      case 1:
        return AppTheme.jungle;
      case 2:
        return AppTheme.underwater;
      case 3:
        return AppTheme.fantasy;
      default:
        return AppTheme.space;
    }
  }

  @override
  void write(BinaryWriter writer, AppTheme obj) {
    switch (obj) {
      case AppTheme.space:
        writer.writeByte(0);
        break;
      case AppTheme.jungle:
        writer.writeByte(1);
        break;
      case AppTheme.underwater:
        writer.writeByte(2);
        break;
      case AppTheme.fantasy:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppThemeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
