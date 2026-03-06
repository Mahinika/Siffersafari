import 'dart:async';

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
import '../../core/services/app_update_service.dart';
import '../../core/utils/adaptive_layout.dart';
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
          final maxContentWidth = layout.contentMaxWidth;

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: user == null
                  ? Center(
                      child: Text(
                        'Ingen aktiv användare',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    )
                  : _DashboardBody(userId: user.userId),
            ),
          );
        },
      ),
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
    const sectionSpacing = SizedBox(height: AppConstants.defaultPadding);

    void showInfoDialog({required String title, required String message}) {
      showDialog(
        context: context,
        builder: (ctx) {
          final onPrimary = Theme.of(ctx).colorScheme.onPrimary;
          return AlertDialog(
            title: Text(
              title,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            content: Text(
              message,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: onPrimary),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

    Widget infoButton({required String title, required String message}) {
      final onPrimary = Theme.of(context).colorScheme.onPrimary;
      return IconButton(
        tooltip: 'Förklaring',
        visualDensity: VisualDensity.compact,
        onPressed: () => showInfoDialog(title: title, message: message),
        icon: Icon(Icons.help_outline, color: onPrimary),
      );
    }

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

    final overviewCard = _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Översikt',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
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
    );

    final adaptationsCard = _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Anpassningar',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              infoButton(
                title: 'Anpassningar',
                message:
                    'Här kan du styra vad som kan dyka upp i quiz och vilken nivå som är lagom.\n\nTips: Om du är osäker, börja med att sätta Årskurs och låt resten vara på standard.',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          LayoutBuilder(
            builder: (context, tileConstraints) {
              final tileLayout =
                  AdaptiveLayoutInfo.fromConstraints(tileConstraints);
              final dropdown = DropdownButton<int?>(
                value: user.gradeLevel,
                isExpanded: tileLayout.isCompactWidth,
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
              );

              if (!tileLayout.isCompactWidth) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Årskurs',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      infoButton(
                        title: 'Årskurs',
                        message:
                            'Årskurs används för att välja en lagom nivå och för att kunna visa en enkel Under/I linje/Över-indikator i analysen.\n\nDu kan alltid lämna den tom om du vill.',
                      ),
                      dropdown,
                    ],
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppConstants.smallPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Årskurs',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        infoButton(
                          title: 'Årskurs',
                          message:
                              'Årskurs används för att välja en lagom nivå och för att kunna visa en enkel Under/I linje/Över-indikator i analysen.\n\nDu kan alltid lämna den tom om du vill.',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    DropdownButtonHideUnderline(child: dropdown),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          SwitchListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Textuppgifter',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                infoButton(
                  title: 'Textuppgifter',
                  message:
                      'När detta är på kan vissa frågor visas som en kort text (inte bara siffror).\n\nDet används främst för Åk 1–3 och för Plus/Minus.',
                ),
              ],
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Saknat tal',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                infoButton(
                  title: 'Saknat tal',
                  message:
                      'När detta är på kan vissa frågor vara av typen: 7 + ? = 10.\n\nDet används främst för Åk 2–3 och för Plus/Minus.',
                ),
              ],
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
          Padding(
            padding: const EdgeInsets.only(top: AppConstants.smallPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Räknesätt',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                infoButton(
                  title: 'Räknesätt',
                  message:
                      'Välj vilka räknesätt som får användas i quiz.\n\nMinst ett räknesätt måste vara på.',
                ),
              ],
            ),
          ),
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
    );

    final benchmarkSectionContent = user.gradeLevel == null
        ? Text(
            'Sätt Årskurs (Åk) för att få Under/I linje/Över-indikator.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          )
        : _BenchmarkSection(
            userId: user.userId,
            gradeLevel: user.gradeLevel!,
            allowedOperations: allowedOps,
            storedSteps: user.operationDifficultySteps,
            quizHistory: recentHistory,
          );

    final recommendationSectionContent = weakestAreas.isEmpty
        ? Text(
            'Spela några quiz till för att få rekommendationer.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Rekommenderad övning',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  infoButton(
                    title: 'Rekommenderad övning',
                    message:
                        'Här visas de 3 områden där barnet just nu har lägst träffsäkerhet (t.ex. Plus • Lätt).\n\nDet är en enkel “börja här”-lista: spela gärna några quiz i de områdena och se om procenten förbättras över tid.',
                  ),
                ],
              ),
              const SizedBox(height: AppConstants.smallPadding),
              ...weakestAreas.map(
                (a) => Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.microSpacing6,
                  ),
                  child: _RecommendationRow(area: a),
                ),
              ),
            ],
          );

    final analysisCard = _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Analys',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              infoButton(
                title: 'Hur räknas statistiken?',
                message:
                    'Korrekt % (alla frågor) = alla svar sedan start.\n\nFörslag (steg) räknas per räknesätt på de senaste ${DifficultyConfig.trainingRecommendationMinQuestions} frågorna (mål: 85% rätt).\n\nRekommenderad övning visar snitt per kategori (t.ex. Plus • Lätt) från quiz-resultat. Det ändrar inte steg automatiskt.',
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Tryck på ? för förklaringar.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          LayoutBuilder(
            builder: (context, analysisConstraints) {
              final useSplitAnalysis = analysisConstraints.maxWidth >= 520;

              if (!useSplitAnalysis) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    benchmarkSectionContent,
                    const SizedBox(height: AppConstants.defaultPadding),
                    recommendationSectionContent,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _InsetPanel(
                      child: benchmarkSectionContent,
                    ),
                  ),
                  const SizedBox(width: AppConstants.defaultPadding),
                  Expanded(
                    child: _InsetPanel(
                      child: recommendationSectionContent,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );

    final historyCard = _Card(
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
            LayoutBuilder(
              builder: (context, historyConstraints) {
                final useHistoryGrid =
                    historyConstraints.maxWidth >= 520 && history.length > 1;

                if (!useHistoryGrid) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: history
                        .map((h) => _HistoryRow(history: h))
                        .toList(growable: false),
                  );
                }

                final itemWidth = (historyConstraints.maxWidth -
                        AppConstants.defaultPadding) /
                    2;

                return Wrap(
                  spacing: AppConstants.defaultPadding,
                  runSpacing: AppConstants.defaultPadding,
                  children: history
                      .map(
                        (h) => SizedBox(
                          width: itemWidth,
                          child: _HistoryTile(history: h),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = AdaptiveLayoutInfo.fromConstraints(constraints);

        if (!layout.isExpandedWidth) {
          return ListView(
            children: [
              overviewCard,
              sectionSpacing,
              const _UpdateSectionCard(),
              sectionSpacing,
              adaptationsCard,
              sectionSpacing,
              analysisCard,
              sectionSpacing,
              historyCard,
            ],
          );
        }

        return SingleChildScrollView(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    overviewCard,
                    sectionSpacing,
                    const _UpdateSectionCard(),
                    sectionSpacing,
                    historyCard,
                  ],
                ),
              ),
              const SizedBox(width: AppConstants.defaultPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    adaptationsCard,
                    sectionSpacing,
                    analysisCard,
                  ],
                ),
              ),
            ],
          ),
        );
      },
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

