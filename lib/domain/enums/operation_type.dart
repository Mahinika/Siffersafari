/// Mathematical operations supported by the app
library;

import 'package:hive/hive.dart';

part 'operation_type.g.dart';

@HiveType(typeId: 2)
enum OperationType {
  @HiveField(0)
  addition('Addition', '+', '➕'),

  @HiveField(1)
  subtraction('Subtraktion', '-', '➖'),

  @HiveField(2)
  multiplication('Multiplikation', '×', '✖️'),

  @HiveField(3)
  division('Division', '÷', '➗'),

  @HiveField(4)
  mixed('Blandad', '?', '🔀');

  const OperationType(this.displayName, this.symbol, this.emoji);

  final String displayName;
  final String symbol;
  final String emoji;
}
