import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../dialogs/create_user_dialog.dart';
import '../widgets/themed_background_scaffold.dart';

class FirstRunSetupScreen extends ConsumerWidget {
  const FirstRunSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: 0.70);
    final subtleOnPrimary = onPrimary.withValues(alpha: 0.54);

    final themeCfg = ref.watch(appThemeConfigProvider);

    return ThemedBackgroundScaffold(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                ],
              ),
              const SizedBox(height: AppConstants.largePadding),
              Text(
                'Välkommen!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.smallPadding),
              Text(
                'Skapa en profil första gången så spelet kan spara poäng, nivå och anpassa svårighetsgrad.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: subtleOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.largePadding),
              ElevatedButton(
                onPressed: () async {
                  await showCreateUserDialog(context: context, ref: ref);
                  if (!context.mounted) return;

                  // Stay on the AppEntryScreen route and let it rebuild into
                  // Home/ProfilePicker once a user exists.
                  await ref.read(userProvider.notifier).loadUsers();
                },
                child: const Text('Skapa profil'),
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Du kan skapa fler profiler senare i Inställningar.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: mutedOnPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.defaultPadding),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: AppConstants.smallPadding,
                children: [
                  Icon(Icons.stars, color: themeCfg.accentColor),
                  Text(
                    'Redo för matte-äventyr!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: mutedOnPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
