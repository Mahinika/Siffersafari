# Beslut & antaganden (Siffersafari)

> Syfte: hålla stabila beslut/antaganden utanför chatten så vi kan återuppta arbetet utan att du behöver repetera.
> Princip: kortfattat, datumstämplat, max 1–3 rader per punkt.

## 2026-03-03
- Vi hanterar långt kontextbehov via "extern kontext": uppdatera `docs/SESSION_BRIEF.md` och denna logg, och hämta detaljer via repo-sök istället för chat-historik.
- Standard QA-flöde: `flutter analyze` → minsta relevanta `flutter test`-subset (full suite bara vid stora ändringar).
- När device-target behövs: defaulta till Pixel_6 om inget annat sägs.
- Appnamn: **Siffersafari**.
- Android-only + offline-first + flera profiler (målgrupp 6–12).
- Install/run ska vara deterministiskt när det behövs: använd `scripts/flutter_pixel6.ps1` (särskilt `-Action sync`).
- UI-screenshot-regression: föredra Flutter-side screenshots via `integration_test/screenshots_test.dart` och extrahera PNG med `scripts/extract_integration_screenshots.ps1` till `artifacts/`.

## 2026-03-04
- Mix-coverage-testet för Åk+step+range stänger av `missing-number`, och gör range/invariant-checks bara för frågor där `operationType != mixed` (specialfrågor som tid/M4/M5 använder `operationType: mixed` och följer inte operand-regler).
- För att ligga närmare Skolverkets centrala innehåll utan att göra appen “för svår för tidigt”: procent och negativa tal introduceras försiktigt som Mix-specialfrågor i Åk 5–6 på höga steps (9–10). Kärn-flödets +/− för Åk 1–6 förblir icke-negativt.
- Textuppgifter: vid första onboarding för ett barn (om ingen inställning är sparad) frågar vi “Kan barnet läsa?”; svar Ja/Nej sparas per barn. Om onboarding hoppas över och inget är sparat: default = AV för Åk 1, annars följer global default.

## 2026-03-06
- Uppdateringsflöde i Föräldraläge: appen kontrollerar senaste GitHub Release via GitHub Release API och startar Android-uppdatering i appen efter föräldrabekräftelse. Data ska bevaras genom att alltid installera ovanpå befintlig app, aldrig via avinstallation.
- Svårighetsprogression: benchmark-steg ska vara mjukare år-för-år, inte samma block för Åk 4–6 och 7–9.
- Högstadiet (Åk 7–9): signed +/− och M5a-specialer ska introduceras gradvis via step-gates; step 1 i Mix ska fortfarande kännas som lugn aritmetik.
- Responsiv layout ska styras av tillgänglig fönsterbredd, inte enhetstyp: `compact < 600`, `medium >= 600`, `expanded >= 840`.
- På smala skärmar ska dropdown-/inställningskontroller ligga under texten i stället för i `ListTile.trailing` för att undvika overflow i portrait/landscape och vid större textskalning.
- På `expanded`-bredd ska informationsrika skärmar föredra riktiga tvåkolumnslayouter framför en ensam centrerad telefonkolumn.
- Quizvyn ska också styras av tillgänglig bredd/höjd, inte bara orientation: använd split-layout först när ytan faktiskt räcker, och låt svarsalternativ växla till 2 kolumner på bred eller kort svarspanel.
- Story-reveal i resultat ska triggas av faktisk quest-completion/advance, inte av stjärnor eller score ensamt.
- Storyns jungle-landmarks ska definieras i derived progression-lagret och återanvändas i Home/karta/results, inte hårdkodas separat per skärm.
- Storykortets hero på Home ska i första hand återanvända befintliga tema-assets (`questHeroAsset` + `characterAsset`) i stället för att kräva en separat story-specifik assetpipeline.
- Kartans checkpointkort ska få sina motiv från derived storydata (`sceneTag`) och vara responsiva nog att fungera även på smala test-/mobilbredder.
- Standard-pathen för storykartan ska vara 20 riktiga uppdrag/checkpoints för normal progression; kartans layout får därför inte ha en fast maxhöjd som klipper senare noder.
- När kartan har många checkpoints ska den delas upp visuellt i etapper (t.ex. block om 5) så lång scroll fortfarande känns läsbar och avsiktlig.

## 2026-03-09
- Ville- och mascot-animationer ska standardiseras på Lottie. Sprite-sekvenser, procedural mascot-rörelse och lokala browser/generator-preview-spår ska inte längre vara aktiva alternativ i repo:t.
- Om en avsedd mascot-Lottie ännu inte finns på sin path ska UI:t visa placeholder i mascot-ytor, inte falla tillbaka till bild- eller spriteanimation.
- Om en lokal preview behövs för snabb visuell kontroll ska den läsa samma JSON från `assets/animations/` som appen använder eller planerar att använda, inte en separat preview-spec.
- Adaptiv svårighetsgrad: hybrid-modell med mikro (3 rätt / 2 fel i rad) + makro (5-fråge-fönster, 0.85/0.60) + 2-fråge-cooldown. Steg ändras när mikro+makro är överens eller mikro neutral + makro har signal. Persisteras per räknesätt i `UserProgress.operationDifficultySteps`.

## 2026-03-10
- Karaktärsanimationer går vidare med hybridstrategi: **Rive för karaktärer** (Ville med state machine) och **Lottie för UI-effekter** (confetti/stars/success/error).
- Assetstruktur för karaktärer ligger under `assets/characters/ville/{svg,rive,config}` och UI-effekter under `assets/ui/lottie`.
- Triggerkoppling för Ville ska finnas i huvudscreens: `home` (enter/screen change), `quiz` (answer_correct/answer_wrong/user_tap/screen_change), `results` (celebrate).
