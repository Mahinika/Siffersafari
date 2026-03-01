import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/word_problems_settings_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import '../dialogs/create_user_dialog.dart';
import '../widgets/themed_background_scaffold.dart';
import 'onboarding_screen.dart';
import 'parent_pin_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

/// Home screen - main entry point of the app
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _loadedAllowedOpsForUserId;
  String? _checkedOnboardingForUserId;

  static String _onboardingDoneKey(String userId) => 'onboarding_done_$userId';

  OperationType _recommendedOperation({
    required Set<OperationType> allowedOps,
    required int? gradeLevel,
  }) {
    // If we know the child's grade, keep the recommendation conservative for
    // younger grades.
    final priority = (gradeLevel != null && gradeLevel <= 2)
        ? const <OperationType>[
            OperationType.addition,
            OperationType.subtraction,
            OperationType.multiplication,
            OperationType.division,
          ]
        : const <OperationType>[
            OperationType.multiplication,
            OperationType.addition,
            OperationType.subtraction,
            OperationType.division,
          ];

    for (final operation in priority) {
      if (allowedOps.contains(operation)) return operation;
    }

    return OperationType.multiplication;
  }

  @override
  void initState() {
    super.initState();
    // Load existing users
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(userProvider.notifier);
      await notifier.loadUsers();
    });
  }

  void _startQuiz({
    required OperationType operationType,
    required DifficultyLevel difficulty,
  }) {
    final user = ref.read(userProvider).activeUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skapa en profil först!')),
      );
      context.pushSmooth(const SettingsScreen());
      return;
    }

    ref.read(userProvider.notifier).clearQuestNotice();

    final effectiveAgeGroup = DifficultyConfig.effectiveAgeGroup(
      fallback: user.ageGroup,
      gradeLevel: user.gradeLevel,
    );

    final effectiveDifficulty = DifficultyConfig.effectiveDifficulty(
      fallback: difficulty,
      gradeLevel: user.gradeLevel,
    );

    final steps = DifficultyConfig.buildDifficultySteps(
      storedSteps: user.operationDifficultySteps,
      defaultDifficulty: effectiveDifficulty,
    );

    final repo = getIt<LocalStorageRepository>();
    final rawWordProblemsEnabled = repo.getSetting(
      wordProblemsEnabledKey(user.userId),
      defaultValue: true,
    );
    final wordProblemsEnabled =
        rawWordProblemsEnabled is bool ? rawWordProblemsEnabled : true;

    ref.read(quizProvider.notifier).startSession(
          ageGroup: effectiveAgeGroup,
          gradeLevel: user.gradeLevel,
          operationType: operationType,
          difficulty: effectiveDifficulty,
          initialDifficultyStepsByOperation: steps,
          wordProblemsEnabled: wordProblemsEnabled,
        );

    context.pushSmooth(const QuizScreen());
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;

    final themeCfg = ref.watch(appThemeConfigProvider);
    final backgroundAsset = themeCfg.backgroundAsset;
    final questHeroAsset = themeCfg.questHeroAsset;
    final accentColor = themeCfg.accentColor;

    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);
    final subtleOnPrimary = onPrimary.withValues(alpha: 0.54);
    final faintOnPrimary = onPrimary.withValues(alpha: 0.38);

    if (user != null && _loadedAllowedOpsForUserId != user.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(parentSettingsProvider.notifier)
            .loadAllowedOperations(user.userId);
        setState(() {
          _loadedAllowedOpsForUserId = user.userId;
        });
      });
    }

    if (user != null && _checkedOnboardingForUserId != user.userId) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        final navigator = Navigator.of(context);
        setState(() {
          _checkedOnboardingForUserId = user.userId;
        });

        final repo = getIt<LocalStorageRepository>();
        final done = await repo.getSetting(_onboardingDoneKey(user.userId));
        if (!mounted) return;

        if (done != true) {
          await navigator.push(
            MaterialPageRoute(
              builder: (_) => OnboardingScreen(userId: user.userId),
            ),
          );
        }
      });
    }

    final parentAllowedOps = user == null
        ? <OperationType>{
            OperationType.addition,
            OperationType.subtraction,
            OperationType.multiplication,
            OperationType.division,
          }
        : (ref.watch(parentSettingsProvider)[user.userId] ??
            {
              OperationType.addition,
              OperationType.subtraction,
              OperationType.multiplication,
              OperationType.division,
            });

    final allowedOps = DifficultyConfig.effectiveAllowedOperations(
      parentAllowedOperations: parentAllowedOps,
      gradeLevel: user?.gradeLevel,
    );

    final operationCards = <Widget>[];
    if (allowedOps.contains(OperationType.addition)) {
      operationCards.add(
        _buildOperationCard(
          context,
          OperationType.addition,
          Icons.add,
        ),
      );
    }
    if (allowedOps.contains(OperationType.subtraction)) {
      operationCards.add(
        _buildOperationCard(
          context,
          OperationType.subtraction,
          Icons.remove,
        ),
      );
    }
    if (allowedOps.contains(OperationType.multiplication)) {
      operationCards.add(
        _buildOperationCard(
          context,
          OperationType.multiplication,
          Icons.close,
        ),
      );
    }
    if (allowedOps.contains(OperationType.division)) {
      operationCards.add(
        _buildOperationCard(
          context,
          OperationType.division,
          Icons.percent,
        ),
      );
    }

    final recommendedOperation = _recommendedOperation(
      allowedOps: allowedOps,
      gradeLevel: user?.gradeLevel,
    );

    return ThemedBackgroundScaffold(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // App Title + Settings
            Row(
              children: [
                Expanded(
                  child: Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (user != null)
                  IconButton(
                    tooltip: 'Föräldraläge',
                    onPressed: () {
                      context.pushSmooth(const ParentPinScreen());
                    },
                    icon: Icon(Icons.lock, color: mutedOnPrimary),
                  ),
              ],
            ),
            const SizedBox(height: AppConstants.defaultPadding),

            // Welcome Message
            Text(
              user != null
                  ? '👋 Hej ${user.name}!'
                  : '🚀 Dags för matte-äventyr! 🚀',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: mutedOnPrimary,
                  ),
              textAlign: TextAlign.center,
            ),

            if (user != null) ...[
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                user.gradeLevel != null
                    ? 'Årskurs ${user.gradeLevel}'
                    : user.ageGroup.displayName,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: subtleOnPrimary,
                    ),
              ),
            ],

            const SizedBox(height: AppConstants.largePadding * 2),

            if (user == null) ...[
              ElevatedButton(
                onPressed: () {
                  showCreateUserDialog(context: context, ref: ref);
                },
                child: const Text('Skapa profil'),
              ),
              const SizedBox(height: AppConstants.largePadding),
            ],

            // Stats card
            if (user != null)
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          context,
                          'Poäng',
                          user.totalPoints.toString(),
                        ),
                        _buildStatItem(
                          context,
                          'Sviten',
                          '${user.currentStreak} 🔥',
                        ),
                        _buildStatItem(
                          context,
                          'Rundor',
                          user.totalQuizzesTaken.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nivå ${user.level}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '${user.pointsIntoLevel}/${UserProgress.pointsPerLevel}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: subtleOnPrimary,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Titel: ${user.levelTitle}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subtleOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      child: LinearProgressIndicator(
                        value: user.levelProgress.clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: onPrimary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Ditt uppdrag',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          userState.questStatus == null
                              ? '-'
                              : '${(userState.questStatus!.progress * 100).round()}%',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      userState.questStatus?.quest.title ??
                          'Välj ett uppdrag så kör vi!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: mutedOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      child: LinearProgressIndicator(
                        value: (userState.questStatus?.progress ?? 0.0)
                            .clamp(0.0, 1.0),
                        minHeight: 10,
                        backgroundColor: onPrimary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: accentColor,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Expanded(
                          child: Text(
                            'Medalj: ${_medalLabelForLevel(user.level)}',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        Row(
                          children: List.generate(3, (index) {
                            final filled =
                                index < _medalStarsForLevel(user.level);
                            return Icon(
                              filled ? Icons.star : Icons.star_border,
                              size: 18,
                              color: filled ? accentColor : faintOnPrimary,
                            );
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _nextGoalMessage(user),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subtleOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            if (user != null &&
                userState.questStatus != null &&
                allowedOps.contains(userState.questStatus!.quest.operation))
              Container(
                margin: const EdgeInsets.only(top: AppConstants.defaultPadding),
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: onPrimary.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius,
                      ),
                      child: SizedBox(
                        height: 110,
                        child: Image.asset(
                          questHeroAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset(
                              backgroundAsset,
                              fit: BoxFit.cover,
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      children: [
                        Icon(
                          Icons.flag,
                          color: accentColor,
                        ),
                        const SizedBox(width: AppConstants.smallPadding),
                        Text(
                          'Nästa äventyr',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      userState.questStatus!.quest.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (userState.questNotice != null) ...[
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        userState.questNotice!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: mutedOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                    const SizedBox(height: AppConstants.smallPadding),
                    Text(
                      userState.questStatus!.quest.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subtleOnPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'På väg',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        Text(
                          '${(userState.questStatus!.progress * 100).round()}%',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      child: LinearProgressIndicator(
                        value: userState.questStatus!.progress,
                        minHeight: 10,
                        backgroundColor: onPrimary.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    ElevatedButton(
                      onPressed: () => _startQuiz(
                        operationType: userState.questStatus!.quest.operation,
                        difficulty: userState.questStatus!.quest.difficulty,
                      ),
                      child: const Text('Starta uppdrag'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: AppConstants.largePadding * 2),

            if (user != null) ...[
              ElevatedButton(
                onPressed: () => _startQuiz(
                  operationType: recommendedOperation,
                  difficulty: DifficultyLevel.easy,
                ),
                child: Text(
                  'Starta ${recommendedOperation.displayName}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: AppConstants.largePadding),
            ],

            // Operation selection
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: AppConstants.defaultPadding,
              mainAxisSpacing: AppConstants.defaultPadding,
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              children: operationCards,
            ),

            const SizedBox(height: AppConstants.defaultPadding),

            // Version Info
            Text(
              'Version ${AppConstants.appVersion}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: faintOnPrimary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: onPrimary,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: mutedOnPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildOperationCard(
    BuildContext context,
    OperationType operation,
    IconData icon,
  ) {
    final themeCfg = ref.read(appThemeConfigProvider);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    final cardContent = GestureDetector(
      key: Key('operation_card_${operation.name}'),
      behavior: HitTestBehavior.opaque,
      onTap: () => _startQuiz(
        operationType: operation,
        difficulty: DifficultyLevel.easy,
      ),
      child: AnimatedContainer(
        duration: AppConstants.shortAnimationDuration,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              themeCfg.primaryActionColor,
              themeCfg.secondaryActionColor,
            ],
          ),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2),
          boxShadow: [
            BoxShadow(
              color: themeCfg.primaryActionColor.withValues(alpha: 0.4),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Hero(
              tag: 'operation_${operation.name}',
              child: Icon(
                icon,
                size: AppConstants.largeIconSize,
                color: onPrimary,
              ),
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              operation.displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Starta ${operation.displayName}',
      child: ExcludeSemantics(
        // Only animate when not in widget test mode
        child: const bool.fromEnvironment('FLUTTER_TEST')
            ? cardContent
            : TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppConstants.mediumAnimationDuration,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Opacity(
                      opacity: value,
                      child: child,
                    ),
                  );
                },
                child: cardContent,
              ),
      ),
    );
  }

  String _medalLabelForLevel(int level) {
    if (level >= 5) return 'Guld';
    if (level >= 3) return 'Silver';
    return 'Brons';
  }

  int _medalStarsForLevel(int level) {
    if (level >= 5) return 3;
    if (level >= 3) return 2;
    return 1;
  }

  String _nextGoalMessage(UserProgress user) {
    final pointsToNextLevel = user.pointsToNextLevel;
    final nextLevel = user.level + 1;

    // Medal milestones are tied to specific level thresholds.
    // - Silver at level 3 (totalPoints >= 2 * pointsPerLevel)
    // - Gold at level 5 (totalPoints >= 4 * pointsPerLevel)
    final int? targetMedalLevel = switch (user.level) {
      2 => 3,
      4 => 5,
      _ => null,
    };

    if (targetMedalLevel != null) {
      final targetTotalPoints =
          (targetMedalLevel - 1) * UserProgress.pointsPerLevel;
      final pointsLeft =
          (targetTotalPoints - user.totalPoints).clamp(0, 1 << 30);
      final medalName = targetMedalLevel == 3 ? 'Silver' : 'Guld';
      return 'Nästa mål: $medalName-medalj – $pointsLeft poäng kvar';
    }

    return 'Nästa mål: nivå $nextLevel – $pointsToNextLevel poäng kvar';
  }
}
