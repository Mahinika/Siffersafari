import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/data_export_service_provider.dart';
import '../../core/providers/local_storage_repository_provider.dart';
import '../../core/providers/missing_number_settings_provider.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/word_problems_settings_provider.dart';
import '../../domain/enums/operation_type.dart';
import '../widgets/themed_background_scaffold.dart';
import 'parent_pin_screen.dart';
import 'settings_screen.dart';

// region ParentDashboardScreen

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).activeUser;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: const Text('Föräldraläge'),
        actions: [
          IconButton(
            tooltip: 'Inställningar',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings),
          ),
          IconButton(
            tooltip: 'Exportera data (GDPR)',
            onPressed: () => _showExportDialog(context, ref, user?.userId),
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: 'Byt PIN',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ParentPinScreen(forceSetNewPin: true),
                ),
              );
            },
            icon: const Icon(Icons.key),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: user == null
          ? Center(
              child: Text(
                'Ingen aktiv användare',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          : _DashboardBody(userId: user.userId),
    );
  }

  // endregion

  // region Export Dialog Methods

  static void _showExportDialog(
    BuildContext context,
    WidgetRef ref,
    String? userId,
  ) {
    if (userId == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exportera data'),
        content: const Text(
          'Ladda ned dina data i JSON-format. '
          'Alla dina svar och profiluppgifter (men inte lösenord) kommer att sparas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Avbryt'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performExport(context, ref, userId, fullData: false);
            },
            child: const Text('Metadata'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _performExport(context, ref, userId, fullData: true);
            },
            child: const Text('Allt'),
          ),
        ],
      ),
    );
  }

  static Future<void> _performExport(
    BuildContext context,
    WidgetRef ref,
    String userId, {
    required bool fullData,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        title: Text('Exporterar...'),
        content: SizedBox(
          height: 50,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
    );

    try {
      final exportService = ref.read(dataExportServiceProvider);
      final filePath = fullData
          ? await exportService.exportUserDataAsJson(userId)
          : await exportService.exportUserMetadataAsJson(userId);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export slutfört'),
          content: Text(
            'Din data har sparats till:\n\n$filePath\n\n'
            'Filen är en JSON-fil som kan öppnas i valfri textredigerare.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // Close progress dialog

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Exportfel'),
          content: Text('Kunde inte exportera data: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  // endregion
}

// region _DashboardBody Main Widget

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.userId});

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    final user = ref.watch(userProvider).activeUser!;
    final repo = ref.read(localStorageRepositoryProvider);
    final recentHistory = repo.getQuizHistory(userId, limit: 50);
    final history = recentHistory
        .where((s) => s['isComplete'] != false)
        .take(5)
        .toList(growable: false);
    final weakestAreas = _computeWeakestAreas(user.masteryLevels);

    final settingsNotifier = ref.read(parentSettingsProvider.notifier);
    settingsNotifier.ensureLoaded(userId);
    final allowedOps =
        ref.watch(parentSettingsProvider)[userId] ?? _defaultAllowedOps();

    final wordProblemsEnabled = ref.watch(wordProblemsEnabledProvider(userId));
    final wordProblemsNotifier =
        ref.read(wordProblemsEnabledProvider(userId).notifier);

    final missingNumberEnabled =
        ref.watch(missingNumberEnabledProvider(userId));
    final missingNumberNotifier =
        ref.read(missingNumberEnabledProvider(userId).notifier);

    return ListView(
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Översikt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              _StatRow(
                label: 'Totala poäng',
                value: user.totalPoints.toString(),
              ),
              _StatRow(
                label: 'Nivå',
                value: '${user.level} (${user.levelTitle})',
              ),
              _StatRow(
                label: 'Korrekt % (alla frågor)',
                value: '${(user.successRate * 100).toStringAsFixed(0)}%',
              ),
              _StatRow(
                label: 'Streak',
                value: '${user.currentStreak} (max ${user.longestStreak})',
              ),
              _StatRow(
                label: 'Antal quiz',
                value: user.totalQuizzesTaken.toString(),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Anpassningar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Årskurs',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  'Styr svårighetsnivå (Åk 1–9).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtleOnPrimary,
                      ),
                ),
                trailing: DropdownButton<int?>(
                  value: user.gradeLevel,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: onPrimary),
                  underline: const SizedBox.shrink(),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Ingen'),
                    ),
                    ..._gradeItems.map(
                      (g) => DropdownMenuItem<int?>(
                        value: g,
                        child: Text('Åk $g'),
                      ),
                    ),
                  ],
                  onChanged: (value) async {
                    await ref
                        .read(userProvider.notifier)
                        .saveUser(user.copyWith(gradeLevel: value));
                  },
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  'Textuppgifter',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  'Ibland visas en kort text istället för bara tal (Åk 1–3, +/−).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtleOnPrimary,
                      ),
                ),
                value: wordProblemsEnabled,
                activeThumbColor: accentColor,
                activeTrackColor:
                    accentColor.withValues(alpha: AppOpacities.highlightStrong),
                onChanged: (value) {
                  wordProblemsNotifier.setEnabled(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(
                  'Saknat tal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  'Ibland visas en ekvation med ? (Åk 2–3, +/−).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: subtleOnPrimary,
                      ),
                ),
                value: missingNumberEnabled,
                activeThumbColor: accentColor,
                activeTrackColor:
                    accentColor.withValues(alpha: AppOpacities.highlightStrong),
                onChanged: (value) {
                  missingNumberNotifier.setEnabled(value);
                },
              ),
              const Divider(height: 1),
              ..._baseOps().map((op) {
                final isOn = allowedOps.contains(op);
                final canTurnOff = allowedOps.length > 1;
                return SwitchListTile(
                  title: Text(
                    op.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  value: isOn,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(
                    alpha: AppOpacities.highlightStrong,
                  ),
                  onChanged: (!isOn || canTurnOff)
                      ? (value) {
                          settingsNotifier.setOperationAllowed(
                            userId,
                            op,
                            value,
                          );
                        }
                      : null,
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Analys',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Förklaring av % i föräldraläget:\n'
                '• Korrekt % (alla frågor): alla svar sedan start.\n'
                '• Förslag (steg): räknas per räknesätt på senaste ${DifficultyConfig.trainingRecommendationMinQuestions} frågor (höj vid >85%, sänk vid <75%).\n'
                '• Rekommenderad övning (t.ex. Plus • Lätt 89%): snitt per kategori (räknesätt + Lätt/Medel/Svår) från quiz-resultat — påverkar inte steg.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: subtleOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              if (user.gradeLevel == null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.defaultPadding,
                  ),
                  child: Text(
                    'Sätt Årskurs (Åk) för att få en enkel Under/I linje/Över-indikator.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppConstants.defaultPadding,
                  ),
                  child: _BenchmarkSection(
                    userId: user.userId,
                    gradeLevel: user.gradeLevel!,
                    allowedOperations: allowedOps,
                    storedSteps: user.operationDifficultySteps,
                    quizHistory: recentHistory,
                  ),
                ),
              if (weakestAreas.isEmpty)
                Text(
                  'Spela några quiz till för att få rekommendationer.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else ...[
                Text(
                  'Rekommenderad övning:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                ...weakestAreas.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppConstants.microSpacing6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          '${(a.rate * 100).toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppConstants.defaultPadding),
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Senaste quiz',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              if (history.isEmpty)
                Text(
                  'Ingen historik än',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else
                ...history.map((h) => _HistoryRow(history: h)),
            ],
          ),
        ),
      ],
    );
  }

  List<_WeakArea> _computeWeakestAreas(Map<String, double> masteryLevels) {
    if (masteryLevels.isEmpty) return const [];

    final entries = masteryLevels.entries
        .where((e) => e.value.isFinite)
        .map(
          (e) => _WeakArea(
            key: e.key,
            rate: e.value.clamp(0.0, 1.0),
            label: _prettyMasteryKey(e.key),
          ),
        )
        .toList();

    entries.sort((a, b) => a.rate.compareTo(b.rate));
    return entries.take(3).toList();
  }

  String _prettyMasteryKey(String key) {
    final parts = key.split('_');
    if (parts.length < 2) return key;
    final operation = parts[0];
    final difficulty = parts[1];

    return '${_pretty(operation)} • ${_pretty(difficulty)}';
  }

  String _pretty(String raw) {
    // Convert enum-like values to readable Swedish-ish labels.
    switch (raw) {
      case 'addition':
        return 'Plus';
      case 'subtraction':
        return 'Minus';
      case 'multiplication':
        return 'Gånger';
      case 'division':
        return 'Delat';
      case 'easy':
        return 'Lätt';
      case 'medium':
        return 'Medel';
      case 'hard':
        return 'Svår';
      default:
        return raw;
    }
  }

  Set<OperationType> _defaultAllowedOps() {
    return _baseOps().toSet();
  }

  List<OperationType> _baseOps() {
    return const [
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    ];
  }
}

