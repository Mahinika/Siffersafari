import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../dialogs/create_user_dialog.dart';
import '../widgets/themed_background_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;
    final allUsers = userState.allUsers;

    final themeCfg = ref.watch(appThemeConfigProvider);

    return ThemedBackgroundScaffold(
      appBar: AppBar(
        title: const Text('Inställningar'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(
                      'Användare',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      'Välj eller skapa en profil',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white54,
                          ),
                    ),
                    trailing: allUsers.isEmpty
                        ? null
                        : DropdownButton<String>(
                            value: user?.userId,
                            dropdownColor: themeCfg.baseBackgroundColor,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: Colors.white),
                            underline: const SizedBox.shrink(),
                            items: [
                              ...allUsers.map(
                                (u) => DropdownMenuItem<String>(
                                  value: u.userId,
                                  child: Text(u.name),
                                ),
                              ),
                            ],
                            onChanged: (value) async {
                              if (value == null) return;
                              await ref.read(userProvider.notifier).selectUser(
                                    value,
                                  );
                            },
                          ),
                  ),
                  const Divider(height: 1, color: Colors.white24),
                  ListTile(
                    title: Text(
                      'Skapa användare',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    leading:
                        const Icon(Icons.person_add, color: Colors.white70),
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
              Expanded(
                child: Center(
                  child: Text(
                    'Ingen aktiv användare',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      title: Text(
                        'Årskurs',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        'Styr svårighetsnivå (Åk 1–9).',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                      trailing: DropdownButton<int?>(
                        value: user.gradeLevel,
                        dropdownColor: themeCfg.baseBackgroundColor,
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
                        onChanged: (value) async {
                          await ref
                              .read(userProvider.notifier)
                              .saveUser(user.copyWith(gradeLevel: value));
                        },
                      ),
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    SwitchListTile(
                      title: Text(
                        'Ljudeffekter',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        'Rätt/fel, klick, belöningar',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                      value: user.soundEnabled,
                      activeThumbColor: themeCfg.accentColor,
                      activeTrackColor:
                          themeCfg.accentColor.withValues(alpha: 0.35),
                      onChanged: (value) async {
                        await ref
                            .read(userProvider.notifier)
                            .saveUser(user.copyWith(soundEnabled: value));
                      },
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    SwitchListTile(
                      title: Text(
                        'Musik',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      subtitle: Text(
                        'Bakgrundsmusik',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white54,
                            ),
                      ),
                      value: user.musicEnabled,
                      activeThumbColor: themeCfg.accentColor,
                      activeTrackColor:
                          themeCfg.accentColor.withValues(alpha: 0.35),
                      onChanged: (value) async {
                        await ref
                            .read(userProvider.notifier)
                            .saveUser(user.copyWith(musicEnabled: value));
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
