import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/config/difficulty_config.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../domain/enums/age_group.dart';

Future<void> showCreateUserDialog({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return const _CreateUserDialog();
    },
  );
}

class _CreateUserDialog extends ConsumerStatefulWidget {
  const _CreateUserDialog();

  @override
  ConsumerState<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<_CreateUserDialog> {
  final _nameController = TextEditingController();
  int? _selectedGrade;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = ref.watch(appThemeConfigProvider);

    return AlertDialog(
      scrollable: true,
      backgroundColor: cfg.cardColor,
      title: const Text(
        'Skapa användare',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Namn',
              labelStyle: TextStyle(color: Colors.white70),
            ),
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
                value: _selectedGrade,
                dropdownColor: cfg.baseBackgroundColor,
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
                onChanged: (value) => setState(() {
                  _selectedGrade = value;
                }),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Avbryt'),
        ),
        TextButton(
          onPressed: () async {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;

            final ageGroup = DifficultyConfig.effectiveAgeGroup(
              fallback: AgeGroup.young,
              gradeLevel: _selectedGrade,
            );

            await ref.read(userProvider.notifier).createUser(
                  userId: const Uuid().v4(),
                  name: name,
                  ageGroup: ageGroup,
                  gradeLevel: _selectedGrade,
                );

            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Skapa'),
        ),
      ],
    );
  }
}
