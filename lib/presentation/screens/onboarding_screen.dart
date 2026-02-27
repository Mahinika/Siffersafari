import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/di/injection.dart';
import '../../core/providers/parent_settings_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../data/repositories/local_storage_repository.dart';
import '../../domain/enums/operation_type.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({
    required this.userId,
    super.key,
  });

  final String userId;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _pageIndex = 0;

  int? _gradeLevel;
  Set<OperationType> _allowedOps = const {OperationType.multiplication};

  static String _doneKey(String userId) => 'onboarding_done_$userId';
  static String _allowedOpsKey(String userId) => 'allowed_ops_$userId';

  OperationType? _operationFromName(String name) {
    for (final op in OperationType.values) {
      if (op.name == name) return op;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    // Load persisted onboarding-related settings for this user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final repo = getIt<LocalStorageRepository>();

      final activeUser = ref.read(userProvider).activeUser;
      final user = activeUser?.userId == widget.userId
          ? activeUser
          : repo.getUserProgress(widget.userId);

      final rawAllowed = repo.getSetting(_allowedOpsKey(widget.userId));
      final ops = <OperationType>{};
      if (rawAllowed is List) {
        for (final item in rawAllowed.whereType<String>()) {
          final op = _operationFromName(item);
          if (op == null) continue;
          if (op == OperationType.mixed) continue;
          ops.add(op);
        }
      }

      final allowedOps = ops.isNotEmpty
          ? ops
          : const <OperationType>{OperationType.multiplication};

      if (!mounted) return;
      setState(() {
        _gradeLevel = user?.gradeLevel;
        _allowedOps = allowedOps;
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
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final repo = getIt<LocalStorageRepository>();

    // Persist settings chosen during onboarding.
    await repo.saveSetting(
      _allowedOpsKey(widget.userId),
      _allowedOps.isNotEmpty
          ? _allowedOps.map((op) => op.name).toList()
          : [OperationType.multiplication.name],
    );

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
    ref.read(parentSettingsProvider.notifier).loadAllowedOperations(
          widget.userId,
        );

    await repo.saveSetting(_doneKey(widget.userId), true);

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  void _next() {
    if (_pageIndex >= 1) {
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
    final progress = (_pageIndex + 1) / 2;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.spaceBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Kom igång',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    Text(
                      '${_pageIndex + 1}/2',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
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
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.spaceAccent,
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.largePadding),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) =>
                        setState(() => _pageIndex = index),
                    children: [
                      _OnboardingGradePage(
                        gradeLevel: _gradeLevel,
                        onChanged: (value) => setState(() {
                          _gradeLevel = value;
                        }),
                      ),
                      _OnboardingOpsPage(
                        allowedOps: _allowedOps,
                        onChanged: (updated) => setState(() {
                          _allowedOps = updated;
                        }),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.spacePrimary,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppConstants.borderRadius),
                    ),
                  ),
                  child: Text(
                    _pageIndex >= 1 ? 'Klar' : 'Nästa',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
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
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              icon,
              size: 56,
              color: AppColors.spaceAccent,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
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
    return _OnboardingCard(
      icon: Icons.school,
      title: 'Välj årskurs',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Det hjälper oss att anpassa svårighetsnivån.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
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
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              DropdownButton<int?>(
                value: gradeLevel,
                dropdownColor: AppColors.spaceBackground,
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
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OnboardingOpsPage extends StatelessWidget {
  const _OnboardingOpsPage({
    required this.allowedOps,
    required this.onChanged,
  });

  final Set<OperationType> allowedOps;
  final ValueChanged<Set<OperationType>> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const <OperationType>[
      OperationType.addition,
      OperationType.subtraction,
      OperationType.multiplication,
      OperationType.division,
    ];

    return _OnboardingCard(
      icon: Icons.grid_view,
      title: 'Välj räknesätt',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Du kan ändra detta senare i Föräldraläge.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppConstants.smallPadding),
          ...items.map((op) {
            final isChecked = allowedOps.contains(op);
            return Theme(
              data: Theme.of(context).copyWith(
                unselectedWidgetColor: Colors.white70,
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
                activeColor: AppColors.spaceAccent,
                title: Text(
                  op.displayName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
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
