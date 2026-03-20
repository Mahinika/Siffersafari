import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:siffersafari/core/constants/app_constants.dart';
import 'package:siffersafari/core/providers/app_theme_provider.dart';
import 'package:siffersafari/core/providers/user_provider.dart';
import 'package:siffersafari/core/theme/app_theme_config.dart';
import 'package:siffersafari/core/utils/adaptive_layout.dart';
import 'package:siffersafari/features/profiles/presentation/dialogs/create_user_dialog.dart';
import 'package:siffersafari/presentation/widgets/theme_mascot.dart';
import 'package:siffersafari/presentation/widgets/themed_background_scaffold.dart';

class InitialProfileSetupScreen extends ConsumerWidget {
  const InitialProfileSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final onPrimary = scheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);

    final themeCfg = ref.watch(appThemeConfigProvider);
    final mascotHeight =
        layoutDependentMascotHeight(MediaQuery.sizeOf(context).height);

    return ThemedBackgroundScaffold(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewInsets = MediaQuery.viewInsetsOf(context);
          final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
          final heroMaxWidth = layout.isExpandedWidth
              ? 460.0
              : layout.isMediumWidth
                  ? 500.0
                  : AppConstants.contentMaxWidth;
          final verticalPadding = layout.isExpandedWidth
              ? AppConstants.largePadding * 1.5
              : AppConstants.largePadding;

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: viewInsets.bottom),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - viewInsets.bottom)
                    .clamp(0.0, double.infinity),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: heroMaxWidth),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppConstants.largePadding,
                      vertical: verticalPadding,
                    ),
                    decoration: BoxDecoration(
                      color:
                          onPrimary.withValues(alpha: AppOpacities.panelFill),
                      borderRadius: BorderRadius.circular(
                        AppConstants.borderRadius * 1.5,
                      ),
                      border: Border.all(
                        color: onPrimary.withValues(
                          alpha: AppOpacities.cardBorder,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                color: onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Align(
                          alignment: Alignment.center,
                          child: SizedBox(
                            height: mascotHeight,
                            child: ThemeMascot.withState(
                              state: CharacterAnimationState.idle,
                              height: mascotHeight,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        Text(
                          'Välkommen!',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: mutedOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.microSpacing6),
                        Text(
                          'Jag heter ${AppConstants.mascotName}.',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: mutedOnPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppConstants.smallPadding),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Skapa en profil första gången så spelet kan spara poäng, nivå och anpassa svårighetsgrad.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: subtleOnPrimary,
                                    fontWeight: FontWeight.w600,
                                    height: 1.35,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.largePadding),
                        Align(
                          alignment: Alignment.center,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 360),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () async {
                                  await showCreateUserDialog(
                                    context: context,
                                    ref: ref,
                                  );
                                  if (!context.mounted) return;

                                  await ref
                                      .read(userProvider.notifier)
                                      .loadUsers();
                                },
                                child: const Text('Skapa profil'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.defaultPadding),
                        Text(
                          'Du kan skapa fler profiler senare i Inställningar.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                          runSpacing: AppConstants.microSpacing6,
                          children: [
                            Icon(Icons.stars, color: themeCfg.accentColor),
                            Text(
                              'Redo för matte-äventyr!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
              ),
            ),
          );
        },
      ),
    );
  }

  double layoutDependentMascotHeight(double screenHeight) {
    if (screenHeight < 700) return 120;
    if (screenHeight < 900) return 150;
    return 180;
  }
}
