/// Mathematical operations supported by the app
library;

import 'package:hive/hive.dart';

part 'operation_type.g.dart';

@HiveType(typeId: 2)
enum OperationType {
  @HiveField(0)
  addition('Plusraketer', '+', '🚀'),

  @HiveField(1)
  subtraction('Minusgrottor', '-', '🕳️'),

  @HiveField(2)
  multiplication('Gånger-djungeln', '×', '🌿'),

  @HiveField(3)
  division('Delat-isbanan', '÷', '🧊'),

  @HiveField(4)
  mixed('Mix-äventyret', '?', '🧩');

  const OperationType(this.displayName, this.symbol, this.emoji);

  final String displayName;
  final String symbol;
  final String emoji;
}
