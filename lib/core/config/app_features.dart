/// App feature toggles.
///
/// Keep these simple and local (offline-first). For experiments, prefer wiring
/// through constructors so tests can enable/disable deterministically.
class AppFeatures {
  AppFeatures._();

  /// Enables word problems (textuppgifter) in the quiz question generator.
  ///
  /// Default OFF until the content + UX is tuned.
  static const bool wordProblemsEnabled = false;

  /// Chance (0.0–1.0) that a generated question becomes a word problem when
  /// supported for the current grade/operation.
  static const double wordProblemsChance = 0.35;
}
