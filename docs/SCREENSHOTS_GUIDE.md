# Screenshot guide (App stores / QA)

## Syfte
Den här guiden beskriver ett minimalt och reproducerbart sätt att ta skärmbilder.

## Rekommenderade skärmar
1. Startsida (med aktiv användare, stats och räknesätt)
2. Quiz (en fråga med svarsalternativ)
3. Feedback-dialog (rätt/fel)
4. Resultat (stjärnor + celebration vid bra resultat)
5. Inställningar (profil + årskurs)
6. Föräldraläge (dashboard)

## Checklista
- Samma språk (svenska) i alla bilder.
- Samma profilnamn (t.ex. "Alex") i alla bilder.
- Ta bilder i både ljust och mörkt rum om du vill se kontrast.

## Android (emulator)
- Starta emulator (t.ex. Pixel_6).
- Kör appen och navigera till önskad vy.
- Ta screenshot via Android Studio/adb.

## Namngivning
Föreslagen struktur:
- `artifacts/screenshots/<device>_<screen>_<yyyy-mm-dd>.png`
