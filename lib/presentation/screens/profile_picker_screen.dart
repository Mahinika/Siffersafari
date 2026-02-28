import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/page_transitions.dart';
import '../widgets/themed_background_scaffold.dart';
import 'home_screen.dart';

class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final users = userState.allUsers;
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);

    return ThemedBackgroundScaffold(
      appBar: AppBar(title: const Text('Välj profil')),
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: users.isEmpty
          ? Center(
              child: Text(
                'Inga profiler ännu.\nBe en förälder skapa en profil.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Vem ska spela?',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Expanded(
                  child: ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppConstants.smallPadding),
                    itemBuilder: (context, index) {
                      final u = users[index];
                      return _ProfileTile(
                        name: u.name,
                        avatarEmoji: u.avatarEmoji,
                        onTap: () async {
                          await ref.read(userProvider.notifier).selectUser(
                                u.userId,
                              );
                          if (!context.mounted) return;
                          await context
                              .pushReplacementSmooth(const HomeScreen());
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                Text(
                  'Tips: Föräldraläge (PIN) finns på startsidan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: mutedOnPrimary,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );
  }
}

class _ProfileTile extends ConsumerWidget {
  const _ProfileTile({
    required this.name,
    required this.avatarEmoji,
    required this.onTap,
  });

  final String name;
  final String avatarEmoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeCfg = ref.watch(appThemeConfigProvider);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      child: Container(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          color: onPrimary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: onPrimary.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: AppConstants.minTouchTargetSize,
              height: AppConstants.minTouchTargetSize,
              decoration: BoxDecoration(
                color: themeCfg.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              alignment: Alignment.center,
              child: Text(
                avatarEmoji,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(width: AppConstants.defaultPadding),
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            Icon(Icons.chevron_right, color: mutedOnPrimary),
          ],
        ),
      ),
    );
  }
}
