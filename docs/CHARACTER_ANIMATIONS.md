# Karaktärsanimationer (Ville / character_v2)

Mål: använda maskoten (t.ex. `character_v2`) som **animerad** figur i UI utan att introducera nya flöden.

## Nuläge (2026-03-05)

- ✅ **Idle-animation** används i appen (`assets/images/characters/character_v2/idle/`)
- ✅ Widgeten `MascotView` stödjer frame-sekvenser (loop)
- ✅ `MascotView` stödjer nu också procedural rörelse i Flutter (`float` / `bounce`) ovanpå befintliga assets, som fallback när separata sprite-animationer saknas
- ❌ Jump/Run/Wave är inte implementerade (assets borttagna)

## Rekommenderad fallback just nu

När nya spriteframes saknas ska Ville inte blockera UI-arbetet. Använd i första hand:

- idle-frame-sekvens om den finns
- procedural rörelse i `MascotView` för att ge liv åt karaktären utan nya assets

Det här ersätter inte riktiga run/jump-framepacks, men det är den mest tidseffektiva vägen för appens nuvarande behov.

## Asset-struktur

Lägg bara in **kuraterade** frames i `assets/`.
Allt som genereras under iteration ska ligga i `artifacts/` tills det är godkänt.

Struktur:
```
assets/images/characters/
  character_v2/
    idle/
      idle_000.png
      idle_001.png
      ...
```

Konvention:
- Filnamn: `<anim>_<frameno start 000>.png`
- Samma dimensioner för alla frames i en animation
- Transparent bakgrund

## Praktisk användning i appen

Använd i första hand `MascotView` på ett av två sätt:

- frame-sekvens när en färdig idle-animation finns i `assets/images/characters/character_v2/idle/`
- procedural rörelse via `MascotMotionPreset` när en vy behöver liv men inga extra spritepacks finns

Det gör att nya skärmar kan få en levande Ville direkt utan att vänta på fler assetleveranser.