class _UpdateSectionCard extends StatefulWidget {
  const _UpdateSectionCard();

  @override
  State<_UpdateSectionCard> createState() => _UpdateSectionCardState();
}

class _UpdateSectionCardState extends State<_UpdateSectionCard> {
  final AppUpdateService _appUpdateService = AppUpdateService();
  bool _isChecking = false;
  bool _isInstalling = false;
  String? _installedVersion;
  String? _errorMessage;
  String? _installMessage;
  int? _installProgress;
  AppUpdateInfo? _latestRelease;
  StreamSubscription<AppUpdateInstallProgress>? _installSubscription;

  @override
  void initState() {
    super.initState();
    _loadInstalledVersion();
  }

  @override
  void dispose() {
    _installSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadInstalledVersion() async {
    try {
      final currentVersion = await _appUpdateService.getInstalledVersion();
      if (!mounted) return;
      setState(() {
        _installedVersion = currentVersion;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _installedVersion = 'okänd';
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isChecking = true;
      _errorMessage = null;
      _installMessage = null;
      _installProgress = null;
    });

    try {
      final release = await _appUpdateService.fetchLatestRelease();
      if (!mounted) return;

      final installedVersion = _installedVersion;
      final updateAvailable = installedVersion != null &&
          _appUpdateService.isUpdateAvailable(
            installedVersion,
            release.tagName,
          );

      setState(() {
        _latestRelease = release;
      });

      if (updateAvailable) {
        await _promptToInstall(release);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _friendlyUpdateError(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  String _friendlyUpdateError(Object error) {
    final message = error.toString();
    if (message.contains('Failed host lookup')) {
      return 'Kunde inte kontrollera uppdatering: Ingen internetanslutning (DNS).';
    }
    if (message.contains('CERTIFICATE_VERIFY_FAILED') ||
        message.contains('certificate is not yet valid')) {
      return 'Kunde inte kontrollera uppdatering: enhetens datum eller tid verkar vara fel. Kontrollera automatisk tid i Android och försök igen.';
    }
    if (message.contains('HandshakeException')) {
      return 'Kunde inte kontrollera uppdatering: säker anslutning till GitHub misslyckades.';
    }

    return 'Kunde inte kontrollera uppdatering: $error';
  }

  Future<void> _promptToInstall(AppUpdateInfo release) async {
    final shouldInstall = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final noteSnippet = release.releaseNotes.trim().isEmpty
                ? null
                : release.releaseNotes.trim();

            return AlertDialog(
              title: const Text('Ny uppdatering hittad'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Version ${release.tagName} finns på GitHub Releases.'),
                  const SizedBox(height: AppConstants.smallPadding),
                  const Text(
                    'Vill du uppdatera nu? Profiler, statistik, PIN och lokala data ligger kvar när appen installeras ovanpå den befintliga versionen.',
                  ),
                  if (noteSnippet != null) ...[
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      noteSnippet.length > 240
                          ? '${noteSnippet.substring(0, 240)}...'
                          : noteSnippet,
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Inte nu'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Ja, uppdatera'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldInstall || !mounted) return;
    await _installRelease(release);
  }

  Future<void> _installRelease(AppUpdateInfo release) async {
    await _installSubscription?.cancel();

    setState(() {
      _isInstalling = true;
      _errorMessage = null;
      _installMessage = 'Förbereder uppdatering...';
      _installProgress = null;
    });

    try {
      _installSubscription = _appUpdateService.installUpdate(release).listen(
        (event) {
          if (!mounted) return;
          setState(() {
            _installMessage = event.message;
            _installProgress = event.progress;
            if (event.isError) {
              _errorMessage = event.message;
            }
            if (event.isTerminal) {
              _isInstalling = false;
            }
          });
        },
        onError: (error) {
          if (!mounted) return;
          setState(() {
            _isInstalling = false;
            _errorMessage = _friendlyUpdateError(error);
            _installMessage = null;
            _installProgress = null;
          });
        },
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isInstalling = false;
        _errorMessage = _friendlyUpdateError(error);
        _installMessage = null;
        _installProgress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final installedVersionText = _installedVersion ?? 'laddar...';
    final release = _latestRelease;
    final hasRelease = release != null;
    final hasInstalled = _installedVersion != null;
    final updateAvailable = hasRelease &&
        hasInstalled &&
        _appUpdateService.isUpdateAvailable(
          _installedVersion!,
          release.tagName,
        );

    String statusText;
    if (_errorMessage != null) {
      statusText = _errorMessage!;
    } else if (_installMessage != null) {
      statusText = _installMessage!;
    } else if (!hasRelease) {
      statusText = 'Tryck på knappen för att kontrollera om ny version finns.';
    } else if (updateAvailable) {
      statusText = 'Ny version finns: ${release.tagName}';
    } else {
      statusText = 'Du har redan senaste versionen (${release.tagName}).';
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Appuppdatering',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Installerad version: $installedVersionText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _errorMessage == null
                      ? mutedOnPrimary
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Wrap(
            spacing: AppConstants.smallPadding,
            runSpacing: AppConstants.smallPadding,
            children: [
              ElevatedButton.icon(
                onPressed:
                    _isChecking || _isInstalling ? null : _checkForUpdates,
                icon: _isChecking
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : _isInstalling
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.system_update_alt),
                label: Text(
                  _isChecking
                      ? 'Kontrollerar...'
                      : _isInstalling
                          ? 'Uppdaterar...'
                          : 'Sök uppdatering',
                ),
              ),
              if (updateAvailable)
                OutlinedButton.icon(
                  onPressed:
                      _isInstalling ? null : () => _promptToInstall(release),
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('Uppdatera nu'),
                ),
            ],
          ),
          if (_isInstalling && _installProgress != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            LinearProgressIndicator(value: _installProgress! / 100),
          ],
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Vid uppdatering installeras APK:n ovanpå befintlig app, så profiler, PIN, statistik och historik ligger kvar. Avinstallera inte först.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedOnPrimary,
                ),
          ),
        ],
      ),
    );
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

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.history});

  final Map<String, dynamic> history;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    final operation = (history['operationType'] as String?) ?? '-';
    final difficulty = (history['difficulty'] as String?) ?? '-';
    final correct = (history['correctAnswers'] as int?) ?? 0;
    final total = (history['totalQuestions'] as int?) ?? 0;
    final pointsWithBonus = (history['pointsWithBonus'] as int?) ??
        ((history['points'] as int?) ?? 0);

    return _InsetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_HistoryRow(history: history)._pretty(operation)} • ${_HistoryRow(history: history)._pretty(difficulty)}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: onPrimary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AppConstants.microSpacing6),
          Text(
            _formatHistoryTime(history),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  label: 'Resultat',
                  value: '$correct/$total',
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: _HistoryMetric(
                  label: 'Poäng',
                  value: '$pointsWithBonus p',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            total <= 0
                ? 'Ingen underlag än'
                : 'Träffsäkerhet: ${((correct / total) * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  String _formatHistoryTime(Map<String, dynamic> history) {
    final raw = history['endTime'] ?? history['startTime'];
    if (raw is! String || raw.isEmpty) return 'Tid okänd';

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return 'Tid okänd';

    final local = parsed.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month kl $hour:$minute';
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtleOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.microSpacing4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _RecommendationRow extends StatelessWidget {
  const _RecommendationRow({required this.area});

  final _WeakArea area;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    return Row(
      children: [
        Expanded(
          child: Text(
            area.label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Text(
          '${(area.rate * 100).toStringAsFixed(0)}%',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _InsetPanel extends StatelessWidget {
  const _InsetPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      decoration: BoxDecoration(
        color: onPrimary.withValues(alpha: AppOpacities.panelFill),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(
          color: onPrimary.withValues(alpha: AppOpacities.borderSubtle),
        ),
      ),
      child: child,
    );
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

    void showInfoDialog({required String title, required String message}) {
      showDialog(
        context: context,
        builder: (ctx) {
          final onPrimary = Theme.of(ctx).colorScheme.onPrimary;
          return AlertDialog(
            title: Text(
              title,
              style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            content: Text(
              message,
              style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(foregroundColor: onPrimary),
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }

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

    final cards = ops.map((op) {
      final stored = storedSteps[op.name];
      final currentStep = DifficultyConfig.clampDifficultyStep(
        stored ?? DifficultyConfig.minDifficultyStep,
      );
      final stats = _successRateFromLatestQuestions(op);
      final hasEnough =
          stats.answered >= DifficultyConfig.trainingRecommendationMinQuestions;

      final recommendedStep = !hasEnough
          ? null
          : DifficultyConfig.recommendedDifficultyStepForTraining(
              currentStep: currentStep,
              averageSuccessRate: stats.rate,
            );

      final indicatorStep = recommendedStep ?? currentStep;

      final benchmark = DifficultyConfig.compareDifficultyStepToGrade(
        gradeLevel: gradeLevel,
        operation: op,
        difficultyStep: indicatorStep,
      );

      final valueText = DifficultyConfig.benchmarkLevelLabel(benchmark.level);
      final recommendationText = DifficultyConfig.benchmarkRecommendationText(
        level: benchmark.level,
        operation: op,
      );

      final underlagText = stats.rate == null
          ? 'Underlag: 0/${DifficultyConfig.trainingRecommendationMinQuestions} frågor'
          : hasEnough
              ? 'Senaste ${DifficultyConfig.trainingRecommendationMinQuestions}: ${_percentLabel(stats.rate!)} rätt'
              : 'Underlag: ${stats.answered}/${DifficultyConfig.trainingRecommendationMinQuestions} (just nu: ${_percentLabel(stats.rate!)} rätt)';

      final stepText = recommendedStep == null
          ? 'Steg $currentStep'
          : 'Steg $currentStep → Förslag $recommendedStep';

      final detailsMessage = StringBuffer()
        ..writeln('Indikator: $valueText')
        ..writeln(underlagText)
        ..writeln(stepText)
        ..writeln()
        ..writeln(
          'Obs: Steg ändras aldrig automatiskt — du väljer själv Lättare/Svårare.',
        );

      if (recommendationText.isNotEmpty) {
        detailsMessage
          ..writeln()
          ..writeln(recommendationText);
      }

      return _BenchmarkOperationCard(
        operation: op,
        valueText: valueText,
        underlagText: underlagText,
        stepText: stepText,
        onPrimary: onPrimary,
        mutedOnPrimary: mutedOnPrimary,
        subtleOnPrimary: subtleOnPrimary,
        onShowDetails: () => showInfoDialog(
          title: '${op.displayName} – detaljer',
          message: detailsMessage.toString().trim(),
        ),
        onDecrease: (currentStep <= DifficultyConfig.minDifficultyStep)
            ? null
            : () => updateStep(op, -1),
        onIncrease: (currentStep >= DifficultyConfig.maxDifficultyStep)
            ? null
            : () => updateStep(op, 1),
      );
    }).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Skolverket-indikator (Åk $gradeLevel)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            IconButton(
              tooltip: 'Förklaring',
              visualDensity: VisualDensity.compact,
              onPressed: () => showInfoDialog(
                title: 'Skolverket-indikator',
                message:
                    'Detta är en enkel “Under / I linje / Över”-indikator baserad på appens nivå (steg 1–10) per räknesätt.\n\nFörslag bygger på de senaste ${DifficultyConfig.trainingRecommendationMinQuestions} frågorna (mål: 85% rätt).\n\nSteg ändras aldrig automatiskt — du väljer själv Lättare/Svårare.',
              ),
              icon: Icon(Icons.help_outline, color: onPrimary),
            ),
          ],
        ),
        const SizedBox(height: AppConstants.smallPadding),
        Text(
          'Kort sagt: indikatorn speglar barnets senaste svar.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: subtleOnPrimary,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppConstants.smallPadding),
        LayoutBuilder(
          builder: (context, constraints) {
            final useGrid = constraints.maxWidth >= 520 && cards.length > 1;

            if (!useGrid) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: cards,
              );
            }

            final itemWidth =
                (constraints.maxWidth - AppConstants.smallPadding) / 2;
            return Wrap(
              spacing: AppConstants.smallPadding,
              runSpacing: AppConstants.smallPadding,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: itemWidth,
                      child: card,
                    ),
                  )
                  .toList(growable: false),
            );
          },
        ),
      ],
    );
  }
}

class _BenchmarkOperationCard extends StatelessWidget {
  const _BenchmarkOperationCard({
    required this.operation,
    required this.valueText,
    required this.underlagText,
    required this.stepText,
    required this.onPrimary,
    required this.mutedOnPrimary,
    required this.subtleOnPrimary,
    required this.onShowDetails,
    required this.onDecrease,
    required this.onIncrease,
  });

  final OperationType operation;
  final String valueText;
  final String underlagText;
  final String stepText;
  final Color onPrimary;
  final Color mutedOnPrimary;
  final Color subtleOnPrimary;
  final VoidCallback onShowDetails;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    return _InsetPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  operation.displayName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w700,
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
              IconButton(
                tooltip: 'Förklaring',
                visualDensity: VisualDensity.compact,
                onPressed: onShowDetails,
                icon: Icon(Icons.help_outline, color: onPrimary),
              ),
            ],
          ),
          Text(
            underlagText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.microSpacing2),
          Text(
            stepText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecrease,
                  child: const Text('Lättare'),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: OutlinedButton(
                  onPressed: onIncrease,
                  child: const Text('Svårare'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// endregion
