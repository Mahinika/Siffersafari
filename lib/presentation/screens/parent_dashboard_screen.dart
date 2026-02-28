import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/enums/operation_type.dart';
import '../widgets/themed_background_scaffold.dart';
import 'parent_pin_screen.dart';
import 'settings_screen.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).activeUser;

    return ThemedBackgroundScaffold(
      overlayOpacity: 0.76,
      appBar: AppBar(
        title: const Text('Föräldraläge'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          : _DashboardBody(userId: user.userId),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.userId});

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final user = ref.watch(userProvider).activeUser!;
    final repo = getIt<LocalStorageRepository>();
    final history = repo.getQuizHistory(userId, limit: 5);
    final weakestAreas = _computeWeakestAreas(user.masteryLevels);

    final settingsNotifier = ref.read(parentSettingsProvider.notifier);
    settingsNotifier.ensureLoaded(userId);
    final allowedOps =
        ref.watch(parentSettingsProvider)[userId] ?? _defaultAllowedOps();

    return ListView(
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Översikt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
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
                label: 'Korrekt % (totalt)',
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Årskurs',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                subtitle: Text(
                  'Styr svårighetsnivå (Åk 1–9).',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                      ),
                ),
                trailing: DropdownButton<int?>(
                  value: user.gradeLevel,
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.white),
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
              const Divider(height: 1, color: Colors.white24),
              ..._baseOps().map((op) {
                final isOn = allowedOps.contains(op);
                final canTurnOff = allowedOps.length > 1;
                return SwitchListTile(
                  title: Text(
                    op.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  value: isOn,
                  activeThumbColor: accentColor,
                  activeTrackColor: accentColor.withValues(alpha: 0.35),
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              if (weakestAreas.isEmpty)
                Text(
                  'Spela några quiz till för att få rekommendationer.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                )
              else ...[
                Text(
                  'Rekommenderad övning:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppConstants.smallPadding),
                ...weakestAreas.map(
                  (a) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.label,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Text(
                          '${(a.rate * 100).toStringAsFixed(0)}%',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white,
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppConstants.smallPadding),
              if (history.isEmpty)
                Text(
                  'Ingen historik än',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
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
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
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
    final operation = (history['operationType'] as String?) ?? '-';
    final difficulty = (history['difficulty'] as String?) ?? '-';
    final correct = (history['correctAnswers'] as int?) ?? 0;
    final total = (history['totalQuestions'] as int?) ?? 0;
    final pointsWithBonus = (history['pointsWithBonus'] as int?) ??
        ((history['points'] as int?) ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${_pretty(operation)} • ${_pretty(difficulty)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Text(
            '$correct/$total',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: AppConstants.smallPadding),
          Text(
            '$pointsWithBonus p',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
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
