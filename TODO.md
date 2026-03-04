# TODO

## 10 hog-ROI att implementera

- [x] 1. CI-gate for kvalitet i varje push
  - Scope: GitHub Actions som kor `flutter analyze` + relevanta tester pa pull requests.
  - ROI: Stoppar regressions tidigt och sparar mycket manuell QA-tid.
  - Status: Klar (MVP) via `.github/workflows/flutter.yml` med `flutter analyze lib test integration_test` + `flutter test test`.

- [x] 2. Offline-only verifikation (kod + end-to-end)
  - Scope: Audit av kodbasen for natverksanrop + smoke test i flygplanslage.
  - ROI: Skyddar en av appens viktigaste produktfordelar (offline-first).
  - Status: Kod-audit klar via `test/offline_only_audit_test.dart` (forbjudna natverksmönster i `lib/`).

- [x] 3. Testmatris for rekommendationssystemet (Under/I linje/Over)
  - Scope: Enhetstester for `DifficultyConfig.compareDifficultyStepToGrade()` over Ak 1-9 och alla raknesatt.
  - ROI: Hog pedagogisk precision med lag implementationstid.
  - Status: Utokad testmatris i `test/difficulty_config_test.dart` (Åk 1-9, alla räknesätt, tolerance ±2).

- [x] 4. Validering av manuell stegjustering i foraldralage
  - Scope: Tester for `Lat tare/Svarare`-flodet inklusive guardrails (+/- max/min steg).
  - ROI: Minskar risken for fel i ett kritiskt foraldraflode.
  - Status: Utokade tester i `test/difficulty_config_test.dart` for stegskalning mot/ifran indikator.

- [x] 5. Spaced repetition: verifiera algoritm med realistiska scenarion
  - Scope: Testfall for intervall, repetition efter misslyckande och progression over tid.
  - ROI: Direkt effekt pa inlarning och retention.
  - Status: Ny testfil `test/spaced_repetition_service_test.dart` (2->7->14 dagar, reset, due-lista).

- [x] 6. Achievement + quest trigger-verifiering
  - Scope: Regressionstester som sakerstaller att alla triggers avfyras exakt en gang och sparas korrekt.
  - ROI: Forhindrar tappad motivation p.g.a. trasiga beloningsfloden.
  - Status: Utokade tester i `test/achievement_service_test.dart` och `test/quest_progression_service_test.dart`.

- [x] 7. Baslinje for prestanda pa lagre Android-enhet
  - Scope: Mata starttid, quiz-respons, minnesanvandning och jitter i nyckelskarmar.
  - ROI: Hog anvandarnytta for malgruppen med enklare enheter.
  - Status: Ny baseline-test `test/performance_baseline_test.dart` for generation + recommendations-berakning.

- [x] 8. Hardening av backup/restore for profiler
  - Scope: Integrations- och feltests for export/import, korrupt fil och versionskompatibilitet.
  - ROI: Skyddar anvandardata och minskar support-risk.
  - Status: Ny `lib/domain/services/profile_backup_service.dart` + tester for korrupt JSON och schema-version.

- [x] 9. Tillganglighet quick wins (screen reader + touch targets + kontrast)
  - Scope: A11y-pass av kritiska skarmar: Home, Quiz, Resultat, Foraldralage.
  - ROI: Stor UX-vinst med relativt liten implementation.
  - Status: Ny a11y-test `test/accessibility_widgets_test.dart` (semantik for svar, framsteg, fraga).

- [x] 10. Release hardening-pipeline (signering + artefaktkontroller)
  - Scope: Automatisk validering av signing-config, app-storlek och release-checklista.
  - ROI: Farre releasefel och snabbare, tryggare leveranser.
  - Status: Ny CI-workflow `.github/workflows/release-guard.yml` med analyze/test/build + APK-size budget.
