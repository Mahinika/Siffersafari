/// Difficulty levels for questions
library;

import 'package:hive/hive.dart';

part 'difficulty_level.g.dart';

@HiveType(typeId: 3)
enum DifficultyLevel {
  @HiveField(0)
  easy('Lätt', 1.0),

  @HiveField(1)
  medium('Medel', 1.5),

  @HiveField(2)
  hard('Svår', 2.0);

  const DifficultyLevel(this.displayName, this.pointMultiplier);

  final String displayName;
  final double pointMultiplier;
}
