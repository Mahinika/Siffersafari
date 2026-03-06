import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/local_storage_repository_provider.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/word_problems_settings_provider.dart';
import '../../core/utils/adaptive_layout.dart';
import '../../domain/enums/operation_type.dart';
import '../widgets/themed_background_scaffold.dart';

// region OnboardingScreen Widget

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  static int _activeCount = 0;
  static bool get isActive => _activeCount > 0;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

// endregion

// region _OnboardingScreenState Main Widget

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _pageIndex = 0;

  int? _gradeLevel;
  Set<OperationType> _allowedOps = const {OperationType.addition};

  bool _needsReadingSetup = false;

  @override
  void initState() {
    super.initState();

    OnboardingScreen._activeCount++;

    // Load persisted onboarding-related settings for this user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = ref.read(localStorageRepositoryProvider);

      final existingReadingSetting =
          repo.getSetting(wordProblemsEnabledKey(widget.userId));

      final activeUser = ref.read(userProvider).activeUser;
      final user = activeUser?.userId == widget.userId
          ? activeUser
          : repo.getUserProgress(widget.userId);

      ref.read(parentSettingsProvider.notifier).loadAllowedOperations(
        widget.userId,
        defaultOperations: const {OperationType.addition},
      );
      final allowedOps = ref.read(parentSettingsProvider)[widget.userId] ??
          const <OperationType>{OperationType.addition};

      if (!mounted) return;
      setState(() {
        _gradeLevel = user?.gradeLevel;
        _allowedOps = allowedOps;
        _needsReadingSetup = existingReadingSetting is! bool;
      });

      // If grade is already set (often chosen during user creation), start on
      // the next step to avoid asking the same question twice.
      if ((user?.gradeLevel != null) && mounted) {
        setState(() {
          _pageIndex = 1;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _controller.jumpToPage(1);
        });
      }
    });
  }

  @override
  void dispose() {
    OnboardingScreen._activeCount = OnboardingScreen._activeCount > 0
        ? OnboardingScreen._activeCount - 1
        : 0;
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final repo = ref.read(localStorageRepositoryProvider);

    await ref
        .read(parentSettingsProvider.notifier)
        .setAllowedOperations(widget.userId, _allowedOps);

    final activeUser = ref.read(userProvider).activeUser;
    if (activeUser != null && activeUser.userId == widget.userId) {
      await ref
          .read(userProvider.notifier)
          .saveUser(activeUser.copyWith(gradeLevel: _gradeLevel));
    } else {
      final user = repo.getUserProgress(widget.userId);
      if (user != null) {
        await repo.saveUserProgress(user.copyWith(gradeLevel: _gradeLevel));
        await ref.read(userProvider.notifier).loadUsers();
      }
    }

    // Make sure parent settings cache reflects the saved operations.
    ref
        .read(parentSettingsProvider.notifier)
        .loadAllowedOperations(widget.userId);

    await repo.setOnboardingDone(widget.userId, true);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _next() {
    if (_pageIndex >= (_pages.length - 1)) {
      _finish();
      return;
    }

    _controller.nextPage(
      duration: AppConstants.mediumAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pageIndex + 1) / _pages.length;
    final accentColor = Theme.of(context).colorScheme.secondary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);

    return PopScope(
      canPop: false,
      child: ThemedBackgroundScaffold(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
            final compactLayout = constraints.maxHeight < 620;
            final maxContentWidth = layout.contentMaxWidth;

            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Nu kör vi!',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: onPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Jag heter ${AppConstants.mascotName}.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: mutedOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${_pageIndex + 1}/${_pages.length}',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: AppConstants.progressBarHeightSmall,
                        backgroundColor: onPrimary.withValues(
                          alpha: AppOpacities.progressTrackLight,
                        ),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    SizedBox(
                      height: compactLayout
                          ? AppConstants.defaultPadding
                          : AppConstants.largePadding,
                    ),
                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (index) =>
                            setState(() => _pageIndex = index),
                        children: _pages,
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    ElevatedButton(
                      onPressed: _next,
                      child: Text(
                        _pageIndex >= (_pages.length - 1) ? 'Klar' : 'Nästa',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.smallPadding),
                    TextButton(
                      onPressed: _finish,
                      child: Text(
                        'Hoppa över',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: mutedOnPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  List<Widget> get _pages {
    final pages = <Widget>[
      _OnboardingGradePage(
        gradeLevel: _gradeLevel,
        onChanged: (value) => setState(() {
          _gradeLevel = value;
        }),
      ),
    ];

    if (_needsReadingSetup) {
      pages.add(
        _OnboardingReadingPage(
          onAnswer: (canRead) async {
            await ref
                .read(wordProblemsEnabledProvider(widget.userId).notifier)
                .setEnabled(canRead);
            if (!mounted) return;
            _next();
          },
        ),
      );
    }

    pages.add(
      _OnboardingOpsPage(
        allowedOps: _allowedOps,
        onChanged: (updated) => setState(() {
          _allowedOps = updated;
        }),
      ),
    );

    return pages;
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: onPrimary.withValues(alpha: AppOpacities.subtleFill),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: onPrimary.withValues(alpha: AppOpacities.cardBorder),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              icon,
              size: AppConstants.minTouchTargetSize,
              color: accentColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            child,
          ],
        ),
      ),
    );
  }
}

class _OnboardingGradePage extends StatelessWidget {
  const _OnboardingGradePage({
    required this.gradeLevel,
    required this.onChanged,
  });

  final int? gradeLevel;
  final ValueChanged<int?> onChanged;

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6];

  @override
  Widget build(BuildContext context) {
    final dropdownBg = Theme.of(context).scaffoldBackgroundColor;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    return _OnboardingCard(
      icon: Icons.school,
      title: 'Vilken årskurs kör du?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Så fixar ${AppConstants.mascotName} lagom svår nivå.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Årskurs',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: mutedOnPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              DropdownButton<int?>(
                value: gradeLevel,
                dropdownColor: dropdownBg,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: onPrimary),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Vet inte'),
                  ),
                  ..._gradeItems.map(
                    (g) => DropdownMenuItem<int?>(
                      value: g,
                      child: Text('Åk $g'),
                    ),
                  ),
                ],
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// endregion

// region Page Builder Widgets
class _OnboardingOpsPage extends StatelessWidget {
  const _OnboardingOpsPage({
    required this.allowedOps,
    required this.onChanged,
  });

  final Set<OperationType> allowedOps;
  final ValueChanged<Set<OperationType>> onChanged;

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.secondary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    const items = <OperationType>[
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    ];

    return _OnboardingCard(
      icon: Icons.grid_view,
      title: 'Vad vill du räkna?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Det går att ändra senare i Föräldraläge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ...items.map((op) {
            final isChecked = allowedOps.contains(op);
            return Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: mutedOnPrimary,
              ),
              child: CheckboxListTile(
                value: isChecked,
                onChanged: (value) {
                  final checked = value ?? false;
                  final updated = {...allowedOps};
                  if (checked) {
                    updated.add(op);
                  } else {
                    updated.remove(op);
                  }
                  if (updated.isEmpty) {
                    // Never allow an empty set.
                    return;
                  }
                  onChanged(updated);
                },
                activeColor: accentColor,
                title: Text(
                  op.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _OnboardingReadingPage extends StatelessWidget {
  const _OnboardingReadingPage({
    required this.onAnswer,
  });

  final ValueChanged<bool> onAnswer;

  @override
  Widget build(BuildContext context) {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);

    return _OnboardingCard(
      icon: Icons.menu_book,
      title: 'Kan barnet läsa?',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Om ja kan spelet ibland visa korta textuppgifter istället för bara tal.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: mutedOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.defaultPadding),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAnswer(true),
                  child: const Text('Ja'),
                ),
              ),
              const SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onAnswer(false),
                  child: const Text('Nej'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.smallPadding),
          Text(
            'Du kan ändra detta senare i Föräldraläge.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: subtleOnPrimary,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
// endregion
