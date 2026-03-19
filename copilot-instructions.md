# Copilot-instruktioner (Siffersafari)

## Kommunikation

- Svara på svenska som standard (byt bara språk om jag ber om det).
- Håll svar korta och konkreta som standard.
- När vi löser ett komplext problem: spara en kort notis om vad som fungerade (utan känsliga detaljer). Om du är osäker, fråga innan du sparar.

---

## Vad är detta repo?

**Siffersafari** – ett Flutter-baserat mattesspel för barn (Android-first, offline-first).  
`pubspec.yaml`: `name: siffersafari`, `version: 1.3.0+8`

Primära flödet: Barn väljer profil → quiz (multiplikation/addition/subtraktion) → resultat → story map.  
Föräldraskydd via PIN, adaptiv svårighetsgrad per operationstyp, OTA-uppdatering via GitHub Releases.

---

## Snabbstart för agenter

### Bygga & köra
```sh
flutter pub get          # hämta beroenden
flutter analyze          # statisk analys (kör alltid innan commit)
flutter test             # alla unit/widget-tester
flutter test <path>      # specifikt test
```

Device-target: Pixel_6-emulator via `scripts/flutter_pixel6.ps1`.  
Sätt install-mål med `-Action run|install|sync`.

### QA-standard
1. `flutter analyze` – noll fel/varningar accepteras
2. `flutter test` – relevant delsvit vid smårändring, full suite vid stora ändringar
3. Pixel_6-sync + install vid ändringar som berör assets/navigation/render

→ Se skill **flutter-qa-guard** för exakt arbetsflöde och vanliga fallgropar.

---

## Arkitektur (snabbversion)

| Lager | Plats | Ansvar |
|---|---|---|
| presentation | `lib/presentation/` | Skärmar, dialoger, widgets |
| core | `lib/core/` | DI (GetIt), providers (Riverpod), tjänster, tema |
| domain | `lib/domain/` | Flutter-fri domänlogik, entiteter, enums |
| data | `lib/data/` | LocalStorageRepository (Hive) |

**State:** Riverpod (`StateNotifierProvider` + `Provider`)  
**DI:** GetIt – registrering i `lib/core/di/injection.dart`  
**Persistens:** Hive (`user_progress`, `settings`, `quiz_history`)  
**Animation:** Hybrid – Rive för karaktärer, Lottie för UI-effekter  
**Layout:** responsiv via tillgänglig bredd (`compact <600`, `medium ≥600`, `expanded ≥840`)

→ Fullständigt diagram: `docs/ARCHITECTURE.md`  
→ Servicekontrakt: `docs/SERVICES_API.md`  
→ Filstruktur: `docs/PROJECT_STRUCTURE.md`

---

## Viktiga konventioner

- **Rive `.riv`-filer exporteras manuellt** från Rive Editor – generators och blueprints (under `artifacts/`) producerar *inte* den slutliga `.riv`-filen automatiskt.
- **Mascot-animation fallback:** om `.riv` saknar state machine `MascotStateMachine` + artboard `Mascot` → spelar första legacy-animationen. Ersätter inte kravet på korrekt Rive-export.
- **Nya humanoid-karaktärer** ska referera `assets/characters/_shared/config/humanoid_base_form_v1.json` via `baseFormRef` i visual spec.
- **SpacedRepetitionService** är implementerad och testad men *ej inkopplad* i quiz-flödet ännu.
- **Lottie används inte** som runtime-fallback för mascot – det är ett avslutat spår.
- **Commit-ordning:** analyze → fix → stage avsedda filer → commit. Lämna tomma/orefererade hjälpfiler ostagade.

---

## Vanliga fallgropar

- Pixel_6-emulatorn kan fastna som offline i adb → lös med cold boot utan snapshot (`emulator.exe -avd Pixel_6 -no-snapshot-load`), inte med adb reconnect.
- `flutter_screenutil` kräver `ScreenUtil.init()` i widget-testernas `setUp` – saknas det kraschar tester med dimensionsfel.
- AdaptiveDifficulty uppdateras per session: verifiera att session-state mergas tillbaka till user-profil vid quiz-slutförande, inte bara i runtime.
- Stale APK på device trots rebuild → kör install-action explicit via `flutter_pixel6.ps1 -Action install`.

---

## Kontext-hantering (sessionskontinuitet)

Använd dessa filer som extern kontext i stället för chat-historik:

| Fil | Syfte |
|---|---|
| `docs/SESSION_BRIEF.md` | Aktuellt läge, mål, nästa steg |
| `docs/DECISIONS_LOG.md` | Stabila beslut med datum – senaste vinner |

**Standardrutin:**
- **Lätt synk alltid:** läs `docs/SESSION_BRIEF.md` vid start och när användaren säger "fortsätt".
- **Djup synk vid behov:** läs även `docs/DECISIONS_LOG.md` + gör repo-sök vid komplex uppgift eller vid återbesök av tidigare fel.
- **Efter delsteg:** uppdatera `SESSION_BRIEF.md` med nytt läge och nästa steg.
- **Vid nytt beslut:** lägg till en kort punkt i `DECISIONS_LOG.md`.
- Långa loggar/outputs → sammanfatta i chat, lägg rådata i `artifacts/`.

---

## Skills (repo-specifika arbetsflöden)

Dessa skills aktiveras automatiskt vid matchande uppgifter:

| Skill | Triggar |
|---|---|
| `game-character-pipeline` | ny karaktär från bild, SVG-lager, rig spec, Rive guide |
| `animation-preview-lab` | idle/walk/pivot-animation, motion-lab, clean preview, `artifacts/animation_preview/` |
| `asset-generation-runner` | generera/regenerera assets, SVG-delar, Lottie-effekter, Rive-blueprints |
| `flutter-qa-guard` | analyze, tester, screenshot-regression, Pixel_6 sync/install |
| `release-readiness-check` | release check, ship, preflight, APK-verifiering, taggning |

Skills finns under `.github/skills/<name>/SKILL.md`.

---

## Bildbaserad karaktärspipeline

- När användaren bifogar en bild och ber om en användbar eller spelklar karaktär, följ `.github/instructions/character-pipeline.instructions.md`.
- Målet är faktiska repo-filer under `assets/characters/<slug>/` och `artifacts/`, inte bara generell rådgivning.
- Följ hybridstandarden: Rive för karaktärer, Lottie för UI-effekter.
- Var tydlig om `.riv` måste exporteras manuellt från Rive Editor.
