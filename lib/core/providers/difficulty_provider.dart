import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/age_group.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';

final ageGroupProvider = StateProvider<AgeGroup>((ref) => AgeGroup.young);

final operationTypeProvider =
    StateProvider<OperationType>((ref) => OperationType.addition);

final difficultyLevelProvider =
    StateProvider<DifficultyLevel>((ref) => DifficultyLevel.easy);
