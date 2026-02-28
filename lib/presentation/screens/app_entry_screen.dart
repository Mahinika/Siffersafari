import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/providers/app_theme_provider.dart';
import '../../core/providers/user_provider.dart';
import '../widgets/themed_background_scaffold.dart';
import 'home_screen.dart';
import 'profile_picker_screen.dart';

class AppEntryScreen extends ConsumerStatefulWidget {
  const AppEntryScreen({super.key});

  @override
  ConsumerState<AppEntryScreen> createState() => _AppEntryScreenState();
}

class _AppEntryScreenState extends ConsumerState<AppEntryScreen> {
  bool _didLoad = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ref.read(userProvider.notifier).loadUsers();
      if (!mounted) return;
      setState(() {
        _didLoad = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final allUsers = userState.allUsers;

    final themeCfg = ref.watch(appThemeConfigProvider);
    final mutedOnPrimary =
      Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.70);

    if (!_didLoad || userState.isLoading) {
      return ThemedBackgroundScaffold(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: themeCfg.accentColor),
              const SizedBox(height: AppConstants.defaultPadding),
              Text(
                'Startar…',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: mutedOnPrimary),
              ),
            ],
          ),
        ),
      );
    }

    // Child-first flow: when multiple profiles exist, always let the child pick.
    if (allUsers.length > 1) {
      return const ProfilePickerScreen();
    }

    return const HomeScreen();
  }
}
