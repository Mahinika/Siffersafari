# Environment Setup Reference

Denna guide är för **detaljerad miljökonfiguration** när något inte funkar i `GETTING_STARTED.md` eller du behöver en från-scratch-installation.

Startklar snabbversion? Se [GETTING_STARTED.md](../GETTING_STARTED.md) istället.

---

## 1. System Requirements

| Komponent | Minimum | Rekommenderat | Testats på |
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
# 1. Ladda ned Flutter från https://flutter.dev/docs/get-started/install/windows
# 2. Packa upp i lämplig plats (ex: C:\flutter)
# 3. Lägg till i PATH:
#    Control Panel → System → Environment Variables → Path → New: C:\flutter\bin

# 4. Verifiera installation
flutter doctor

# Förväntat output (puede ha varierande versioner):
# Doctor summary (to see all details, run flutter doctor -v):
# [✓] Flutter
# [✓] Android toolchain
# [✓] Chrome
```

**Troubleshooting:**
```bash
# Om flutter doctor visar fel:
flutter doctor --verbose  # Se vilket som fattas

# Acceptera Android licenses
flutter doctor --android-licenses

# Uppdatera Flutter (om det behövs)
flutter upgrade
flutter pub get
```

---

### B. Android SDK & NDK

Installera via Android Studio (enklast):

1. **Ladda ned Android Studio** från https://developer.android.com/studio
2. **Kör installationen** (acceptera defaults)
3. **Öppna SDK Manager** (Tools → SDK Manager)
4. **Installera:**
   - Android SDK Platform API 34 (eller senaste)
   - Android SDK Build-Tools 34.x
   - Android Emulator
   - Android SDK Platform-Tools

Verifiera:
```bash
flutter doctor

# Förväntat:
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
1. Ladda ned **JDK 17** från https://www.oracle.com/java/technologies/downloads/
2. Installera (acceptera defaults)
3. Verifiera:
   ```bash
   java -version  # Ska visa Java 17.x
   ```

---

### D. Android Emulator (Pixel_6)

Vi använder **Pixel_6** för all testning för konsistens.

**Skapa emulatorn:**
```bash
# Via Android Studio GUI:
# 1. Tools → Device Manager
# 2. Create Device → Pixel 6
# 3. Select API 34 (eller senaste)
# 4. Finish

# Eller via kommandorad:
sdkmanager "system-images;android-34;default;x86_64"
avdmanager create avd -n Pixel_6 -k "system-images;android-34;default;x86_64" -d "Pixel 6"
```

**Starta:**
```bash
# Via Android Studio GUI eller:
emulator -avd Pixel_6 -wipe-data -gpu auto

# Vänta tills:
# - Boot-animation slutar
# - "adb devices" visar enheten
adb devices
```

---

## 3. Projekt Setup

### Initial Checkout

```bash
cd d:\Projects\Personal\Siffersafari  # eller din lokala projektmapp
git clone <repo-url> .  # Om nytt clone
git pull                 # Om redan klont
```

### Dependencies

```bash
flutter pub get
```

Om du får dependency-fel:
```bash
flutter pub upgrade
flutter pub cache repair  # Som sista resort
```

### Code Generation

Vissa filer genereras automatiskt (Hive TypeAdapters):

```bash
flutter pub run build_runner build --delete-conflicting-outputs

# Förväntat output:
# [INFO] BuildContext: Building new asset graph...
# [INFO] Building ...
```

Genererade filer hamnar här:
- `lib/domain/entities/user_progress.g.dart`

### Lint & Analysis

```bash
flutter analyze

# Förväntat: "No issues found! (ran in X.Xs)"
```

---

## 4. Vanliga Fel & Lösningar

### "flutter: command not found"
- **Orsak:** Flutter är inte i PATH
- **Lösning:** Se steg 2A ovan (lägg till PATH)

### "Android SDK not found"
- **Orsak:** Android SDK är inte installerad
- **Lösning:** Se steg 2B (install via Android Studio)

### "java: command not found"
- **Orsak:** Java/JDK är inte installerad
- **Lösning:** Se steg 2C

### "Emulator won't start"
- **Orsak:** AMD/Intel virtualization inte aktiverad (BIOS)
- **Lösning:** 
  ```bash
  # Kontrollera virtualization status
  systeminfo | findstr Hyper-V
  
  # Om "Virtualization: Enabled" inte visas, aktivera i BIOS
  ```

### "adb device offline / unauthorized"
- **Orsak:** Emulator inte fullt startad
- **Lösning:**
  ```bash
  adb kill-server
  adb start-server
  adb wait-for-device
  adb devices  # Bör visa enhetens ID
  ```

### "Permission denied: build/apk..."
- **Orsak:** Windows låser filer
- **Lösning:**
  ```bash
  flutter clean
  flutter pub get
  flutter build apk --debug
  ```

---

## 5. Snabbtest

Verifiera hela setup:

```bash
# 1. Starta emulator (terminal 1)
emulator -avd Pixel_6 -wipe-data

# 2. I annan terminal, projektet root:
# Test 1: Analys
flutter analyze

# Test 2: En liten test
flutter test test/offline_only_audit_test.dart -v

# Test 3: Build & deploy
flutter run -d emulator-<id>

# Expected: App startar på emulator, ingen fel
```

---

## 6. IDE Setup (VS Code)

Rekommenderat för detta projekt:

**Extensions:**
- Flutter (Darren Knowles)
- Dart (Dart Code)
- Android Emulator (Hieu Tran)

**Settings** (`.vscode/settings.json`):
```json
{
  "[dart]": {
    "editor.formatOnSave": true,
    "editor.defaultFormatter": "Dart-Code.dart-code"
  },
  "dart.flutterSdkPath": "C:\\flutter"  // Justera path
}
```

---

## Nästa Steg

✅ Setup klar? Då:
- [GETTING_STARTED.md](../GETTING_STARTED.md) — Kör första testningen
- [ADD_FEATURE.md](ADD_FEATURE.md) — Lägg till en feature
- [CONTRIBUTING.md](../CONTRIBUTING.md) — QA-rutiner innan commit
