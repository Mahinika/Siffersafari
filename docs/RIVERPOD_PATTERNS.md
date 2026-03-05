# Riverpod Patterns & Standards

This document establishes consistent patterns for defining and using Riverpod providers across Siffersafari.

## 1. Provider Types

### Service Provider
Simple holder for a dependency-injected service (no state).

```dart
// lib/core/providers/audio_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/injection.dart';
import '../services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return getIt<AudioService>();
});
```

**When to use:** For service singletons that don't change or depend on other providers.  
**watch vs read:** Use `ref.watch()` if the service is observed in real-time; use `ref.read()` in event handlers.

---

### State Provider
Simple mutable state owned by the UI (e.g., filter selections, temporary UI state).

```dart
// lib/core/providers/difficulty_provider.dart
final ageGroupProvider = StateProvider<AgeGroup>((ref) => AgeGroup.young);
final operationTypeProvider = StateProvider<OperationType>((ref) => OperationType.addition);
final difficultyLevelProvider = StateProvider<DifficultyLevel>((ref) => DifficultyLevel.easy);
```

**When to use:** For UI-transient state that doesn't need persisted logic.  
**Lifecycle:** Reset on app close; use `ref.read(provider.notifier).state = newValue` to update.

---

### Computed Provider
Read-only value derived from watching other providers.

```dart
// lib/core/providers/app_theme_provider.dart
final appThemeProvider = Provider<AppTheme>((ref) {
  final user = ref.watch(userProvider).activeUser;
  return user?.selectedTheme ?? AppTheme.jungle;
});

final appThemeConfigProvider = Provider<AppThemeConfig>((ref) {
  final theme = ref.watch(appThemeProvider);
  return AppThemeConfig.forTheme(theme);
});
```

**When to use:** For derived state that depends on one or more other providers.  
**watch vs read:** Always use `ref.watch()` to stay synchronized.

---

### StateNotifier Provider
Complex state with business logic. Encapsulates mutations and invariants.

**File structure:**
1. State class (`@freezed` or manual `copyWith`)
2. StateNotifier class (holds logic & mutations)
3. Final provider definition

```dart
// lib/core/providers/user_provider.dart

@freezed
class UserState with _$UserState {
  const factory UserState({
    UserProgress? activeUser,
    @Default([]) List<UserProgress> allUsers,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _UserState;
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier(
    this._repository,
    this._achievementService,
  ) : super(const UserState());

  final LocalStorageRepository _repository;
  final AchievementService _achievementService;

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final users = _repository.getAllUserProfiles();
      state = state.copyWith(allUsers: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = ref.watch(localStorageRepositoryProvider);
  final achievementService = ref.watch(achievementServiceProvider);
  return UserNotifier(repository, achievementService);
});
```

**When to use:** For domain state with behavior (e.g., quiz session, user profile, settings).  
**watch vs read:** Use `ref.watch()` in build; use `ref.read()` in event handlers (button tap, form submit).

---

## 2. Naming Conventions

| Pattern | Example | Comment |
|---------|---------|---------|
| Service provider | `audioServiceProvider` | Not `audioProvider` |
| State provider | `ageGroupProvider` | Name the state, not the provider |
| Computed provider | `appThemeConfigProvider` | Descriptive name for derived value |
| StateNotifier | `UserNotifier` | Suffix with `Notifier` |
| StateNotifier provider | `userProvider` | Not `userNotifierProvider` |

---

## 3. watch vs read Guidelines

### Use `watch()`:
- In widget build methods
- For any provider that needs real-time synchronization
- When the result is used in the UI

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).activeUser; // Rebuild when user changes
    return Text(user?.name ?? 'No user');
  }
}
```

### Use `read()`:
- In event handlers (button taps, form submits)
- When you need the current value once, not subscribe
- Before calling `.notifier` methods

```dart
onPressed: () {
  final user = ref.read(userProvider).activeUser;
  if (user != null) {
    ref.read(userProvider.notifier).saveUser(user);
  }
}
```

---

## 4. Dependency Graph Tips

- **Keep providers shallow.** If `providerA` watches `providerB`, and `providerB` watches `providerC`, code that watches `providerA` will rebuild when `providerC` changes.
- **Use `.select()`** to subscribe to a single field instead of the whole state:
  ```dart
  final userName = ref.watch(userProvider.select((state) => state.activeUser?.name));
  ```
- **Avoid circular dependencies.** If suspicious, run `flutter analyze`.

---

## 5. File Organization

Save each provider (or closely-related provider group) in its own file under `lib/core/providers/`:

```
lib/core/providers/
  audio_service_provider.dart
  user_provider.dart           (includes UserState + UserNotifier)
  quiz_provider.dart           (includes QuizState + QuizNotifier)
  app_theme_provider.dart      (multiple computed providers)
  difficulty_provider.dart     (multiple StateProviders)
```

---

## 6. Comments & Documentation

- **Complex providers only:** If a StateNotifier has non-obvious behavior, add a brief comment:
  ```dart
  /// Manages user profile, quiz history, and quest state.
  /// loadUsers() cleans up legacy demo users and syncs audio settings.
  class UserNotifier extends StateNotifier<UserState> { ... }
  ```
- **Avoid comment clutter:** If the code is self-explanatory, skip it.

---

## Examples from Current Codebase

| Provider | Type | Status |
|----------|------|--------|
| `audioServiceProvider` | Service | ✓ Clean |
| `appThemeProvider` | Computed | ✓ Clean |
| `userProvider` | StateNotifier | ✓ Follows pattern |
| `quizProvider` | StateNotifier | ✓ Follows pattern |
| `ageGroupProvider` | State | ✓ Clean |
| `parentSettingsProvider` | StateNotifier | ✓ Follows pattern |

---

## Checklist for New Providers

- [ ] Provider is in a dedicated file under `lib/core/providers/`
- [ ] Naming follows convention: `[feature]Provider` or `[feature]Notifier`
- [ ] Dependencies use `ref.watch()` (or `ref.read()` if appropriate)
- [ ] State class (if needed) uses `@freezed` or manual `copyWith`
- [ ] Analyzed with `flutter analyze` (no import errors)
- [ ] Tested in relevant test suite (unit/widget)
