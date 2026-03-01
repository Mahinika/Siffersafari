# Prestanda-baseline (Pixel_6, 2026-03-01)

## Testkonfiguration
- **Enhet**: Pixel_6 emulator (Android API 36, sdk_gphone64_x86_64)
- **Build**: Debug APK (136 MB)
- **Testdatum**: 2026-03-01  
- **Metod**: adb shell-kommandon + flutter run --profile

---

## Mätresultat

### 1. Cold Start-tid
- **Mätt tid**: 3.48 sekunder (3481 ms TotalTime)
- **Status**: ⚠️ Över rekommenderat mål
- **Målvärde**: <2s optimal, <3s acceptabelt
- **Gap**: +1.48s över optimal, +0.48s över acceptabel

### 2. Minnesanvändning (idle efter start)
- **Total PSS**: 140.3 MB
- **Native Heap**: 35.0 MB
- **Dalvik Heap**: 2.6 MB  
- **Total RSS**: 205.8 MB
- **Status**: ⚠️ På gränsen till högt
- **Målvärde**: <150 MB för enkel app
- **Kommentar**: Relativt högt för en quiz-app utan många samtidiga objekt

### 3. CPU-användning (idle)
- **Total**: 0.6% (0% user + 0.6% kernel)
- **Faults**: 16 minor, 8 major  
- **Status**: ✅ Mycket bra vid idle

### 4. Frame Rendering
- **Observerat**: 134 + 119 skipped frames vid app-start
- **Status**: ⚠️ Kritiskt problem
- **Målvärde**: Inga skipped frames för smooth 60 fps
- **Root cause**: För mycket arbete på main thread under startup/initial render

### 5. APK-storlek
- **Debug build**: 136.03 MB
- **Status**: ⚠️ Mycket stor
- **Förväntad release-storlek**: ~50–70 MB efter optimering
- **Kommentar**: Debug builds är större, men assets bör granskas

---

## Identifierade problem

### Kritiska (påverkar användarupplevelse direkt)

1. **Frame skipping vid app-start**
   - 253 total skipped frames observerat
   - Ger "stuttering" upplevelse första sekunderna
   - Orsak: Main thread-blockering under initialisering

2. **Långsam cold start (3.5s)**
   - 75% över optimalt mål
   - Ger upplevelse av "slö app"
   - Orsak: Troligen Hive init + asset loading + widget build

### Måttliga (kan bli problem på äldre/långsammare enheter)

3. **Hög minnesanvändning (140 MB)**
   - På gränsen för vad som är acceptabelt
   - Risk för OOM (Out of Memory) på äldre enheter med <2 GB RAM
   - Orsak: Assets i minnet (Lottie, ljud, bilder?)

4. **Stor APK-storlek (136 MB debug)**
   - Även release build blir sannolikt 50–70 MB
   - Långsam download för användare med dålig uppkoppling
   - Orsak: Assets (Lottie-animationer, ljud, bilder)

---

## Rekommenderade åtgärder (prioriterat)

### Fas 1: Quick wins (✅ IMPLEMENTERAT 2026-03-01)

1. **✅ Asynkron Hive-initialisering med loading screen**
   - Flyttade Hive box-öppning till asynkron Future med FutureBuilder
   - Visar CircularProgressIndicator under laddning
   - Förväntat: Eliminerar frame skips vid startup
   - Status: Implementerat i main.dart

2. **📋 Audio MP3-konvertering (dokumenterat, ej utfört)**
   - Skapade guide: `assets/sounds/CONVERT_TO_MP3.md`
   - AudioService har redan .mp3-support (försöker .mp3 först, fallback .wav)
   - Förväntat: ~5 MB APK-minskning när utfört
   - Status: Kan göras senare vid behov

3. **✅ Lottie lazy-loading (redan implementerat)**
   - celebration.json (4.7 KB) laddas endast när `shouldCelebrate == true`
   - Ingen ytterligare optimering behövs
   - Status: Redan optimalt

