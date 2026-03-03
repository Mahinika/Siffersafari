# Copilot-instruktioner (Multiplikation)

- Svara på svenska som standard (byt bara språk om jag ber om det).
- Håll svar korta och konkreta som standard.
- När vi löser ett komplext problem: spara en kort notis om vad som fungerade (utan känsliga detaljer). Om du är osäker, fråga innan du sparar.

## Kontext-hantering (för att "utöka" effektiv context window)

- Använd repo-filer som extern kontext och håll dem uppdaterade:
	- `docs/SESSION_BRIEF.md` (kort status: mål, läge, nästa steg)
	- `docs/DECISIONS_LOG.md` (stabila beslut/antaganden med datum)
- Standardrutin:
	- Lätt synk alltid: läs/utgå från `docs/SESSION_BRIEF.md` i början av arbetet och när användaren säger "fortsätt".
	- Djup synk vid behov: läs även `docs/DECISIONS_LOG.md` + gör repo-sök när uppgiften är komplex, när något är oklart, eller när vi återbesöker ett tidigare fel.
- Efter större delsteg (fix, feature, felsökningsgenombrott): uppdatera `docs/SESSION_BRIEF.md` med vad som nu är sant och vad nästa steg är.
- När ett beslut tas (t.ex. standardflöde, device-target, port/paths): lägg till en kort punkt i `docs/DECISIONS_LOG.md`.
- Undvik att fylla chatten med långa loggar/outputs: hämta via verktyg, sammanfatta bara det viktiga och lägg ev. rådata i filer under `artifacts/` vid behov.
- När något refereras som "som förra gången": utgå från repo-sök + dessa två filer istället för att förlita dig på chat-historik.
