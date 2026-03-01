/// App feature toggles.
///
/// Keep these simple and local (offline-first). For experiments, prefer wiring
/// through constructors so tests can enable/disable deterministically.
class AppFeatures {
  AppFeatures._();

  /// Enables word problems (textuppgifter) in the quiz question generator.
  ///
  /// Note: Only applies when `gradeLevel` is set (Åk 1–3) and operation is +/−.
  static const bool wordProblemsEnabled = true;

  /// Chance (0.0–1.0) that a generated question becomes a word problem when
  /// supported for the current grade/operation.
  static const double wordProblemsChance = 0.35;

  /// Enables “saknat tal” (missing number) questions.
  ///
  /// Note: Only applies when `gradeLevel` is set (Åk 2–3) and operation is +/−.
  /// Implemented without new UI by using `promptText`, e.g. "? + 3 = 10".
  static const bool missingNumberEnabled = true;

  /// Chance (0.0–1.0) that a supported question becomes a missing-number
  /// equation.
  static const double missingNumberChance = 0.20;
}