// endregion

// region Helper Classes

class _WeakArea {
  const _WeakArea({
    required this.key,
    required this.rate,
    required this.label,
  });

  final String key;
  final double rate;
  final String label;
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: AppOpacities.panelFill),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: child,
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.microSpacing6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedOnPrimary,
                  ),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.history});

  final Map<String, dynamic> history;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final operation = (history['operationType'] as String?) ?? '-';
    final difficulty = (history['difficulty'] as String?) ?? '-';
    final correct = (history['correctAnswers'] as int?) ?? 0;
    final total = (history['totalQuestions'] as int?) ?? 0;
    final pointsWithBonus = (history['pointsWithBonus'] as int?) ??
        ((history['points'] as int?) ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppConstants.microSpacing8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_pretty(operation)} • ${_pretty(difficulty)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: mutedOnPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '$correct/$total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '$pointsWithBonus p',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _pretty(String raw) {
    // Convert enum-like values to readable Swedish-ish labels.
    switch (raw) {
      case 'addition':
        return 'Plus';
      case 'subtraction':
        return 'Minus';
      case 'multiplication':
        return 'Gånger';
      case 'division':
        return 'Delat';
      case 'easy':
        return 'Lätt';
      case 'medium':
        return 'Medel';
      case 'hard':
        return 'Svår';
      default:
        return raw;
    }
  }
}

