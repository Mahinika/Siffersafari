/// Mastery level for a concept
library;

import 'package:hive/hive.dart';

part 'mastery_level.g.dart';

@HiveType(typeId: 5)
enum MasteryLevel {
  @HiveField(0)
  notStarted('Ej påbörjat', 0.0),

  @HiveField(1)
  developing('Utvecklar', 0.5),

  @HiveField(2)
  proficient('Skicklig', 0.8),

  @HiveField(3)
  advanced('Avancerad', 0.95);

  const MasteryLevel(this.displayName, this.threshold);

  final String displayName;
  final double threshold; // Success rate threshold
}
