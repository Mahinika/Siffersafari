# Assets - Images

Denna mapp innehåller bildresurser för appen.

## Struktur:

```
images/
├── app_icon.svg        # App-ikon (SVG)
├── themes/
│   ├── space/          # Rymdtema-bilder
│   │   ├── background.png
│   │   ├── character.png
│   │   ├── icons/
│   │   └── decorations/
│   └── jungle/         # Djungeltema-bilder
│       ├── background.png
│       ├── character_v2.png
│       ├── icons/
│       └── decorations/
├── icons/              # Gemensamma ikoner
├── badges/             # Belöningar och medaljer
└── avatars/            # Användaravatarer
```

## Bildformat:

- **PNG** för transparens (ikoner, element)
- **JPEG** för bakgrunder utan transparens
- **SVG** för skalerbara ikoner (om möjligt)

## Bildstorlekar:

- Ikoner: 48x48, 72x72, 96x96 (olika DPI)
- Bakgrunder: minst 1080x1920 (portrait)
- Karaktärer: 256x256 eller 512x512

## Karaktärsanimationer (frames)

För enkla animationer (t.ex. idle/wave) kan vi använda frame-sekvenser.

Rekommenderad struktur:

```
images/
└── characters/
	└── character_v2/
		├── idle/idle_000.png
		└── wave/wave_000.png
```

Se även `docs/CHARACTER_ANIMATIONS.md`.

## Optimering:

- Komprimera bilder med TinyPNG eller ImageOptim
- Använd lämplig upplösning (inte större än nödvändigt)
- Använd @2x, @3x suffixes för olika DPI-varianter

## Resurser för gratis bilder:

- https://unsplash.com
- https://www.flaticon.com (för ikoner)
- https://www.freepik.com
- https://pixabay.com

## Designriktlinjer:

### Rymdtema:
- Färger: Mörkblå, lila, gul (stjärnor)
- Stil: Friendly space, inte för sci-fi
- Element: Planeter, stjärnor, raketer, astronauter

### Djungeltema:
- Färger: Grönt, brunt, gult
- Stil: Lekfull djungel, inte för mörk eller skrämmande
- Element: Träd, blad, djur, lianer

## Licens:

Säkerställ att alla bilder har lämpliga licenser.
