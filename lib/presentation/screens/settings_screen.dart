import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/utils/adaptive_layout.dart';
import '../../domain/enums/app_theme.dart';
import '../dialogs/create_user_dialog.dart';
import '../widgets/themed_background_scaffold.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;
    final allUsers = userState.allUsers;

    final themeCfg = ref.watch(appThemeConfigProvider);
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final mutedOnPrimary = onPrimary.withValues(alpha: AppOpacities.mutedText);
    final subtleOnPrimary =
        onPrimary.withValues(alpha: AppOpacities.subtleText);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: const Text('Inställningar'),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layout = AdaptiveLayoutInfo.fromConstraints(constraints);
          final maxContentWidth = layout.contentMaxWidth;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxContentWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color:
                            onPrimary.withValues(alpha: AppOpacities.panelFill),
                        borderRadius:
                            BorderRadius.circular(AppConstants.borderRadius),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _AdaptiveDropdownTile<String>(
                            title: 'Användare',
                            subtitle: 'Välj eller skapa en profil',
                            value: user?.userId,
                            isCompact: layout.isCompactWidth,
                            textColor: onPrimary,
                            subtitleColor: subtleOnPrimary,
                            dropdownColor: themeCfg.baseBackgroundColor,
                            items: [
                              ...allUsers.map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.userId,
                                  child: Text(u.name),
                                ),
                              ),
                            ],
                            onChanged: allUsers.isEmpty
                                ? null
                                : (value) async {
                                    if (value == null) return;
                                    await ref
                                        .read(userProvider.notifier)
                                        .selectUser(value);
                                  },
                          ),
                          const Divider(height: 1),
                          ListTile(
                            title: Text(
                              'Skapa användare',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: mutedOnPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            leading:
                                Icon(Icons.person_add, color: mutedOnPrimary),
                            onTap: () => showCreateUserDialog(
                              context: context,
                              ref: ref,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    if (user == null)
                      Container(
                        padding:
                            const EdgeInsets.all(AppConstants.defaultPadding),
                        decoration: BoxDecoration(
                          color: onPrimary.withValues(
                            alpha: AppOpacities.panelFill,
                          ),
                          borderRadius:
                              BorderRadius.circular(AppConstants.borderRadius),
                        ),
                        child: Center(
                          child: Text(
                            'Ingen aktiv användare',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: mutedOnPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      )
                    else
                      Container(
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
                            _AdaptiveDropdownTile<int?>(
                              title: 'Årskurs',
                              subtitle: 'Styr svårighetsnivå (Åk 1–9).',
                              value: user.gradeLevel,
                              isCompact: layout.isCompactWidth,
                              textColor: onPrimary,
                              subtitleColor: subtleOnPrimary,
                              dropdownColor: themeCfg.baseBackgroundColor,
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
                                await ref.read(userProvider.notifier).saveUser(
                                      user.copyWith(gradeLevel: value),
                                    );
                              },
                            ),
                            const Divider(height: 1),
                            _AdaptiveDropdownTile<AppTheme>(
                              title: 'Tema',
                              subtitle: 'Byt bakgrund och stil.',
                              value: user.selectedTheme,
                              isCompact: layout.isCompactWidth,
                              textColor: onPrimary,
                              subtitleColor: subtleOnPrimary,
                              dropdownColor: themeCfg.baseBackgroundColor,
                              items: [
                                ...AppTheme.values.map(
                                  (t) => DropdownMenuItem<AppTheme>(
                                    value: t,
                                    child: Text('${t.emoji} ${t.displayName}'),
                                  ),
                                ),
                              ],
                              onChanged: (value) async {
                                if (value == null) return;
                                await ref.read(userProvider.notifier).saveUser(
                                      user.copyWith(selectedTheme: value),
                                    );
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: Text(
                                'Ljudeffekter',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: mutedOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: Text(
                                'Rätt/fel, klick, belöningar',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                    ),
                              ),
                              value: user.soundEnabled,
                              activeThumbColor: themeCfg.accentColor,
                              activeTrackColor: themeCfg.accentColor.withValues(
                                alpha: AppOpacities.highlightStrong,
                              ),
                              onChanged: (value) async {
                                await ref.read(userProvider.notifier).saveUser(
                                      user.copyWith(soundEnabled: value),
                                    );
                              },
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              title: Text(
                                'Musik',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: mutedOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              subtitle: Text(
                                'Bakgrundsmusik',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                    ),
                              ),
                              value: user.musicEnabled,
                              activeThumbColor: themeCfg.accentColor,
                              activeTrackColor: themeCfg.accentColor.withValues(
                                alpha: AppOpacities.highlightStrong,
                              ),
                              onChanged: (value) async {
                                await ref.read(userProvider.notifier).saveUser(
                                      user.copyWith(musicEnabled: value),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: AppConstants.defaultPadding),
                    if (user != null)
                      Container(
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
                            ListTile(
                              title: Text(
                                'Om appen',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: mutedOnPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: Text(
                                'Sekretesspolicy',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: onPrimary,
                                    ),
                              ),
                              subtitle: Text(
                                'Läs om hur vi hanterar data',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                    ),
                              ),
                              leading: Icon(
                                Icons.privacy_tip_outlined,
                                color: mutedOnPrimary,
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: mutedOnPrimary,
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (context) =>
                                        const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              title: Text(
                                'Radera all data',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Colors.red.shade400,
                                    ),
                              ),
                              subtitle: Text(
                                'Radera alla profiler och data permanent',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: subtleOnPrimary,
                                    ),
                              ),
                              leading: Icon(
                                Icons.delete_outline,
                                color: Colors.red.shade400,
                              ),
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (BuildContext context) =>
                                      AlertDialog(
                                    title: const Text('Radera all data?'),
                                    content: const Text(
                                      'Detta tar bort alla profiler, quiz-resultat och inställningar. '
                                      'Denna åtgärd kan inte ångras.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Avbryt'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Radera',
                                          style: TextStyle(
                                            color: Colors.red.shade400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
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
}

class _AdaptiveDropdownTile<T> extends StatelessWidget {
  const _AdaptiveDropdownTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isCompact,
    required this.textColor,
    required this.subtitleColor,
    required this.dropdownColor,
  });

  final String title;
  final String subtitle;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool isCompact;
  final Color textColor;
  final Color subtitleColor;
  final Color dropdownColor;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        );
    final subtitleStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: subtitleColor,
        );
    final dropdown = DropdownButton<T>(
      value: value,
      isExpanded: isCompact,
      dropdownColor: dropdownColor,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: textColor),
      underline: const SizedBox.shrink(),
      items: items,
      onChanged: onChanged,
    );

    if (!isCompact) {
      return ListTile(
        title: Text(title, style: titleStyle),
        subtitle: Text(subtitle, style: subtitleStyle),
        trailing: onChanged == null ? null : dropdown,
      );
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: titleStyle),
          const SizedBox(height: AppConstants.microSpacing6),
          Text(subtitle, style: subtitleStyle),
          if (onChanged != null) ...[
            const SizedBox(height: AppConstants.smallPadding),
            DropdownButtonHideUnderline(
              child: dropdown,
            ),
          ],
        ],
      ),
    );
  }
}
