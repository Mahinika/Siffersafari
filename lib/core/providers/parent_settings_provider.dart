import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/local_storage_repository.dart';
import '../../domain/enums/operation_type.dart';
import '../di/injection.dart';

const _baseOperations = <OperationType>[
  OperationType.addition,
  OperationType.subtraction,
  OperationType.multiplication,
  OperationType.division,
];

class ParentSettingsNotifier
    extends StateNotifier<Map<String, Set<OperationType>>> {
  ParentSettingsNotifier(this._repository) : super(const {});

  final LocalStorageRepository _repository;

  static String _allowedOpsKey(String userId) => 'allowed_ops_$userId';

  Set<OperationType> allowedOperationsFor(String userId) {
    return state[userId] ?? _baseOperations.toSet();
  }

  void ensureLoaded(String userId) {
    if (state.containsKey(userId)) return;
    loadAllowedOperations(userId);
  }

  void loadAllowedOperations(String userId) {
    final raw = _repository.getSetting(_allowedOpsKey(userId));

    Set<OperationType> ops;
    if (raw is List) {
      ops = raw
          .whereType<String>()
          .map(_operationFromName)
          .whereType<OperationType>()
          .where((op) => _baseOperations.contains(op))
          .toSet();
    } else {
      ops = _baseOperations.toSet();
    }

    if (ops.isEmpty) {
      ops = _baseOperations.toSet();
    }

    state = {
      ...state,
      userId: ops,
    };
  }

  OperationType? _operationFromName(String name) {
    for (final op in OperationType.values) {
      if (op.name == name) return op;
    }
    return null;
  }

  Future<void> setOperationAllowed(
    String userId,
    OperationType operation,
    bool allowed,
  ) async {
    final current = allowedOperationsFor(userId);

    final updated = {
      ...current,
    };

    if (allowed) {
      updated.add(operation);
    } else {
      updated.remove(operation);
    }

    if (updated.isEmpty) {
      // Never allow an empty set; keep current.
      return;
    }

    state = {
      ...state,
      userId: updated,
    };

    await _repository.saveSetting(
      _allowedOpsKey(userId),
      updated.map((op) => op.name).toList(),
    );
  }
}

final parentSettingsProvider = StateNotifierProvider<ParentSettingsNotifier,
    Map<String, Set<OperationType>>>(
  (ref) {
    final repository = getIt<LocalStorageRepository>();
    return ParentSettingsNotifier(repository);
  },
);
