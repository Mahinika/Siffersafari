# BEFORE RELEASE

## Legal & Compliance (gör ABSOLUT FÖRST)
- [ ] Verifiera att alla lagkrav (GDPR, etc) är uppfyllda
- [ ] Verifiera att privacy policy och terms of service är uppdaterade
- [ ] Kontrollera att alla assets har korrekt copyright/licens
- [ ] Verifiera att permissions är minimala och väldokumenterade

## Security Audit
- [ ] Gör final security audit

## Documentation
- [ ] Säkerställ att all dokumentation är uppdaterad

## Testing & Quality Assurance
- [ ] Kör fullständig regressionstestning på alla enheter
- [ ] Testa appen på lågpresterande enheter
- [ ] Testa med olika språkinställningar
- [ ] Testa installation och avinstallation på flera enheter
- [ ] Testa uppgradering från tidigare version (om relevant)

## Performance & Compatibility
- [ ] Kör prestandatest och åtgärda eventuella flaskhalsar
- [ ] Kontrollera att app-storlek är acceptabel

## Functionality Verification
- [ ] Säkerställ att backup och återställning fungerar
- [ ] Kontrollera att alla länkar och externa resurser fungerar
- [ ] Säkerställ att onboarding fungerar utan internet
- [ ] Arkitektur-audit: verifiera att all data hanteras via Hive och att ingen kod gör nätverksanrop
	- [ ] Sök igenom kodbasen efter nätverksklienter/imports och dokumentera resultat
	- [ ] Verifiera att all persistence går via Hive/repositories
	- [ ] Kör appen i flygplansläge och testa kärnflöden end-to-end
	- [ ] Sign-off: "Offline-only verifierad" i release-noteringar

## Monitoring & Analytics
- [ ] Verifiera att crash reporting fungerar
- [ ] Kontrollera att alla analytics events loggas korrekt

## Build & Signing
- [ ] Verifiera att alla APK-signaturer fungerar korrekt

## Final Polish
- [ ] Gör en sista UI/UX-genomgång och fixa smådetaljer
- [ ] Verifiera att alla texter är korrekt översatta
- [ ] Språkgranska all svensk text i appen: enkel, begriplig och med korrekt grammatik
	- [ ] Granska alla texter för Åk 1-3: korta meningar och enkla ord
	- [ ] Korrigera grammatik, stavning och konsekvent ton i hela appen
	- [ ] Verifiera i appen (inte bara i kod) att sluttexten blev rätt
	- [ ] Sign-off av språkgranskning före release