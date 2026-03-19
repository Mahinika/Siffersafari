# Environment Setup Reference

Denna guide ar for detaljerad miljokonfiguration nar nagot inte funkar i `GETTING_STARTED.md` eller du behover en fran-scratch-installation.

Startklar snabbversion? Se [GETTING_STARTED.md](GETTING_STARTED.md) i stallet.

---

## 1. System Requirements

| Komponent | Minimum | Rekommenderat | Testats pa |
|-----------|---------|----------------|-----------|
| Windows | 10 | 11 | Windows 11 |
| RAM | 8 GB | 16 GB | 16 GB |
| Disk | 10 GB fritt | 30 GB fritt | 50 GB |
| Java | JDK 11 | JDK 11+ | JDK 17 |
| Android SDK | API 30 | API 34+ | API 34 |

---

## 2. Installation Steps

### A. Flutter SDK

**Installation:**
```bash
# 1. Ladda ned Flutter fran https://flutter.dev/docs/get-started/install/windows
# 2. Packa upp i lamplig plats (ex: C:\flutter)
# 3. Lagg till i PATH:
#    Control Panel -> System -> Environment Variables -> Path -> New: C:\flutter\bin

# 4. Verifiera installation
flutter doctor

# Forvantat output (versioner kan variera):
# Doctor summary (to see all details, run flutter doctor -v):
# [✓] Flutter
# [✓] Android toolchain
# [✓] Chrome
```

**Troubleshooting:**
```bash
# Om flutter doctor visar fel:
flutter doctor --verbose

# Acceptera Android licenses
flutter doctor --android-licenses

# Uppdatera Flutter (om det behovs)
flutter upgrade
flutter pub get
```

---

### B. Android SDK & NDK

Installera via Android Studio (enklast):

1. Ladda ned Android Studio fran https://developer.android.com/studio
2. Kor installationen och acceptera defaults
3. Oppna SDK Manager (Tools -> SDK Manager)
4. Installera:
   - Android SDK Platform API 34 eller senare
   - Android SDK Build-Tools 34.x
   - Android Emulator
   - Android SDK Platform-Tools

Verifiera:
```bash
flutter doctor

# Forvantat:
# [✓] Android toolchain - develop for Android devices (Android SDK version 34.x)
```

---

### C. Java/JDK

**Check om redan installerad:**
```bash
java -version
javac -version
```

**Om inte:**
1. Ladda ned JDK 17 fran https://www.oracle.com/java/technologies/downloads/
2. Installera och acceptera defaults
3. Verifiera:
   ```bash
   java -version
   ```

---

### D. Android Emulator (Pixel_6)

Vi anvander `Pixel_6` for all testning for konsistens.

**Skapa emulatorn:**
```bash
# Via Android Studio GUI:
# 1. Tools -> Device Manager
# 2. Create Device -> Pixel 6
# 3. Select API 34 (eller senare)
# 4. Finish

# Eller via kommandorad:
sdkmanager "system-images;android-34;default;x86_64"
avdmanager create avd -n Pixel_6 -k "system-images;android-34;default;x86_64" -d "Pixel 6"
```

**Starta:**
```bash
# Via Android Studio GUI eller:
emulator -avd Pixel_6 -wipe-data -gpu auto

# Vanta tills:
# - Boot-animation slutar
# - "adb devices" visar enheten
adb devices
```

---

## 3. Projekt Setup

### Initial Checkout

```bash
cd d:\Projects\Personal\Siffersafari
git clone <repo-url> .
git pull
```

### Dependencies

```bash
flutter pub get
```

Om du far dependency-fel:
```bash
flutter pub upgrade
flutter pub cache repair
```

### Code Generation

Vissa filer genereras automatiskt, till exempel Hive TypeAdapters:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Genererade filer hamnar till exempel har:
- `lib/domain/entities/user_progress.g.dart`

### Lint & Analysis

```bash
flutter analyze
```

---

## 4. Vanliga Fel & Losningar

### "flutter: command not found"
- Orsak: Flutter ar inte i PATH
- Losning: Se steg 2A ovan

### "Android SDK not found"
- Orsak: Android SDK ar inte installerad
- Losning: Se steg 2B

### "java: command not found"
- Orsak: Java/JDK ar inte installerad
- Losning: Se steg 2C

### "Emulator won't start"
- Orsak: AMD/Intel virtualization ar inte aktiverad i BIOS
- Losning:
  ```bash
  systeminfo | findstr Hyper-V
  ```

### "adb device offline / unauthorized"
- Orsak: Emulatorn ar inte fullt startad
- Losning:
  ```bash
  adb kill-server
  adb start-server
  adb wait-for-device
  adb devices
  ```

### "Permission denied: build/apk..."
- Orsak: Windows laser filer
- Losning:
  ```bash
  flutter clean
  flutter pub get
  flutter build apk --debug
  ```

---

## 5. Snabbtest

Verifiera hela setupen:

```bash
# 1. Starta emulator (terminal 1)
emulator -avd Pixel_6 -wipe-data

# 2. I annan terminal, i projektets root:
flutter analyze
flutter test test/unit/audits/offline_only_audit_test.dart -v
flutter run -d emulator-<id>
```

Forvantat resultat: appen startar pa emulatorn utan fel.

---

## 6. IDE Setup (VS Code)

Rekommenderat for detta projekt:

**Extensions:**
- Flutter (`Dart-Code.flutter`)
- Dart (`Dart-Code.dart-code`)
- Error Lens (`usernamehw.errorlens`)
- Mermaid-stod for docs (`bierner.markdown-mermaid`, `bpruitt-goddard.mermaid-markdown-syntax-highlighting`)

**Workspace setup som redan finns i repot:**
- `.vscode/settings.json` aktiverar Dart-formattering, hot reload on save, mindre brus i Explorer/Search och file nesting for genererade filer
- `.vscode/extensions.json` rekommenderar projektets VS Code-tillagg
- `.vscode/launch.json` innehaller fardiga Flutter-profiler for vanlig debug och `Pixel_6`
- `.vscode/tasks.json` innehaller QA-, Pixel_6- och asset-pipeline-tasks

**Rekommenderat arbetsflode i VS Code:**
1. Oppna repo-roten i VS Code.
2. Acceptera rekommenderade extensions nar VS Code fragar.
3. Kor `Developer: Reload Window` efter forsta installationen av extensions.
4. Anvand `Run and Debug` for:
   - `Flutter: Debug`
   - `Flutter: Debug (Pixel_6)`
   - `Flutter: Profile (Pixel_6)`
   - `Flutter: Release (Pixel_6)`
5. Anvand `Tasks: Run Task` for:
   - `QA: Analyze`
   - `QA: Analyze + Test (valfri path)`
   - `QA: Analyze + Full Test (stora andringar)`
   - `Pixel_6: Sync + QA (valfri testpath)`

Du behover normalt inte satta `dart.flutterSdkPath` i repo-settings. Om Flutter inte hittas, lagg det i dina personliga User Settings i stallet.

---

## Nasta Steg

Setup klar? Da:
- [GETTING_STARTED.md](GETTING_STARTED.md) - Kor forsta testningen
- [ADD_FEATURE.md](ADD_FEATURE.md) - Lagg till en feature
- [CONTRIBUTING.md](CONTRIBUTING.md) - QA-rutiner innan commit
