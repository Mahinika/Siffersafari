import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/quiz_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/entities/user_progress.dart';
import '../../domain/enums/age_group.dart';
import '../../domain/enums/app_theme.dart';
import '../../domain/enums/difficulty_level.dart';
import '../../domain/enums/operation_type.dart';
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

  OperationType _recommendedOperation(Set<OperationType> allowedOps) {
    const priority = <OperationType>[
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

  Future<void> _showCreateUserDialog() async {
    final nameController = TextEditingController();
    int? selectedGrade;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: AppColors.spaceBackground,
              title: const Text(
                'Skapa användare',
                style: TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Namn',
                      labelStyle: const TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: AppColors.spaceAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppConstants.defaultPadding),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Årskurs',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                      DropdownButton<int?>(
                        value: selectedGrade,
                        dropdownColor: AppColors.spaceBackground,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.white),
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Ingen'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 1,
                            child: Text('Åk 1'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 2,
                            child: Text('Åk 2'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 3,
                            child: Text('Åk 3'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 4,
                            child: Text('Åk 4'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 5,
                            child: Text('Åk 5'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 6,
                            child: Text('Åk 6'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 7,
                            child: Text('Åk 7'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 8,
                            child: Text('Åk 8'),
                          ),
                          DropdownMenuItem<int?>(
                            value: 9,
                            child: Text('Åk 9'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedGrade = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Avbryt'),
                ),
                TextButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final ageGroup = DifficultyConfig.effectiveAgeGroup(
                      fallback: AgeGroup.young,
                      gradeLevel: selectedGrade,
                    );

                    await ref.read(userProvider.notifier).createUser(
                          userId: const Uuid().v4(),
                          name: name,
                          ageGroup: ageGroup,
                          gradeLevel: selectedGrade,
                        );

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  child: const Text('Skapa'),
                ),
              ],
            );
          },
        );
      },
    );
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
        const SnackBar(content: Text('Skapa en användare först.')),
      );
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
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

    ref.read(quizProvider.notifier).startSession(
          ageGroup: effectiveAgeGroup,
          operationType: operationType,
          difficulty: effectiveDifficulty,
        );

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QuizScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;

    final selectedTheme = user?.selectedTheme ?? AppTheme.space;
    final backgroundAsset = switch (selectedTheme) {
      AppTheme.jungle => 'assets/images/themes/jungle/background.png',
      _ => 'assets/images/themes/space/background.png',
    };
    final questHeroAsset = switch (selectedTheme) {
      AppTheme.jungle => 'assets/images/themes/jungle/quest_hero.png',
      _ => 'assets/images/themes/space/quest_hero.png',
    };
    final baseBackgroundColor = selectedTheme == AppTheme.jungle
        ? AppColors.jungleBackground
        : AppColors.spaceBackground;

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
        setState(() {
          _checkedOnboardingForUserId = user.userId;
        });

        final repo = getIt<LocalStorageRepository>();
        final done = await repo.getSetting(_onboardingDoneKey(user.userId));
        if (!mounted) return;

        if (done != true) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => OnboardingScreen(userId: user.userId),
            ),
          );
        }
      });
    }

    final allowedOps = user == null
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

    final recommendedOperation = _recommendedOperation(allowedOps);

    return Scaffold(
      backgroundColor: baseBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/images/splash_background.png',
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: baseBackgroundColor.withOpacity(0.72),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: SingleChildScrollView(
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
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                        if (user != null)
                          IconButton(
                            tooltip: 'Föräldraläge',
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ParentPinScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.lock,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),

                    // Welcome Message
                    Text(
                      user != null
                          ? '👋 Hej ${user.name}!'
                          : '🚀 Välkommen till mattespelet! 🚀',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white70,
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
                              color: Colors.white54,
                            ),
                      ),
                    ],

                    const SizedBox(height: AppConstants.largePadding * 2),

                    if (user == null) ...[
                      ElevatedButton(
                        onPressed: () {
                          _showCreateUserDialog();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spacePrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                        child: const Text('Skapa användare'),
                      ),
                      const SizedBox(height: AppConstants.largePadding),
                    ],

                    // Stats card
                    if (user != null)
                      Container(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
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
                                  'Totala Poäng',
                                  user.totalPoints.toString(),
                                ),
                                _buildStatItem(
                                  context,
                                  'Streak',
                                  '${user.currentStreak} 🔥',
                                ),
                                _buildStatItem(
                                  context,
                                  'Quiz',
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
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '${user.pointsIntoLevel}/${UserProgress.pointsPerLevel}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white54,
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
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                              child: LinearProgressIndicator(
                                value: user.levelProgress.clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.spaceAccent,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.defaultPadding),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Aktivt uppdrag',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white70,
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
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              userState.questStatus?.quest.title ??
                                  'Inget uppdrag valt ännu',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                              child: LinearProgressIndicator(
                                value:
                                    (userState.questStatus?.progress ?? 0.0)
                                        .clamp(0.0, 1.0),
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.spaceAccent,
                                ),
                              ),
                            ),

                            const SizedBox(height: AppConstants.defaultPadding),
                            Row(
                              children: [
                                const Icon(
                                  Icons.emoji_events,
                                  color: AppColors.spaceAccent,
                                ),
                                const SizedBox(
                                    width: AppConstants.smallPadding),
                                Expanded(
                                  child: Text(
                                    'Medalj: ${_medalLabelForLevel(user.level)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white70,
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
                                      color: filled
                                          ? AppColors.spaceAccent
                                          : Colors.white38,
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
                                      color: Colors.white54,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (user != null &&
                        userState.questStatus != null &&
                        allowedOps
                            .contains(userState.questStatus!.quest.operation))
                      Container(
                        margin: const EdgeInsets.only(
                            top: AppConstants.defaultPadding),
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
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
                                const Icon(
                                  Icons.flag,
                                  color: AppColors.spaceAccent,
                                ),
                                const SizedBox(
                                    width: AppConstants.smallPadding),
                                Text(
                                  'Nästa uppdrag',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              userState.questStatus!.quest.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            if (userState.questNotice != null) ...[
                              const SizedBox(height: AppConstants.smallPadding),
                              Text(
                                userState.questNotice!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                            const SizedBox(height: AppConstants.smallPadding),
                            Text(
                              userState.questStatus!.quest.description,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Framsteg',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                Text(
                                  '${(userState.questStatus!.progress * 100).round()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppConstants.smallPadding),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  AppConstants.borderRadius),
                              child: LinearProgressIndicator(
                                value: userState.questStatus!.progress,
                                minHeight: 10,
                                backgroundColor: Colors.white.withOpacity(0.15),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppColors.spaceAccent,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppConstants.defaultPadding),
                            ElevatedButton(
                              onPressed: () => _startQuiz(
                                operationType:
                                    userState.questStatus!.quest.operation,
                                difficulty:
                                    userState.questStatus!.quest.difficulty,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.spacePrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppConstants.borderRadius,
                                  ),
                                ),
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
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.spacePrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                AppConstants.borderRadius),
                          ),
                        ),
                        child: Text(
                          'Starta ${recommendedOperation.displayName}',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Colors.white,
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
                            color: Colors.white38,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
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
    return Semantics(
      button: true,
      label: 'Starta ${operation.displayName}',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: () => _startQuiz(
            operationType: operation,
            difficulty: DifficultyLevel.easy,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.spacePrimary,
                  AppColors.spaceSecondary,
                ],
              ),
              borderRadius:
                  BorderRadius.circular(AppConstants.borderRadius * 2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.spacePrimary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: AppConstants.smallPadding),
                Text(
                  operation.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
