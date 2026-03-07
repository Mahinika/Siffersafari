import '../../domain/entities/quest.dart';
import '../../domain/entities/story_progress.dart';
import '../../domain/enums/difficulty_level.dart';

class StoryProgressionService {
  const StoryProgressionService();

  static const _landmarks = <_LandmarkData>[
    _LandmarkData(
      'Startlägret',
      'Ett tryggt basläger vid djungelns kant.',
      'baslager',
    ),
    _LandmarkData(
      'Fruktgläntan',
      'Mogna sifferfrukter hänger tätt i träden.',
      'frukt',
    ),
    _LandmarkData(
      'Skuggstigen',
      'En smal stig där ledtrådarna gömmer sig i skuggan.',
      'skugga',
    ),
    _LandmarkData(
      'Djungelbron',
      'En gungande bro över de brusande trädkronorna.',
      'bro',
    ),
    _LandmarkData(
      'Kartlägret',
      'Gamla kartbitar visar vägen vidare inåt.',
      'karta',
    ),
    _LandmarkData(
      'Forsgläntan',
      'Vattnet dånar och siffrorna måste fångas i farten.',
      'fors',
    ),
    _LandmarkData(
      'Tempelporten',
      'Stora stenar markerar vägen till något större.',
      'tempel',
    ),
    _LandmarkData(
      'Soltemplet',
      'Det gyllene templet väntar längst in i djungeln.',
      'soltempel',
    ),
    _LandmarkData(
      'Ormbunksängen',
      'Höga ormbunkar döljer nya spår i marken.',
      'skog',
    ),
    _LandmarkData(
      'Trumgläntan',
      'Djupa rytmer ekar mellan träden.',
      'trumma',
    ),
    _LandmarkData(
      'Månporten',
      'En stenbåge markerar vägen vidare i skymningen.',
      'port',
    ),
    _LandmarkData(
      'Safirfallet',
      'Kallt vatten glittrar mellan klipporna.',
      'fors',
    ),
    _LandmarkData(
      'Kartutkiken',
      'Härifrån syns flera stigar samtidigt.',
      'karta',
    ),
    _LandmarkData(
      'Skattkammaren',
      'Gamla kistor och symboler täcker marken.',
      'skatt',
    ),
    _LandmarkData(
      'Väktartrappan',
      'Stegen uppåt kräver mod och skärpa.',
      'tempel',
    ),
    _LandmarkData(
      'Solterrassen',
      'Ljusstrålar visar den sista delen av stigen.',
      'soltempel',
    ),
    _LandmarkData(
      'Lägercirkeln',
      'Expeditionen samlar kraft inför nästa etapp.',
      'baslager',
    ),
    _LandmarkData(
      'Mangolunden',
      'Färska frukter markerar en trygg rastplats.',
      'frukt',
    ),
    _LandmarkData(
      'Skymningsstigen',
      'Solen sjunker men ledtrådarna lyser upp vägen.',
      'skugga',
    ),
    _LandmarkData(
      'Guldbron',
      'Den sista bron leder rakt mot målet.',
      'bro',
    ),
  ];

  StoryProgress build({
    required List<QuestDefinition> path,
    required QuestStatus currentStatus,
    required Set<String> completedQuestIds,
    String? notice,
  }) {
    final effectivePath =
        path.isNotEmpty ? path : <QuestDefinition>[currentStatus.quest];

    var currentNodeIndex = 0;
    for (var i = 0; i < effectivePath.length; i++) {
      if (effectivePath[i].id == currentStatus.quest.id) {
        currentNodeIndex = i;
        break;
      }
    }

    final completedNodes = effectivePath
        .where((quest) => completedQuestIds.contains(quest.id))
        .length;

    final nodes = List<StoryNode>.generate(effectivePath.length, (index) {
      final quest = effectivePath[index];
      final landmark = _landmarks[index % _landmarks.length];
      final state = completedQuestIds.contains(quest.id)
          ? StoryNodeState.completed
          : index == currentNodeIndex
              ? StoryNodeState.current
              : StoryNodeState.upcoming;

      return StoryNode(
        id: quest.id,
        title: quest.title,
        operation: quest.operation,
        difficulty: quest.difficulty,
        state: state,
        landmark: landmark.name,
        landmarkHint: landmark.hint,
        sceneTag: landmark.sceneTag,
        stepIndex: index,
      );
    });

    return StoryProgress(
      worldTitle: 'Ville i djungeln',
      worldSubtitle: 'Följ stigen genom djungeln och lås upp nya platser.',
      chapterTitle: _chapterTitleFor(currentStatus.quest.difficulty),
      currentObjectiveTitle: currentStatus.quest.title,
      currentObjectiveDescription: currentStatus.quest.description,
      progress: currentStatus.progress.clamp(0.0, 1.0),
      completedNodes: completedNodes,
      totalNodes: effectivePath.length,
      currentNodeIndex: currentNodeIndex,
      nodes: nodes,
      notice: notice,
    );
  }

  String _chapterTitleFor(DifficultyLevel difficulty) {
    switch (difficulty.name) {
      case 'easy':
        return 'Kapitel 1: Den första stigen';
      case 'medium':
        return 'Kapitel 2: Djupare in i jungeln';
      case 'hard':
        return 'Kapitel 3: Templet i dimman';
    }

    return 'Junglexpediton';
  }
}

class _LandmarkData {
  const _LandmarkData(this.name, this.hint, this.sceneTag);

  final String name;
  final String hint;
  final String sceneTag;
}
