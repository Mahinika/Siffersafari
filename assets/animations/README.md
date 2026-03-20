# Assets - Animations

Denna mapp innehåller Lottie-animationer (.json) för appen.

## Nuvarande animationer

Just nu används minst en Lottie-fil i appen:

1. **celebration.json** - visad på resultatskärmen vid bra resultat / upplåsning

Nya mascot- eller karaktärsanimationer ska också läggas här som Lottie-filer när de är godkända.

Planerade mascot-paths i temat just nu:

- `assets/animations/mascot_jungle_idle.json`
- `assets/animations/mascot_space_idle.json`

Om dessa filer ännu inte finns visar mascot-ytorna placeholder tills de riktiga animationerna är levererade.

För snabb visuell kontroll utanför emulatorn finns även en lokal HTML-preview i `artifacts/animation_preview/mascot_walk_preview/` som laddar referensfilen `artifacts/animation_reference/mascot_walk_cycle.json`. Referensen är inte en shipad runtime-asset.

## Format:

- Lottie JSON-filer
- Exporterade från Adobe After Effects med Bodymovin plugin
- Eller från LottieFiles

## Resurser för gratis Lottie-animationer:

- https://lottiefiles.com (Free animations)
- https://iconscout.com/lottie-animations
- https://lottiefiles.com/featured (Curated collections)

## Optimering:

- Håll filstorlekar under 100KB per animation
- Använd enkla animationer för bättre prestanda
- Begränsa antalet lager och effekter
- Undvik parallella sprite- eller proceduralspår för samma animation i appen

## Licens:

Säkerställ att alla animationer har lämpliga licenser.
