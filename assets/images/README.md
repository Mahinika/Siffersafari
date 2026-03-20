# Assets - Images

Denna mapp innehåller bildresurser för appen.

## Struktur:

```
images/
├── app_icon/           # Källbilder för app-ikon
│   └── icon_source.png
├── brand/              # Branding (t.ex. Cognifox-logga)
│   └── cognifox_logo.png
├── themes/
│   ├── space/          # Rymdtema-bilder
│   │   ├── background.png
│   │   ├── character.png
│   │   └── quest_hero.png
│   └── jungle/         # Djungeltema-bilder
│       ├── background.png
│       ├── character.png
│       └── quest_hero.png
└── generated/          # Tillfälliga genererade bilder (ej för permanent asset-användning)
```

## Filer som används direkt i appen

- `themes/jungle/background.png`
- `themes/jungle/quest_hero.png`
- `themes/jungle/character.png`
- `themes/space/background.png`
- `themes/space/quest_hero.png`
- `themes/space/character.png`
- `brand/cognifox_logo.png`
- `app_icon/icon_source.png`

## Bildformat:

- **PNG** för transparens (ikoner, element)
- **JPEG** för bakgrunder utan transparens
- **SVG** för skalerbara ikoner (om möjligt)

## Bildstorlekar:

- Ikoner: 48x48, 72x72, 96x96 (olika DPI)
- Bakgrunder: minst 1080x1920 (portrait)
- Karaktärer: 256x256 eller 512x512

## Karaktärer och animation

Denna mapp innehåller statiska bildassets. När en karaktär ska animeras i appen ska animationen i stället ligga som Lottie-fil under `assets/animations/`.

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