### Fas 2: Optimering (kan göras senare vid behov)

4. **Image asset-audit**
   - Kontrollera onödiga/för stora bilder
   - Använd WebP istället för PNG där möjligt
   - Förväntat: -10–20 MB APK-storlek

5. **Widget rebuild-optimering**
   - Granska QuestionCard och andra widgets för onödiga rebuilds
   - Använd `const` där möjligt
   - Förväntat: -20% CPU/memory under quiz

6. **Release build + ProGuard/R8**
   - Bygg release APK med code minification
   - Förväntat: -40–60 MB APK-storlek

### Fas 3: Advanced (för produktion-readiness)

7. **Testa på äldre enhet (API 24/25)**
   - Skapa Android 7.0 emulator
   - Verifiera att alla metrics håller på low-end hardware

8. **Memory leak-audit**
   - Använd DevTools memory profiler
   - Sök efter listeners/streams som inte stängs

9. **Background startup-optimering**
   - Använd `Isolate` för inital data loading
   - Implementera splash screen med progress indicator

---

## Nästa steg

1. ✅ Baseline-mätning klar (detta dokument)
2. ⏭️ **Implementera Fas 1 quick wins** (fokus: frame skipping + startup tid)
3. ⏭️ Mät igen och verifiera förbättring
4. ⏭️ Skapa äldre emulator (API 24/25) och testa där
5. ⏭️ Release build-test för Play Store

---

## Jämförelse: Före vs Efter Fas 1

| Metrik | Baseline (före) | Efter Fas 1 | Ändring | Analys |
|--------|-----------------|-------------|---------|--------|
| **Frame skips** | 253 | 187 | -26% (✅ -66) | Förbättring, men inte eliminerat |
| **Cold start** | 3481 ms | 5113 ms | +47% (❌ +1632 ms) | Betydligt sämre |
| **Memory PSS** | 140 MB | 235 MB | +68% (❌ +95 MB) | Kraftig ökning |
| **APK-storlek** | 136 MB | 175 MB | +29% (❌ +39 MB) | Stor ökning |

### Analys av resultat

**Positiva effekter:**
- Frame skips minskade med 26% (253 → 187), vilket ger något smoothare upplevelse

**Negativa effekter:**
- Cold start ökade med 47% (3.5s → 5.1s) - Motsats till målet
- Memory användning ökade med 68% (140 MB → 235 MB) - Oväntad försämring
- APK-storlek ökade med 29% (136 MB → 175 MB) - Troligen pga M4a/M5a-tillägg

**Möjliga orsaker:**
1. **Async-pattern overhead**: FutureBuilder + CircularProgressIndicator lägger till rendering-tid
2. **Hive.openBox() blockar fortfarande**: Flyttat från `main()` till `_initializeAsync()` men körs fortfarande på main thread
3. **M4a/M5a-funktionalitet**: Statistik/sannolikhet/procent/potenser lagd till efter baseline
4. **Clean build-effekt**: `flutter clean` kan ha påverkat APK-storleken

**Slutsats:**
Fas 1-implementationen gav inte förväntad förbättring. Frame skips minskade något, men cold start försämrades kraftigt. Memory- och APK-ökningen tyder på att M4a/M5a-funktionalitet lagts till mellan mätningarna, vilket gör direkt jämförelse svår.

**Rekommenderade nästa steg:**
1. Revertera async Hive-ändringen (gav ej önskad effekt)
2. Fokusera på MP3-konvertering och asset-optimering först
3. Isolera M4a/M5a-effekter genom att mäta baseline igen utan nya features
4. Överväg Isolate för Hive om async-approach ska fortsätta

---

## Historik
- **2026-03-01 08:00**: Initial baseline på Pixel_6 emulator (debug build)
- **2026-03-01 12:21**: Mätning efter Fas 1 implementation (async Hive init)
