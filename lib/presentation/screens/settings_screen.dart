import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/user_provider.dart';
import '../../domain/enums/age_group.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _gradeItems = <int>[1, 2, 3, 4, 5, 6, 7, 8, 9];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final user = userState.activeUser;
    final allUsers = userState.allUsers;

    Future<void> showCreateUserDialog() async {
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
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

    return Scaffold(
      backgroundColor: AppColors.spaceBackground,
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
                            dropdownColor: AppColors.spaceBackground,
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
                    onTap: showCreateUserDialog,
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
                      activeThumbColor: AppColors.spaceAccent,
                      activeTrackColor:
                          AppColors.spaceAccent.withValues(alpha: 0.35),
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
                      activeThumbColor: AppColors.spaceAccent,
                      activeTrackColor:
                          AppColors.spaceAccent.withValues(alpha: 0.35),
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
