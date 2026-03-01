import '../../domain/entities/quest.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/mastery_level.dart';
import '../../domain/enums/operation_type.dart';

typedef QuestPath = List<QuestDefinition>;

class QuestProgressionService {
  const QuestProgressionService();

  static const List<QuestDefinition> defaultQuests = [
    QuestDefinition(
      id: 'q_plus_easy',
      title: 'Samla sifferfrukter',
      description: 'Bli skicklig på plus (lätt).',
      operation: OperationType.addition,
      difficulty: DifficultyLevel.easy,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_minus_easy',
      title: 'Hitta borttappade siffror',
      description: 'Bli skicklig på minus (lätt).',
      operation: OperationType.subtraction,
      difficulty: DifficultyLevel.easy,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_times_easy',
      title: 'Bygg ditt basläger',
      description: 'Bli skicklig på gånger (lätt).',
      operation: OperationType.multiplication,
      difficulty: DifficultyLevel.easy,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_div_easy',
      title: 'Dela upp skattkistan',
      description: 'Bli skicklig på delat (lätt).',
      operation: OperationType.division,
      difficulty: DifficultyLevel.easy,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_plus_medium',
      title: 'Kartlägg nya stigar',
      description: 'Bli skicklig på plus (medel).',
      operation: OperationType.addition,
      difficulty: DifficultyLevel.medium,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_minus_medium',
      title: 'Undvik snubbelstenar',
      description: 'Bli skicklig på minus (medel).',
      operation: OperationType.subtraction,
      difficulty: DifficultyLevel.medium,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_times_medium',
      title: 'Tämj djungelbron',
      description: 'Bli skicklig på gånger (medel).',
      operation: OperationType.multiplication,
      difficulty: DifficultyLevel.medium,
      requiredMastery: MasteryLevel.proficient,
    ),
    QuestDefinition(
      id: 'q_div_medium',
      title: 'Räkna ut ransoner',
      description: 'Bli skicklig på delat (medel).',
      operation: OperationType.division,
      difficulty: DifficultyLevel.medium,
      requiredMastery: MasteryLevel.proficient,
    ),
  ];

  QuestPath questsForUser(
    UserProgress user, {
    Set<OperationType>? allowedOperations,
  }) {
    final grade = user.gradeLevel;

    QuestPath basePath;

    // Grade-based paths (recommended guidance). Keep it simple and predictable.
    // - Åk 1-2: only Easy
    // - Åk 3-4: Easy + Medium
    // - Åk 5+: Easy + Medium (Hard quests can be added later)
    if (grade != null) {
      if (grade <= 2) {
        basePath = defaultQuests
            .where((q) => q.difficulty == DifficultyLevel.easy)
            .toList(growable: false);
        return _applyAllowedOperations(
          basePath: basePath,
          allowedOperations: allowedOperations,
        );
      }
      if (grade <= 4) {
        basePath = defaultQuests
            .where(
              (q) =>
                  q.difficulty == DifficultyLevel.easy ||
                  q.difficulty == DifficultyLevel.medium,
            )
            .toList(growable: false);
        return _applyAllowedOperations(
          basePath: basePath,
          allowedOperations: allowedOperations,
        );
      }
      basePath = defaultQuests
          .where(
            (q) =>
                q.difficulty == DifficultyLevel.easy ||
                q.difficulty == DifficultyLevel.medium,
          )
          .toList(growable: false);
      return _applyAllowedOperations(
        basePath: basePath,
        allowedOperations: allowedOperations,
      );
    }

    // Fallback: age group
    switch (user.ageGroup) {
      case AgeGroup.young:
        basePath = defaultQuests
            .where((q) => q.difficulty == DifficultyLevel.easy)
            .toList(growable: false);
        return _applyAllowedOperations(
          basePath: basePath,
          allowedOperations: allowedOperations,
        );
      case AgeGroup.middle:
        basePath = defaultQuests
            .where(
              (q) =>
                  q.difficulty == DifficultyLevel.easy ||
                  q.difficulty == DifficultyLevel.medium,
            )
            .toList(growable: false);
        return _applyAllowedOperations(
          basePath: basePath,
          allowedOperations: allowedOperations,
        );
      case AgeGroup.older:
        basePath = defaultQuests
            .where(
              (q) =>
                  q.difficulty == DifficultyLevel.easy ||
                  q.difficulty == DifficultyLevel.medium,
            )
            .toList(growable: false);
        return _applyAllowedOperations(
          basePath: basePath,
          allowedOperations: allowedOperations,
        );
    }
  }

  QuestPath _applyAllowedOperations({
    required QuestPath basePath,
    required Set<OperationType>? allowedOperations,
  }) {
    final allowed = allowedOperations;
    if (allowed == null) return basePath;

    final filtered = basePath
        .where((q) => allowed.contains(q.operation))
        .toList(growable: false);

    // If filtering would remove everything (should be rare), keep base path.
    return filtered.isEmpty ? basePath : filtered;
  }

  QuestDefinition? questById({required QuestPath path, required String id}) {
    for (final q in path) {
      if (q.id == id) return q;
    }
    return null;
  }

  String firstQuestId(
    UserProgress user, {
    Set<OperationType>? allowedOperations,
  }) {
    final path = questsForUser(user, allowedOperations: allowedOperations);
    return (path.isNotEmpty ? path.first : defaultQuests.first).id;
  }

  QuestStatus getCurrentStatus({
    required UserProgress user,
    required String? currentQuestId,
    required Set<String> completedQuestIds,
    Set<OperationType>? allowedOperations,
  }) {
    final path = questsForUser(user, allowedOperations: allowedOperations);
    final effectivePath = path.isNotEmpty ? path : defaultQuests;

    QuestDefinition quest;

    final byId = currentQuestId == null
        ? null
        : questById(path: effectivePath, id: currentQuestId);
    if (byId != null && !completedQuestIds.contains(byId.id)) {
      quest = byId;
    } else {
      quest = effectivePath.firstWhere(
        (q) => !completedQuestIds.contains(q.id),
        orElse: () => effectivePath.last,
      );
    }

    final masteryKey = '${quest.operation.name}_${quest.difficulty.name}';
    final rate = (user.masteryLevels[masteryKey] ?? 0.0).clamp(0.0, 1.0);
    final threshold = quest.threshold;

    final progress = threshold <= 0 ? 0.0 : (rate / threshold).clamp(0.0, 1.0);

    return QuestStatus(
      quest: quest,
      masteryRate: rate,
      progress: progress,
      isCompleted: rate >= threshold,
    );
  }

  String? nextQuestId({
    required UserProgress user,
    required String currentQuestId,
    Set<OperationType>? allowedOperations,
  }) {
    final path = questsForUser(user, allowedOperations: allowedOperations);
    final effectivePath = path.isNotEmpty ? path : defaultQuests;

    for (var i = 0; i < effectivePath.length; i++) {
      if (effectivePath[i].id == currentQuestId) {
        final nextIndex = i + 1;
        if (nextIndex >= effectivePath.length) return null;
        return effectivePath[nextIndex].id;
      }
    }
    return null;
  }
}
