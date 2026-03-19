import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/services/spaced_repetition_service.dart';

/// Provider for SpacedRepetitionService.
///
/// Manages review schedules for questions to optimize long-term retention.
final spacedRepetitionServiceProvider =
    Provider<SpacedRepetitionService>((ref) {
  return SpacedRepetitionService();
});
