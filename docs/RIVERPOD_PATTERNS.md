# Riverpod Patterns & Standards

Detta dokument etablerar konsekventa mönster för att definiera och använda Riverpod providers i Siffersafari.

## 1. Provider-typer

### Service Provider
Enkel behållare för en injicerad service (ingen state).

```dart
// lib/core/providers/audio_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../di/injection.dart';
import '../services/audio_service.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  return getIt<AudioService>();
});
```

**När ska jag använda denna:** För service-singletons som inte förändras eller beror på andra providers.  
**watch vs read:** Använd `ref.watch()` om servicen observeras i realtid; använd `ref.read()` i event handlers.

---

### State Provider
Enkel mutable state som ägs av UI:t (t.ex. filterval, temporär UI-state).

```dart
// Example-only snippet
final selectedTabProvider = StateProvider<int>((ref) => 0);
```

**När ska jag använda denna:** För UI-transient state som inte kräver persisterad logik.  
**Livscykel:** Sätts om på app-stäng; uppdatera med `ref.read(provider.notifier).state = newValue`.

---

### Computed Provider
Skrivskyddad värde härledd från att observera andra providers.

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

**När ska jag använda denna:** För härledd state som beror på en eller fler andra providers.  
**watch vs read:** Använd alltid `ref.watch()` för att hålla synk.

---

### StateNotifier Provider
Komplex state med affärslogik. Kapslar in mutationer och invarianter.

**Filstruktur:**
1. State-klass (manuell `copyWith`)
2. StateNotifier-klass (innehåller logik & mutationer)
3. Final provider-definition

```dart
// lib/core/providers/user_provider.dart

class UserState {
  const UserState({
    this.activeUser,
    this.allUsers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final UserProgress? activeUser;
  final List<UserProgress> allUsers;
  final bool isLoading;
  final String? errorMessage;

  UserState copyWith({
    UserProgress? activeUser,
    List<UserProgress>? allUsers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserState(
      activeUser: activeUser ?? this.activeUser,
      allUsers: allUsers ?? this.allUsers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
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

**När ska jag använda denna:** För domain state med beteende (t.ex. quiz-session, användarprofil, inställningar).  
**watch vs read:** Använd `ref.watch()` i build; använd `ref.read()` i event handlers (knappklick, formuläruppsändning).

---

## 2. Namngivningskonventioner

| Mönster | Exempel | Kommentar |
|---------|---------|----------|
| Service provider | `audioServiceProvider` | Inte `audioProvider` |
| State provider | `selectedTabProvider` | Namnge staten, inte providern |
| Computed provider | `appThemeConfigProvider` | Beskrivande namn för härledd värde |
| StateNotifier | `UserNotifier` | Suffix med `Notifier` |
| StateNotifier provider | `userProvider` | Inte `userNotifierProvider` |

---

## 3. watch vs read Riktlinjer

### Använd `watch()`:
- I widget build-metoder
- För alla providers som behöver realtidssynkronisering
- När resultatet används i UI:n

```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider).activeUser; // Bygga om när användare ändras
    return Text(user?.name ?? 'Ingen användare');
  }
}
```

### Använd `read()`:
- I event handlers (knappklick, formuläruppsändning)
- När du behöver aktuellt värde en gång, inte prenumerera
- Före anrop av `.notifier` metoder

```dart
onPressed: () {
  final user = ref.read(userProvider).activeUser;
  if (user != null) {
    ref.read(userProvider.notifier).saveUser(user);
  }
}
```

---

## 4. Tips för Dependency Graph

- **Håll providers grundliga.** Om `providerA` observerar `providerB`, och `providerB` observerar `providerC`, kommer kod som observerar `providerA` att bygga om när `providerC` ändras.
- **Använd `.select()`** för att prenumerara på ett enda fält istället för hela staten:
  ```dart
  final userName = ref.watch(userProvider.select((state) => state.activeUser?.name));
  ```
- **Undvik cirkulära beroenden.** Om du är misstänksam, kör `flutter analyze`.

---

## 5. Filorganisation

Spara varje provider (eller nära befolkad provider-grupp) i sin egen fil under `lib/core/providers/`:

```
lib/core/providers/
  audio_service_provider.dart
  user_provider.dart           (inkluderar UserState + UserNotifier)
  quiz_provider.dart           (inkluderar QuizState + QuizNotifier)
  app_theme_provider.dart      (flera beräknade providers)
```

---

## 6. Kommentarer & Dokumentation

- **Endast komplexa providers:** Om en StateNotifier har icke-uppenbart beteende, lägg till en kort kommentar:
  ```dart
  /// Hanterar användarprofil, quizhistorik och quest-state.
  /// loadUsers() rensar äldre demo-användare och synkroniserar ljudinställningar.
  class UserNotifier extends StateNotifier<UserState> { ... }
  ```
- **Undvik kommentarverkan:** Om koden är självförklarande, hoppa över den.

---

## Exempel från Aktuell Kodbas

| Provider | Typ | Status |
|----------|-----|--------|
| `audioServiceProvider` | Service | ✓ Ren |
| `appThemeProvider` | Computed | ✓ Ren |
| `userProvider` | StateNotifier | ✓ Följer mönster |
| `quizProvider` | StateNotifier | ✓ Följer mönster |
| `parentSettingsProvider` | StateNotifier | ✓ Följer mönster |

---

## Checklista för Nya Providers

- [ ] Provider är i en dedikerad fil under `lib/core/providers/`
- [ ] Namngivning följer konvention: `[feature]Provider` eller `[feature]Notifier`
- [ ] Beroenden använder `ref.watch()` (eller `ref.read()` om lämpligt)
- [ ] State-klass (om behövs) använder manuell `copyWith`
- [ ] Analyserad med `flutter analyze` (inga importfel)
- [ ] Testad i relevant testsvit (unit/widget)
