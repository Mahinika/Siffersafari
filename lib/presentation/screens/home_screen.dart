import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/audio_service_provider.dart';
import '../../core/providers/local_storage_repository_provider.dart';
import '../../core/providers/missing_number_settings_provider.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/spaced_repetition_settings_provider.dart';
import '../../core/providers/story_progress_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/word_problems_settings_provider.dart';
import '../../core/utils/adaptive_layout.dart';
import '../../core/utils/page_transitions.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
import 'package:siffersafari/features/home/presentation/widgets/home_story_progress_card.dart';
import 'package:siffersafari/features/profiles/presentation/dialogs/create_user_dialog.dart';
import '../screens/story_map_screen.dart';
import '../widgets/mascot_character.dart';
import '../widgets/themed_background_scaffold.dart';
import 'onboarding_screen.dart';
import 'parent_pin_screen.dart';
import 'quiz_screen.dart';
import 'settings_screen.dart';

// region HomeScreen Setup

/// Home screen - main entry point of the app
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _loadedAllowedOpsForUserId;
  String? _checkedOnboardingForUserId;
  String? _loadedReviewSummaryForUserId;
  String _appVersionLabel = '...';
  bool _onboardingPushInFlight = false;
  MascotReaction _mascotReaction = MascotReaction.idle;
  int _mascotReactionNonce = 0;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    // Load existing users and start background music
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifier = ref.read(userProvider.notifier);
      await notifier.loadUsers();

      // Start background music when home screen loads
      ref.read(audioServiceProvider).playMusic();

      if (mounted) {
        setState(() {
          _mascotReaction = MascotReaction.enter;
          _mascotReactionNonce++;
        });
      }
    });
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final versionLabel = packageInfo.buildNumber.isEmpty
          ? packageInfo.version
          : '${packageInfo.version}+${packageInfo.buildNumber}';

      if (!mounted) return;
      setState(() {
        _appVersionLabel = versionLabel;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _appVersionLabel = 'okänd';
      });
    }
  }

  // endregion

  // region _startQuiz Method

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
      gradeLevel: user.gradeLevel,
    );

    final wordProblemsEnabled = ref.read(
      wordProblemsEnabledProvider(user.userId),
    );

    final missingNumberEnabled = ref.read(
      missingNumberEnabledProvider(user.userId),
    );

    ref.read(quizProvider.notifier).startSession(
          userId: user.userId,
          ageGroup: effectiveAgeGroup,
          gradeLevel: user.gradeLevel,
          operationType: operationType,
          difficulty: effectiveDifficulty,
          initialDifficultyStepsByOperation: steps,
          wordProblemsEnabled: wordProblemsEnabled,
          missingNumberEnabled: missingNumberEnabled,
        );

    setState(() {
      _mascotReaction = MascotReaction.screenChange;
      _mascotReactionNonce++;
    });
    context.pushSmooth(const QuizScreen());
  }

  // endregion

  // region Main Build Method

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;
    final quizState = ref.watch(quizProvider);
    final spacedRepetitionEnabled = user == null
        ? false
        : ref.watch(spacedRepetitionEnabledProvider(user.userId));
    final storyProgress = ref.watch(storyProgressProvider);

    final themeCfg = ref.watch(appThemeConfigProvider);
    final backgroundAsset = themeCfg.backgroundAsset;
    final questHeroAsset = themeCfg.questHeroAsset;
    final characterAsset = themeCfg.characterAsset;
    final accentColor = themeCfg.accentColor;

    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);
    final faintOnPrimary = onPrimary.withValues(alpha: AppOpacities.faintText);

    if (user != null && _loadedAllowedOpsForUserId != user.userId) {
      // Mark as scheduled immediately to avoid multiple callbacks being queued
      // during rapid rebuilds.
      _loadedAllowedOpsForUserId = user.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(parentSettingsProvider.notifier)
            .loadAllowedOperations(user.userId);
      });
    }

    if (user != null && _loadedReviewSummaryForUserId != user.userId) {
      _loadedReviewSummaryForUserId = user.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(quizProvider.notifier)
            .hydrateReviewSummaryForUser(user.userId);
      });
    }

    if (user != null && _checkedOnboardingForUserId != user.userId) {
      // Mark as scheduled immediately to avoid pushing onboarding twice.
      _checkedOnboardingForUserId = user.userId;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;

        // Avoid stacking onboarding routes (can happen if Home is recreated
        // while an onboarding route is already on top).
        if (_onboardingPushInFlight || OnboardingScreen.isActive) return;

        final navigator = Navigator.of(context);

        final repo = ref.read(localStorageRepositoryProvider);
        final done = repo.isOnboardingDone(user.userId);
        if (!mounted) return;

        if (done != true) {
          _onboardingPushInFlight = true;
          try {
            await navigator.push(
              MaterialPageRoute(
                builder: (_) => OnboardingScreen(userId: user.userId),
              ),
            );
          } finally {
            _onboardingPushInFlight = false;
          }
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
    final hasStoryQuest = user != null &&
        storyProgress != null &&
        userState.questStatus != null &&
        allowedOps.contains(userState.questStatus!.quest.operation);

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

    return ThemedBackgroundScaffold(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
          final maxContentWidth = layout.contentMaxWidth;
          final isWideScreen = !layout.isCompactWidth;
          final gridCrossAxisCount = layout.gridColumns(
            compact: 2,
            medium: 3,
            expanded: 4,
          );
          final operationCardAspectRatio = layout.isShortHeight
              ? 1.45
              : layout.isExpandedWidth
                  ? 1.15
                  : layout.isMediumWidth
                      ? 1.0
                      : 0.95;

          final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
          final questHeroLogicalWidth = isWideScreen
              ? constraints.maxWidth.clamp(0.0, 800.0).toDouble()
              : constraints.maxWidth;
          final questHeroCacheWidth =
              (questHeroLogicalWidth * devicePixelRatio).round();
          final questHeroCacheHeight = (110 * devicePixelRatio).round();

          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  children: [
                    // App Title + Settings
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            AppConstants.appName,
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
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
                      const SizedBox(height: AppConstants.defaultPadding),
                      SizedBox(
                        height: isWideScreen ? 140 : 120,
                        child: MascotCharacter(
                          reaction: _mascotReaction,
                          reactionNonce: _mascotReactionNonce,
                          height: isWideScreen ? 140 : 120,
                        ),
                      ),
                      const SizedBox(height: AppConstants.smallPadding),
                      Text(
                        AppConstants.mascotName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: subtleOnPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],

                    const SizedBox(height: AppConstants.largePadding),

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
                        constraints: isWideScreen
                            ? const BoxConstraints(maxWidth: 800)
                            : null,
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: onPrimary.withValues(
                            alpha: AppOpacities.panelFill,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceAround,
                              runAlignment: WrapAlignment.center,
                              spacing: AppConstants.defaultPadding,
                              runSpacing: AppConstants.smallPadding,
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
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: mutedOnPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '${user.pointsIntoLevel}/${UserProgress.pointsPerLevel}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
                              child: LinearProgressIndicator(
                                value: user.levelProgress.clamp(0.0, 1.0),
                                minHeight: AppConstants.progressBarHeightSmall,
                                backgroundColor: onPrimary.withValues(
                                  alpha: AppOpacities.progressTrackLight,
                                ),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Nasta steg',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: mutedOnPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  userState.questStatus == null
                                      ? '-'
                                      : '${(userState.questStatus!.progress * 100).round()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: onPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              userState.questStatus?.quest.title ??
                                  '${AppConstants.mascotName}: Välj ett uppdrag så kör vi!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius,
                              ),
                              child: LinearProgressIndicator(
                                value: (userState.questStatus?.progress ?? 0.0)
                                    .clamp(0.0, 1.0),
                                minHeight: AppConstants.progressBarHeightSmall,
                                backgroundColor: onPrimary.withValues(
                                  alpha: AppOpacities.progressTrackLight,
                                ),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(accentColor),
                              ),
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Row(
                              children: [
                                Icon(
                                  Icons.emoji_events,
                                  color: accentColor,
                                ),
                                const SizedBox(
                                  width: AppConstants.smallPadding,
                                ),
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
                                      color:
                                          filled ? accentColor : faintOnPrimary,
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppConstants.smallPadding,
                                vertical: AppConstants.smallPadding,
                              ),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius,
                                ),
                                border: Border.all(
                                  color: accentColor.withValues(alpha: 0.52),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_edu,
                                    color: accentColor,
                                    size: 18,
                                  ),
                                  const SizedBox(
                                    width: AppConstants.smallPadding,
                                  ),
                                  Expanded(
                                    child: Text(
                                      !spacedRepetitionEnabled
                                          ? 'Repetitioner av: aktivera i Föräldraläge'
                                          : quizState.dueReviewCount == 0
                                              ? 'Repetitioner redo: inga just nu'
                                              : 'Repetitioner redo: ${quizState.dueReviewCount}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: mutedOnPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (hasStoryQuest)
                      HomeStoryProgressCard(
                        story: storyProgress,
                        heroAsset: questHeroAsset,
                        backgroundAsset: backgroundAsset,
                        characterAsset: characterAsset,
                        accentColor: accentColor,
                        onPrimary: onPrimary,
                        mutedOnPrimary: mutedOnPrimary,
                        subtleOnPrimary: subtleOnPrimary,
                        faintOnPrimary: faintOnPrimary,
                        cacheWidth: questHeroCacheWidth,
                        cacheHeight: questHeroCacheHeight,
                        onStartQuest: () => _startQuiz(
                          operationType: userState.questStatus!.quest.operation,
                          difficulty: userState.questStatus!.quest.difficulty,
                        ),
                        onOpenMap: () => context.pushSmooth(
                          const StoryMapScreen(),
                        ),
                      ),

                    const SizedBox(height: AppConstants.largePadding),

                    if (user != null) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasStoryQuest
                              ? 'Eller valj en egen matte-runda'
                              : 'Valj ditt nasta uppdrag',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: onPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.microSpacing6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          hasStoryQuest
                              ? 'Fortsatt pa stigen ovanfor eller tryck pa en skylt har nedan.'
                              : 'Tryck pa en skylt sa startar vi direkt.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      const SizedBox(height: AppConstants.defaultPadding),
                    ],

                    // Operation selection (responsive grid)
                    ConstrainedBox(
                      constraints: isWideScreen
                          ? const BoxConstraints(maxWidth: 800)
                          : const BoxConstraints(),
                      child: GridView.count(
                        crossAxisCount: gridCrossAxisCount,
                        childAspectRatio: operationCardAspectRatio,
                        crossAxisSpacing: AppConstants.defaultPadding,
                        mainAxisSpacing: AppConstants.defaultPadding,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        children: operationCards,
                      ),
                    ),

                    const SizedBox(height: AppConstants.defaultPadding),

                    // Version Info
                    Text(
                      'Version $_appVersionLabel',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: faintOnPrimary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // endregion

  // region UI Builder Methods

  Widget _buildStatItem(BuildContext context, String label, String value) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
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
              color: themeCfg.primaryActionColor.withValues(
                alpha: AppOpacities.operationCardShadowPrimary,
              ),
              blurRadius: AppConstants.operationCardShadowPrimaryBlur,
              spreadRadius: AppConstants.operationCardShadowPrimarySpread,
              offset: const Offset(
                0,
                AppConstants.operationCardShadowPrimaryOffsetY,
              ),
            ),
            BoxShadow(
              color: Theme.of(context)
                  .shadowColor
                  .withValues(alpha: AppOpacities.shadowAmbient),
              blurRadius: AppConstants.operationCardShadowAmbientBlur,
              offset: const Offset(
                0,
                AppConstants.operationCardShadowAmbientOffsetY,
              ),
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

  // endregion

  // region Medal/Goal Helper Methods

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

  // endregion
}
