/// Age groups for adaptive difficulty
library;

import 'package:hive/hive.dart';

part 'age_group.g.dart';

@HiveType(typeId: 1)
enum AgeGroup {
  @HiveField(0)
  young(6, 8, 'Lågstadiet (6-8 år)'),

  @HiveField(1)
  middle(8, 10, 'Mellanstadiet (8-10 år)'),

  @HiveField(2)
  older(10, 13, 'Högstadiet (10-13 år)');

  const AgeGroup(this.minAge, this.maxAge, this.displayName);

  final int minAge;
  final int maxAge;
  final String displayName;
}
