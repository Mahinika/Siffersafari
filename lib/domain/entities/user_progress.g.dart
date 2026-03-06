// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_progress.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProgressAdapter extends TypeAdapter<UserProgress> {
  @override
  final int typeId = 0;

  @override
  UserProgress read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProgress(
      userId: fields[0] as String,
      name: fields[1] as String,
      ageGroup: fields[2] as AgeGroup,
      avatarEmoji: fields[18] as String,
      gradeLevel: fields[17] as int?,
      totalQuizzesTaken: fields[3] as int,
      totalQuestionsAnswered: fields[4] as int,
      totalCorrectAnswers: fields[5] as int,
      currentStreak: fields[6] as int,
      longestStreak: fields[7] as int,
      totalPoints: fields[8] as int,
      selectedTheme: fields[9] as AppTheme,
      soundEnabled: fields[10] as bool,
      musicEnabled: fields[11] as bool,
      timerEnabled: fields[12] as bool,
      lastSessionDate: fields[13] as DateTime?,
      unlockedThemes: (fields[14] as List).cast<AppTheme>(),
      achievements: (fields[15] as List).cast<String>(),
      masteryLevels: (fields[16] as Map).cast<String, double>(),
      operationDifficultySteps: (fields[19] as Map).cast<String, int>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserProgress obj) {
    writer
      ..writeByte(20)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.ageGroup)
      ..writeByte(18)
      ..write(obj.avatarEmoji)
      ..writeByte(17)
      ..write(obj.gradeLevel)
      ..writeByte(3)
      ..write(obj.totalQuizzesTaken)
      ..writeByte(4)
      ..write(obj.totalQuestionsAnswered)
      ..writeByte(5)
      ..write(obj.totalCorrectAnswers)
      ..writeByte(6)
      ..write(obj.currentStreak)
      ..writeByte(7)
      ..write(obj.longestStreak)
      ..writeByte(8)
      ..write(obj.totalPoints)
      ..writeByte(9)
      ..write(obj.selectedTheme)
      ..writeByte(10)
      ..write(obj.soundEnabled)
      ..writeByte(11)
      ..write(obj.musicEnabled)
      ..writeByte(12)
      ..write(obj.timerEnabled)
      ..writeByte(13)
      ..write(obj.lastSessionDate)
      ..writeByte(14)
      ..write(obj.unlockedThemes)
      ..writeByte(15)
      ..write(obj.achievements)
      ..writeByte(16)
      ..write(obj.masteryLevels)
      ..writeByte(19)
      ..write(obj.operationDifficultySteps);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProgressAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