// endregion

// region _BenchmarkSection Widget

class _BenchmarkSection extends ConsumerWidget {
  const _BenchmarkSection({
    required this.userId,
    required this.gradeLevel,
    required this.allowedOperations,
    required this.storedSteps,
    required this.quizHistory,
  });

  final String userId;
  final int gradeLevel;
  final Set<OperationType> allowedOperations;
  final Map<String, int> storedSteps;
  final List<Map<String, dynamic>> quizHistory;

  ({double? rate, int answered}) _successRateFromLatestQuestions(
    OperationType op,
  ) {
    var correct = 0;
    var total = 0;

    for (final s in quizHistory) {
      if (s['operationType'] != op.name) continue;

      final cRaw = s['correctAnswers'];
      final tRaw = s['totalQuestions'];
      final c = cRaw is num ? cRaw.toInt() : int.tryParse('$cRaw');
      final t = tRaw is num ? tRaw.toInt() : int.tryParse('$tRaw');
      if (c == null || t == null || t <= 0) continue;

      correct += c;
      total += t;

      if (total >= DifficultyConfig.trainingRecommendationMinQuestions) {
        break;
      }
    }

    if (total <= 0) {
      return (rate: null, answered: 0);
    }
    return (rate: correct / total, answered: total);
  }

  String _percentLabel(double rate) {
    return '${(rate * 100).toStringAsFixed(0)}%';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    final user = ref.watch(userProvider).activeUser;

    final ops = <OperationType>[
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    ].where(allowedOperations.contains).toList(growable: false);

    Future<void> updateStep(OperationType op, int delta) async {
      final currentUser = user;
      if (currentUser == null || currentUser.userId != userId) return;

      final currentStoredSteps = currentUser.operationDifficultySteps;
      final currentStep = DifficultyConfig.clampDifficultyStep(
        currentStoredSteps[op.name] ?? DifficultyConfig.minDifficultyStep,
      );
      final nextStep =
          DifficultyConfig.clampDifficultyStep(currentStep + delta);
      if (nextStep == currentStep) return;

      final updatedSteps = {
        ...currentStoredSteps,
        op.name: nextStep,
      };

      await ref.read(userProvider.notifier).saveUser(
            currentUser.copyWith(operationDifficultySteps: updatedSteps),
          );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Skolverket-indikator (Åk $gradeLevel)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: mutedOnPrimary,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Baserat på appens interna nivå (steg 1–10) per räknesätt.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtleOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.microSpacing2),
        Text(
          'Förslag kommer efter minst ${DifficultyConfig.trainingRecommendationMinQuestions} frågor (mål: 85% rätt).',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtleOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.microSpacing2),
        Text(
          'Obs: Steg ändras aldrig automatiskt — du väljer själv Lättare/Svårare.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtleOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        ...ops.map((op) {
          final stored = storedSteps[op.name];
          final currentStep = DifficultyConfig.clampDifficultyStep(
            stored ?? DifficultyConfig.minDifficultyStep,
          );
          final stats = _successRateFromLatestQuestions(op);
          final hasEnough = stats.answered >=
              DifficultyConfig.trainingRecommendationMinQuestions;

          final recommendedStep = !hasEnough
              ? null
              : DifficultyConfig.recommendedDifficultyStepForTraining(
                  currentStep: currentStep,
                  averageSuccessRate: stats.rate,
                );

          // Make the Under/I linje/Över indicator reflect the child's answers
          // when we have enough underlag, without auto-changing the stored step.
          final indicatorStep = recommendedStep ?? currentStep;

          final benchmark = DifficultyConfig.compareDifficultyStepToGrade(
            gradeLevel: gradeLevel,
            operation: op,
            difficultyStep: indicatorStep,
          );

          final valueText =
              DifficultyConfig.benchmarkLevelLabel(benchmark.level);
          final recommendationText =
              DifficultyConfig.benchmarkRecommendationText(
            level: benchmark.level,
            operation: op,
          );

          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.microSpacing6,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        op.displayName,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: mutedOnPrimary,
                            ),
                      ),
                    ),
                    const SizedBox(width: AppConstants.smallPadding),
                    Text(
                      valueText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Padding(
                  padding:
                      const EdgeInsets.only(top: AppConstants.microSpacing4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (stats.rate != null)
                        Text(
                          hasEnough
                              ? 'Underlag (senaste ${DifficultyConfig.trainingRecommendationMinQuestions} frågor): ${_percentLabel(stats.rate!)} rätt.'
                              : 'Underlag: ${stats.answered}/${DifficultyConfig.trainingRecommendationMinQuestions} frågor (just nu: ${_percentLabel(stats.rate!)} rätt).',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      if (stats.rate != null)
                        const SizedBox(height: AppConstants.microSpacing2),
                      if (recommendedStep != null)
                        Text(
                          '${op.displayName}: Steg $currentStep • Förslag (utifrån barnets svar): Steg $recommendedStep',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        )
                      else
                        Text(
                          '${op.displayName}: Steg $currentStep • Spela minst ${DifficultyConfig.trainingRecommendationMinQuestions} frågor för ett förslag.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      if (recommendedStep != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppConstants.microSpacing2,
                          ),
                          child: Text(
                            'Indikatorn (Under/I linje/Över) bygger nu på förslaget (Steg $recommendedStep).',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: subtleOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      const SizedBox(height: AppConstants.microSpacing6),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (currentStep <=
                                      DifficultyConfig.minDifficultyStep)
                                  ? null
                                  : () => updateStep(op, -1),
                              child: const Text('Lättare'),
                            ),
                          ),
                          const SizedBox(width: AppConstants.smallPadding),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: (currentStep >=
                                      DifficultyConfig.maxDifficultyStep)
                                  ? null
                                  : () => updateStep(op, 1),
                              child: const Text('Svårare'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (benchmark.level != GradeBenchmarkLevel.inline &&
                    recommendationText.isNotEmpty)
                  Padding(
                    padding:
                        const EdgeInsets.only(top: AppConstants.microSpacing2),
                    child: Text(
                      recommendationText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtleOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

// endregion
