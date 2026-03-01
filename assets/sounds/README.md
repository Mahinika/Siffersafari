# Assets - Sounds

Denna mapp innehåller ljudfiler för appen.

## Nödvändiga ljudfiler:

Appen försöker spela **MP3 först**, och faller tillbaka till **WAV** om MP3 saknas.

1. **correct.mp3** (eller **correct.wav**) - Ljud när användaren svarar rätt
2. **wrong.mp3** (eller **wrong.wav**) - Ljud när användaren svarar fel
3. **celebration.mp3** (eller **celebration.wav**) - Ljud vid framgång/upplåsning
4. **click.mp3** (eller **click.wav**) - Ljud för knapptryckningar
5. **background_music.mp3** (eller **background_music.wav**) - Bakgrundsmusik (valfritt)

I projektet finns enkla, egen-genererade WAV-filer (original) som fungerar direkt.

## Generera lekiga standardljud (lokalt)

Det finns ett litet script som kan (om)generera enkla, barnvänliga standardljud som WAV:

`dart run scripts/generate_sfx_wav.dart --out assets/sounds`

Om du bara vill regenerera ett specifikt ljud (för att inte skriva över andra som du redan gillar), använd `--only`:

`dart run scripts/generate_sfx_wav.dart --out assets/sounds --only celebration`

Scriptet skapar alltid en timestampad backup av befintliga `.wav`-filer innan det skriver över.

## Rekommendationer:

- Format: MP3, WAV eller OGG
- Kort varaktighet (0.5-2 sekunder för effekter)
- Lagom volym
- Barnvänliga, positiva ljud

## Resurser för gratis ljud:

- https://freesound.org
- https://mixkit.co/free-sound-effects/
- https://pixabay.com/sound-effects/
- https://www.zapsplat.com

## Licens:

Säkerställ att alla ljudfiler har lämpliga licenser för kommersiellt eller privat bruk.
