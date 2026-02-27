import '../enums/difficulty_level.dart';
import '../enums/mastery_level.dart';
import '../enums/operation_type.dart';

class QuestDefinition {
  const QuestDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.operation,
    required this.difficulty,
    this.requiredMastery = MasteryLevel.proficient,
  });

  final String id;
  final String title;
  final String description;
  final OperationType operation;
  final DifficultyLevel difficulty;
  final MasteryLevel requiredMastery;

  double get threshold => requiredMastery.threshold;
}

class QuestStatus {
  const QuestStatus({
    required this.quest,
    required this.masteryRate,
    required this.progress,
    required this.isCompleted,
  });

  final QuestDefinition quest;
  final double masteryRate;
  final double progress; // 0..1 vs quest threshold
  final bool isCompleted;
}
