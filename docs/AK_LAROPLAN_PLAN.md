# Plan: Åk 1–9 (läroplan) → bättre frågegeneration

## Syfte
Använd årskurs-informationen (Åk 1–9) för att:
- generera frågor med rätt **talområde**,
- gradvis introducera rätt **strategier** (t.ex. tiokompisar, tiotalsövergång),
- senare kunna lägga till nya **frågetyper** (textuppgifter, pengar, tid, geometri),
utan att bygga om appen i ett steg.

## Målbild (kort)
- När en förälder sätter barnets Åk ska quizet automatiskt välja rimliga tal och “typiska” strategier för den Åk.
- Föräldern kan alltid överstyra räknesätt och svårighet; Åk är en **guide**, inte ett tak.

## Icke-mål (för att hålla scope)
- Inga nya skärmar i M1/M2/M5a (allt ska gå i befintligt quizflöde).
- Ingen “perfekt läroplanssimulator” — vi siktar på **rimliga** frågor som hjälper barn att träna rätt saker.
- Ingen nätverks- eller inloggningsfunktionalitet.

## Grundprinciper
- **Förståelse före hastighet** (särskilt Åk 1–2).
- **Stabil progression**: små steg, tydliga nivåer.
- **Föräldern har sista ordet**: förälderns val av räknesätt begränsar alltid.
- **Fallback**: om Åk saknas eller data saknas → använd nuvarande logik.

## Källor (Skolverket)
- Lgr22 (grundskolan, webbvisning):
  - https://www.skolverket.se/undervisning/grundskolan/laroplan-lgr22-for-grundskolan-samt-for-forskoleklassen-och-fritidshemmet
  - (Sidan anger även “Läroplan gäller från 2025-08-01”.)
- Kursplan i matematik (grundskolan, ämneskod `GRGRMAT01`, webbvisning):
  - https://www.skolverket.se/undervisning/grundskolan/laroplan-lgr22-for-grundskolan-samt-for-forskoleklassen-och-fritidshemmet#/curriculums/LGR22/GRGRMAT01?schoolType=GR&tosHeading=Kursplaner#GRGRMAT01
  - (Sidan anger även “Ämne gäller från 2022-07-01”.)
- Kommentarmaterial till kursplanen i matematik – grundskolan (publikationssida):
  - https://www.skolverket.se/publikationer?id=9790
- Kommentarmaterial (översiktssida):
  - https://www.skolverket.se/undervisning/grundskolan/kommentarmaterial-till-grundskolan

## Kursplanens struktur (hur vi mappar till appen)
- Skolverkets kursplan för matematik är uppbyggd som:
  - **Ämnets syfte** (inkl. en lista över centrala förmågor, t.ex. begrepp, metoder, problemlösning, resonemang och uttrycksformer).
  - **Centralt innehåll** uppdelat per stadie: **Åk 1–3**, **Åk 4–6**, **Åk 7–9**.
    - Återkommande innehållsområden: *Taluppfattning och tals användning*, *Algebra*, *Geometri*, *Sannolikhet och statistik*, *Samband och förändring*, *Problemlösning*.
    - Det finns också inslag av **digitala verktyg** och **programmering/stegvisa instruktioner** i centralt innehåll.
  - **Kriterier/betygskriterier** i slutet av **Åk 3**, **Åk 6**, **Åk 9**.
- Vår plan använder Åk som **guide** för vilka tal/strategier som är rimliga, men vi låter alltid förälderns val överstyra (som idag).
- Roadmap-mapping:
  - **M1/M2** ≈ börja täcka centralt innehåll Åk 1–3 för de delar som passar vår nuvarande quiz-form (tal, räknesätt, enkla mönster/likheter, enkel problemlösning).
  - **M3** ≈ skala upp mot centralt innehåll Åk 4–6 (t.ex. större tal, bråk/decimal/procent, fler strategier).
  - **M4/M5b** ≈ de delar som behöver ny representation/UI (t.ex. geometri, grafer/diagram).
  - **M5a** ≈ sådant som kan visas som text + svar (t.ex. negativa tal, procent, potenser).

## Gap check (Åk 1–3): vad vi har vs vad som saknas

Det här är en snabb reality-check mot “Centralt innehåll i årskurs 1–3” i Skolverkets kursplan för matematik.

| Område (centralt innehåll Åk 1–3) | Nuläge i appen (quiz) | Nästa steg i planen |
|---|---|---|
| Taluppfattning & räknesätt | **Delvis täckt**: +/−/×/÷ finns, med Åk-formning för tidiga steg (t.ex. tiokompisar och undvik växling tidigt). Division är idag i praktiken “utan rest”. | **M1**: fortsätt bredda taluppfattning (t.ex. tal i bråkform som enkla bråk som “del av helhet” – kräver svar-format). **M3**: procent/decimal senare. |
| Algebra | **Låg täckning**: vi gör mest rutinuppgifter. Vi saknar tydliga uppgifter om likhetstecknets betydelse, obekant tal (t.ex. \_ + 3 = 10), och mönster/talföljder som egen frågetyp. | **M1.5/M2**: lägg till “obekant tal”-uppgifter i befintligt UI (text + svar). M4: visuella mönster om vi vill. |
| Problemlösning | **Delvis**: barn löser problem men nästan alltid som “ren räkning” utan kontext. | **M2**: textuppgifter v1 (kort, 1 steg, låg kognitiv last). |
| Geometri (inkl. mätning/skala/symmetri) | **Saknas** (ingen representation/uppgiftstyp för former, lägesord, mätning av längd/massa/volym/tid, symmetri). | **M4**: modul för geometri + mätning (bör vara av/på + fallback). |
| Sannolikhet & statistik (tabeller/diagram) | **Saknas**. | **M4**: modul för enkla tabeller/diagram + tolkning. |
| Samband & förändring (t.ex. dubbelt/hälften) | **Saknas som eget spår** (kan uppstå i text men vi har inga dedikerade uppgifter). | **M2** (textmallar) eller **M4** (om visualisering behövs). |
| Programmering/stegvisa instruktioner | **Saknas**. | **M4/M5** (om vi prioriterar det pedagogiska värdet; kräver designbeslut). |

Konsekvens: vår nuvarande app är starkast i *Taluppfattning och tals användning* (via räknesätten) men behöver M2/M4 för att bli mer heltäckande mot kursplanens bredd i Åk 1–3.

## Definitioner (så vi pratar samma språk)
- **Åk-styrning**: används för att välja talområde + regler för vilka tal som är “bra” att träna.
- **Intern step (1–10)**: vår finare skala per räknesätt som redan finns (adaptiv svårighet).
- **Constraint**: en regel som filtrerar/bygger tal (t.ex. “undvik växling tidigt”).
- **Frågetyp**: hur uppgiften presenteras (ren räkning, textuppgift, pengar, klocka, diagram…).

## “Definition of done” (för att veta när vi är klara)
- Vi kan peka på mätbara checks (se Acceptance i milstolparna).
- Vi har enhetstester för range/constraints och minst ett flödestest som spelar quiz deterministiskt.
- Om Åk-regler inte kan appliceras (edge-cases) faller vi tillbaka utan crash.

## Arkitektur-idé (lager)
1) **Talområde (range-layer)**
   - Åk + räknesätt + intern step (1–10) → min/max och ev. extra constraints.
   - Mål: "rätt storleksklass" för varje Åk.

2) **Struktur/regler (structure-layer)**
   - Regler som styr *vilka typer av tal* som väljs:
     - Åk 1: tiokompisar, summa inom 10 tidigt, enkla minus (10−x).
     - Åk 2: gradvis tiotalsövergång, undvik växling tidigt.
     - Åk 3: fler strategier, större talområde.
   - Mål: frågor tränar rätt strategi, inte bara rätt sifferspann.

3) **Frågetyper (question-type-layer)**
   - V1: rena räkneuppgifter (finns redan)
   - V2: textuppgifter (vardag) som fortfarande mappas till +/−/×/÷
   - V3: pengar/tid/geometri/mönster (nya representationer)

4) **Fördelning (mixing-layer)**
   - Per Åk: bestäm ungefärlig mix (%-fördelning) mellan frågetyper.
   - Exempel: Åk 1: mest +/− och taluppdelning, lite textuppgifter.

## Milstolpar (rekommenderad ordning)
### M1 — Åk 1–3: förbättra nuvarande räknefrågor (ingen ny UI)
- Implementera Åk-styrt talområde och enkla constraints.
- Exempel:
  - Åk 1: mer 0–10, 0–20, tiokompisar, 10−x.
  - Åk 2: 0–100, undvik tiotalsövergång tidigt, introducera gradvis.
  - Åk 3: 0–1000 för +/−, tabeller som fokus.
- Kursplan-koppling (Skolverket): primärt *Taluppfattning och tals användning* + delar av *Algebra* (likhet/mönster) + *Problemlösning* i Åk 1–3. (Geometri/statistik kan komma senare som egna moduler i M4.)
- Acceptance:
  - 95% av frågor i Åk 1 ligger inom 0–20 för +/− (tidiga steps).
  - Tiokompisar dyker upp "ofta nog" men inte alltid.
  - Växling (carry/borrow) förekommer sällan i tidiga Åk 2-steps.
- Checklista:
  - Åk→talområde per räknesätt (min/max) + interpolation mot step.
  - Åk→constraints per räknesätt (t.ex. “undvik växling”).
  - Tester: range-test per Åk + constraint-test.

### M2 — Textuppgifter v1 (Åk 1–3)
- Lägg till en minimal textuppgifts-generator som använder samma motor.
- Begränsa:
  - ett steg, ett räknesätt, kort text, låg kognitiv last.
- Acceptance:
  - Textuppgifter fungerar i quizflödet utan ny skärm.
- Checklista:
  - En textmall per räknesätt (+/−/×/÷) och Åk 1–3.
  - Inga nya UI-widgets; text renderas i samma fråga som idag.
  - Tester: deterministisk textgenerering (seed) + snapshot-liknande asserts.

### M3 — Åk 4–6: större tal och fler strategier
- Utöka talområde + constraints:
  - större spann (+/− upp till 10 000 / 100 000), mer växling.
  - ×/÷: tvåsiffrigt gånger ensiffrigt, division med rest (om vi vill).
- Obs: division med rest kräver beslut om svar-format (heltal + rest).
- Kursplan-koppling (Skolverket): centralt innehåll Åk 4–6 inkluderar bl.a. bråk/decimal/procent, koordinatsystem/grafer, statistik (medelvärde/median/typvärde) och programmering i visuella miljöer. Vi tar detta stegvis och håller oss till quiz-format där det går.
- Acceptance:
  - Talområde skalar upp utan att skapa “hopp” (step 1–10 känns jämn).
  - Division med rest är antingen avstängt eller har tydligt svar-format.
- Checklista:
  - Uppdatera range-layer för Åk 4–6 per räknesätt.
  - Inför/öka växling gradvis via constraints.
  - Tester: gränsvärden + rest-division (om påslaget).

### M4 — Pengar/Tid/Geometri/Mönster (separata moduler)
- Implementera en modul i taget.
- Varje modul behöver:
  - datamodell,
  - generator,
  - rendering i UI (t.ex. klocka, mynt),
  - test.
- Acceptance:
  - Varje modul kan slås av/på (feature flag / enkel konfig) och har fallback.

### M5 — Åk 7–9: algebra, negativa tal, funktioner (stegvis)
- Dela upp i två spår så vi kan leverera utan stor ombyggnad:
  - **M5a (utan ny UI):** uppgifter som kan visas som “vanlig text + svar” i nuvarande quiz.
    - Negativa tal: +/−/×/÷ med heltal.
    - Prioriteringsregler: enkla uttryck med parenteser.
    - Procent: “x % av y”, procentuell förändring (ökning/minskning), förändringsfaktor.
    - Potenser: kvadrattal/kubiktal och enkla potensuttryck.
    - Bråk/decimal/procent: konverteringar och jämförelser (i begränsad form).
  - **M5b (kräver ny UI/representation):** uppgifter där text inte räcker.
    - Funktioner & grafer (koordinatsystem, lutning, skärning).
    - Geometri med figur (t.ex. Pythagoras i ritad triangel, cirkel-omkrets/area med bildstöd).
    - Statistik/sannolikhet med diagram/utfallsrum som behöver visualisering.
- Acceptance:
  - M5a: kan köras i quizflödet utan ny skärm.
  - M5b: varje modul har egen minimal rendering + enhetstester.

> Notis: I Skolverkets centrala innehåll Åk 7–9 finns även programmering (visuell och textbaserad) samt mer fokus på funktioner, förändringstakt och modeller. Det matchar väl med att vi delar M5 i “text funkar” (M5a) och “kräver visualisering” (M5b).

## Mätetal (enkla och lokala)
- **Range compliance:** andel frågor inom förväntat talområde per Åk/operation/step.
- **Constraint compliance:** andel frågor som följer “undvik växling/rest/…” när regeln gäller.
- **Svårighetsjämnhet:** step 1→10 ska ge jämn ökning (inga stora hopp).

## Utrullning & fallback
- Feature-flagga per del (minst per lager):
  - Range-layer på/av.
  - Structure-layer på/av.
  - Frågetyp textuppgift på/av.
- Om något blir konstigt i produktion: slå av den delen och falla tillbaka till nuvarande generator.

## Var i koden? (orientering)
- Range-layer & Åk→talområde: `DifficultyConfig` (t.ex. i `difficulty_config.dart`).
- Constraints & frågekomposition: generatorn (t.ex. `question_generator_service.dart`).
- Åk i flödet: sessionmodell + start av quiz (t.ex. `quiz_session.dart` + quiz-provider).
- Persistens: användarprogress/history där vi redan sparar quiz-resultat (t.ex. user/provider + storage).

## Test & kvalitet
- Enhetstester:
  - tal inom intervall per Åk,
  - constraints hålls (t.ex. undvik växling i tidiga Åk 2).
- Fördelningstester:
  - tiokompisar förekommer med rimlig frekvens.
- Widgettest:
  - quiz kan spelas klart deterministiskt.

## Öppna beslut (bra att spika tidigt)
- Division med rest: svar-format och hur vi räknar “rätt”.
- Bråk: hur barn ska svara (t.ex. "1/2" vs valknappar).
- Procent/förändringsfaktor: format på svar (t.ex. "25%" vs "0,25").

## Risker / beslut som behövs
- "Åk" varierar mellan skolor → vi bör vara konservativa och ha föräldra-override.
- Nya frågetyper (tid/pengar/geometri) kräver mer UI.
- Åk 7–9 kan ligga utanför primär målålder (6–12) → prioriteras efter effekt.

---

## Referens (inskickad text)

I årskurs 1 handlar matematiken om att bygga en trygg grund: taluppfattning, enkla beräkningar och att förstå hur matematik syns i vardagen. Det viktigaste är förståelse, inte hastighet.

🧮 Centrala områden i matematik åk 1
🔢 Taluppfattning och talens betydelse
Eleverna ska kunna:

Känna igen och skriva tal 0–20 (många arbetar även upp till 100).

Förstå antal, ordningstal (1:a, 2:a, 3:e).

Jämföra tal: större än, mindre än, lika med.

Dela upp tal (t.ex. 7 = 5 + 2, 7 = 3 + 4).

➕➖ Grundläggande addition och subtraktion
Fokus ligger på:

Addition och subtraktion inom 0–10, senare upp till 20.

Att använda strategier som:

räkna vidare (5 + 3 → 6, 7, 8)

räkna bakåt

tiokompisar (7 + 3, 6 + 4 osv.)

Förstå skillnaden mellan plus och minus i vardagssituationer.

🔍 Problemlösning i vardagen
Eleverna tränar på att:

Tolka enkla textuppgifter.

Använda bilder, konkret material och egna strategier.

Förklara hur de tänker.

🧱 Geometri och mönster
De ska kunna:

Känna igen och namnge enkla geometriska former: cirkel, kvadrat, rektangel, triangel.

Upptäcka och skapa mönster.

Jämföra längd, storlek och form.

📏 Mätning och tid
Grunderna omfattar:

Jämföra längd (längre/kortare), vikt (tyngre/lättare), volym (mer/mindre).

Känna igen klockan: hel och halv timme (ibland först i åk 2, men introduceras ofta i åk 1).

Förstå begrepp som före/efter, igår/idag/imorgon.

💰 Pengar
Många skolor introducerar:

Svenska mynt och sedlar.

Enkla betalningssituationer.

📘 Vad som brukar vara extra viktigt att kunna i slutet av åk 1
Säkert räkna addition och subtraktion inom 0–10.

Förstå talens uppbyggnad och kunna dela upp dem.

Lösa enkla problem och kunna visa hur man tänkt.

Känna igen geometriska former och enkla mönster.

Vill du att jag gör en checklista, övningar, eller en sammanfattning anpassad för ett barn?

Årskurs 2 ?
I årskurs 2 bygger man vidare på grunden från åk 1, men nu med större tal, fler strategier och mer problemlösning. Fokus ligger på att bli säkrare, mer flexibel och att förstå hur matematik hänger ihop.

🔢 Taluppfattning i åk 2
Eleverna arbetar med:

Tal 0–100 (många skolor går även upp mot 200).

Positionssystemet: ental och tiotal.

Att ordna tal på tallinjen och hoppa i steg (2, 5, 10).

Jämföra tal: större än, mindre än, lika med.

Dela upp tal på flera sätt, t.ex. 34 = 30 + 4 eller 20 + 14.

➕➖ Addition och subtraktion
Här fördjupas räknesätten:

Addition och subtraktion inom 0–100.

Strategier som:

tiotalsövergång (t.ex. 48 + 7 → 48 + 2 + 5)

kompensation (t.ex. 39 + 12 → 40 + 11)

uppställning introduceras ibland, men inte alltid.

Förstå sambandet mellan addition och subtraktion.

✖️➗ Introduktion till multiplikation och division
I slutet av åk 2 börjar många skolor med:

Multiplikation som upprepad addition.

Division som delning och gruppering.

Små tabeller, ofta 2:ans, 5:ans och 10:ans.

🔍 Problemlösning och resonemang
Eleverna tränar på att:

Lösa textuppgifter med flera steg.

Välja och förklara strategier.

Använda bilder, tabeller och egna modeller.

🔷 Geometri
Vanliga moment:

Känna igen och beskriva former: kvadrat, rektangel, triangel, cirkel.

Symmetri.

Mäta längd med linjal (cm, m).

Jämföra och uppskatta längd, vikt och volym.

🕒 Tid och pengar
Eleverna ska kunna:

Klockan: hel, halv, kvart i, kvart över.

Dagar, veckor, månader.

Mynt och sedlar, enkla köp- och växelsituationer.

📘 Vad som brukar vara viktigt i slutet av åk 2
Säkert räkna addition och subtraktion inom 0–100.

Förstå tiotalsövergångar.

Kunna läsa klockan (hel, halv, kvart).

Ha grundläggande förståelse för multiplikation och division.

Kunna lösa och förklara enkla textuppgifter.

Vill du att jag gör en checklista, övningsuppgifter, eller en jämförelse mellan åk 1 och åk 2?

Årskurs 3 ?
I årskurs 3 fördjupas allt som eleverna lärt sig i åk 1–2, men nu med större tal, fler strategier och tydligare krav på att kunna resonera, förklara och visa hur man tänker. Det är också året då multiplikation och division blir centrala delar av matematiken.

🔢 Taluppfattning och talområde
Eleverna arbetar nu med tal upp till 1000, och ska kunna:

Förstå positionssystemet: ental, tiotal, hundratal.

Jämföra och ordna tal på tallinjen.

Uppskatta resultat och rimlighet.

Dela upp tal på flera sätt, t.ex. 347 = 300 + 40 + 7.

Det här är grunden för att kunna räkna mer flexibelt och förstå hur större tal fungerar.

➕➖ Addition och subtraktion
Räkning inom 0–1000 är centralt. Eleverna ska kunna:

Räkna med tiotals- och hundratalsövergångar.

Använda olika strategier, t.ex. kompensation, uppdelning och tallinjen.

Förstå och använda uppställning (vanligt i åk 3, men skolor varierar).

Kontrollera sina svar genom att tänka baklänges eller uppskatta.

Det viktiga är inte bara att få rätt svar, utan att kunna förklara hur man tänkt.

✖️➗ Multiplikation och division
Det här är ofta det största steget i åk 3. Eleverna ska:

Förstå multiplikation som upprepad addition.

Förstå division som delning och gruppering.

Kunna multiplikationstabellerna 2, 3, 4, 5, 6, 7, 8, 9 och 10 (ofta tränas de flesta tabellerna under året).

Se sambandet mellan multiplikation och division.

Använda tabellerna i problemlösning.

Multiplikationstabellerna är en av de viktigaste kunskaperna inför mellanstadiet.

🔍 Problemlösning och resonemang
I åk 3 ska eleverna kunna:

Lösa textuppgifter med flera steg.

Välja en strategi och motivera den.

Visa lösningar med bilder, tabeller, räknesätt eller text.

Bedöma om ett svar är rimligt.

Det här är en stor del av bedömningen i slutet av lågstadiet.

🔷 Geometri
Eleverna arbetar med:

Rätblock, kub, cylinder, klot.

Rät vinkel och andra vinklar.

Symmetri och spegling.

Mäta längd i cm, dm och m.

Enkla geometriska konstruktioner.

🕒 Tid, pengar och mätning
Åk 3 innebär att eleverna ska kunna:

Klockan: hel, halv, kvart, minuter, digital tid.

Räkna med tid (t.ex. hur lång tid något tar).

Mynt och sedlar, växla pengar.

Mäta vikt (g, kg) och volym (dl, l).

Jämföra och uppskatta mått.

📘 Viktigt att kunna i slutet av åk 3
Säkert räkna addition och subtraktion inom 0–1000.

Kunna multiplikationstabellerna (åtminstone de vanligaste).

Förstå och använda division.

Läsa och använda klockan, även minuter.

Lösa textuppgifter och förklara sina tankar.

Förstå geometriska former och kunna mäta längd, vikt och volym.

Vill du att jag gör en checklista, övningsuppgifter, eller en sammanfattning anpassad för ett barn i åk 3?

årskurs 4
I årskurs 4 tar matematiken ett tydligt steg in i mellanstadiet. Eleverna ska nu arbeta mer systematiskt, använda flera strategier och börja förstå matematik på en mer abstrakt nivå. Talområdet växer, multiplikation och division fördjupas och problemlösning blir mer avancerad.

🔢 Taluppfattning upp till 10 000
Eleverna ska kunna:

Förstå positionssystemet med ental, tiotal, hundratal och tusental.

Jämföra och ordna tal upp till 10 000.

Placera tal på tallinjen och uppskatta rimliga värden.

Förstå och använda avrundning till närmaste tiotal, hundratal och tusental.

Det här är grunden för att kunna räkna effektivt med större tal.

➕➖ Addition och subtraktion med större tal
Räkning sker nu inom 0–10 000, ofta med uppställning. Eleverna ska:

Behärska uppställning med växling.

Använda strategier som kompensation, uppdelning och tallinjen.

Kontrollera rimlighet genom överslagsräkning.

Förstå hur addition och subtraktion hänger ihop.

✖️➗ Multiplikation och division på mellanstadienivå
Multiplikationstabellerna ska nu sitta, och eleverna arbetar med:

Multiplikation med större tal, t.ex. 
23
⋅
4
.

Division med rest, t.ex. 
25
÷
4
=
6
 rest 
1
.

Sambandet mellan multiplikation och division.

Strategier som upprepad addition, tabellkunskap och uppdelning av tal.

En första introduktion till skriftliga metoder för multiplikation och division (varierar mellan skolor).

🔍 Problemlösning och resonemang
Eleverna ska kunna:

Lösa textuppgifter med flera steg.

Välja och motivera strategier.

Visa lösningar med tabeller, modeller, räknesätt eller text.

Bedöma rimlighet och förklara sitt tänkande.

Det här är en viktig del av bedömningen i mellanstadiet.

📏 Geometri och mätning
Geometrin blir mer avancerad:

Rät vinkel, spetsig vinkel, trubbig vinkel.

Parallella och vinkelräta linjer.

Rektangelns och kvadratens omkrets och area.

Mäta och rita vinklar med gradskiva.

Förstå begrepp som radie och diameter.

Mätning omfattar:

Längd: mm, cm, dm, m, km.

Vikt: g, hg, kg.

Volym: ml, dl, l.

🕒 Tid och tabeller/diagram
Eleverna ska kunna:

Räkna med tid: minuter, timmar, tidsintervall.

Tolka och skapa tabeller, stapeldiagram och linjediagram.

Förstå medelvärde på en grundläggande nivå (varierar mellan skolor).

💰 Pengar och vardagsmatematik
Fortsatt arbete med:

Priser, växel, jämföra kostnader.

Enkla procentuella resonemang kan förekomma (t.ex. "hälften", "en fjärdedel").

📘 Viktigt att kunna i slutet av åk 4
Säkert räkna addition och subtraktion upp till 10 000.

Kunna multiplikationstabellerna och använda dem flexibelt.

Förstå division med rest.

Lösa textuppgifter med flera steg och förklara sina strategier.

Mäta och rita vinklar, samt beräkna omkrets och area av enkla figurer.

Tolka och skapa diagram och tabeller.

Vill du att jag fortsätter med årskurs 5, eller vill du ha övningar som passar åk 4?

årskurs 5
I årskurs 5 breddas matematiken tydligt: eleverna arbetar med större tal, mer avancerade beräkningar, bråk och decimaltal, samt mer systematisk problemlösning. Det är ett år där många nya områden introduceras, samtidigt som tidigare kunskaper ska sitta stabilt.

🔢 Taluppfattning upp till 100 000
Eleverna ska kunna:

Förstå positionssystemet med ental → tiotal → hundratal → tusental → tiotusental.

Jämföra och ordna tal upp till 100 000.

Använda avrundning till närmaste tiotal, hundratal, tusental och tiotusental.

Uppskatta rimliga svar i beräkningar.

Det här är grunden för att kunna hantera större beräkningar och mer komplex problemlösning.

➕➖ Addition och subtraktion med stora tal
Beräkningar sker nu ofta med uppställning. Eleverna ska:

Behärska uppställning med växling i flera steg.

Använda strategier som kompensation och uppdelning av tal.

Kontrollera rimlighet med överslagsräkning.

Förstå hur addition och subtraktion hänger ihop i större talområden.

✖️➗ Multiplikation och division på mellanstadienivå
Multiplikation och division blir mer avancerade:

Multiplikation med två- och tresiffriga tal, t.ex. 
34
⋅
12
.

Division med större tal, både med och utan rest.

Skriftliga metoder för multiplikation och division (t.ex. lång division).

Förstå samband mellan räknesätten och kunna välja effektiv metod.

Det här är centralt inför årskurs 6 och högstadiet.

🍰 Bråk och decimaltal
Ett av de viktigaste nya områdena i åk 5:

Förstå bråk som delar av helhet och antal.

Jämföra och ordna bråk.

Växla mellan bråk och decimaltal.

Förstå tiondelar och hundradelar.

Enkla beräkningar med decimaltal, t.ex. 
3
,
4
+
1
,
2
.

Bråk och decimaltal är en av de största utmaningarna för många elever.

📏 Geometri och mätning
Geometrin blir mer systematisk:

Beräkna omkrets och area av rektanglar och sammansatta figurer.

Förstå begrepp som parallella linjer, vinkelräta linjer och olika typer av vinklar.

Mäta och rita vinklar med gradskiva.

Arbeta med skala och proportioner.

Mätning omfattar:

Längd: mm, cm, dm, m, km.

Vikt: g, hg, kg.

Volym: ml, dl, l.

📊 Tabeller, diagram och statistik
Eleverna ska kunna:

Tolka och skapa tabeller, stapeldiagram, cirkeldiagram och linjediagram.

Förstå begrepp som frekvens, typvärde och median (varierar mellan skolor).

Använda diagram för att lösa problem.

🔍 Problemlösning och resonemang
I åk 5 förväntas eleverna:

Lösa problem med flera steg och flera räknesätt.

Välja strategier och motivera sina val.

Visa lösningar tydligt med text, bilder, tabeller eller beräkningar.

Bedöma rimlighet och kunna förklara sitt tänkande.

Det här är en viktig del av bedömningen inför åk 6.

📘 Viktigt att kunna i slutet av åk 5
Säkert räkna med addition, subtraktion, multiplikation och division i stora talområden.

Förstå och använda bråk och decimaltal.

Beräkna area och omkrets av olika figurer.

Mäta och rita vinklar.

Tolka och skapa olika typer av diagram.

Lösa textuppgifter med flera steg och förklara sina strategier.

Vill du att jag fortsätter med årskurs 6, eller vill du ha övningar som passar åk 5?

Årskurs 6
I årskurs 6 avslutar eleverna låg- och mellanstadiets matematik och ska vara redo för högstadiets mer abstrakta och formella arbetssätt. Det innebär att både taluppfattning, bråk, decimaltal, procent, geometri och problemlösning fördjupas och breddas. Kraven är tydligare och eleverna ska kunna visa sina resonemang mer systematiskt.

🔢 Taluppfattning upp till 1 000 000
Eleverna ska kunna:

Förstå positionssystemet upp till miljoner.

Jämföra, ordna och placera tal på tallinjen.

Använda avrundning till olika nivåer (tiotal → hundratal → tusental → tiotusental → hundratusental).

Uppskatta rimliga resultat i beräkningar.

Förstå negativa tal i enkla sammanhang (t.ex. temperatur).

Det här är grunden för att kunna hantera högstadiets algebra och mer avancerade beräkningar.

➕➖ Addition och subtraktion med stora tal
Eleverna ska:

Behärska uppställning med växling i flera steg.

Arbeta säkert med tal upp till 1 000 000.

Använda överslagsräkning för att kontrollera rimlighet.

Välja effektiva strategier beroende på situation.

✖️➗ Multiplikation och division på avancerad mellanstadienivå
I åk 6 ska eleverna klara:

Multiplikation med två- och tresiffriga tal, t.ex. 
347
⋅
26
.

Division med större tal, både med och utan rest.

Skriftliga metoder som lång division.

Förstå och använda faktorisering och multiplikationens uppdelning, t.ex. 
48
⋅
25
=
(
50
−
2
)
⋅
25
.

Det här är centralt inför högstadiets algebra och ekvationslösning.

🍰 Bråk, decimaltal och procent
Det här är ett av de viktigaste områdena i åk 6.

Bråk
Eleverna ska kunna:

Jämföra och ordna bråk.

Förkorta och förlänga bråk.

Räkna med bråk i enkla situationer.

Växla mellan bråk, decimaltal och procent.

Decimaltal
Eleverna ska:

Förstå tiondelar, hundradelar och tusendelar.

Räkna med decimaltal i addition, subtraktion, multiplikation och division.

Procent
Eleverna ska:

Förstå procent som “hundradelar”.

Växla mellan procent, bråk och decimaltal.

Lösa enkla procentuppgifter, t.ex. 25 % av 200.

📏 Geometri och mätning
Geometrin blir mer formell och förbereder för högstadiets geometri.

Eleverna ska kunna:

Beräkna area och omkrets av rektanglar, trianglar och sammansatta figurer.

Förstå och använda begrepp som parallella linjer, vinkelräta linjer, radie, diameter.

Mäta och rita vinklar med gradskiva.

Räkna med skala, t.ex. 1:100.

Förstå volym i kubikcentimeter (cm³) och kubikmeter (m³).

📊 Statistik och sannolikhet
Eleverna ska kunna:

Tolka och skapa tabeller, stapeldiagram, cirkeldiagram och linjediagram.

Förstå typvärde, median och medelvärde.

Arbeta med enkel sannolikhet, t.ex. sannolikheten att få en 6:a på en tärning.

🔍 Problemlösning och resonemang
I åk 6 är det viktigt att eleverna:

Löser problem med flera steg och flera räknesätt.

Motiverar sina strategier och förklarar sina lösningar.

Använder matematiska begrepp korrekt.

Bedömer rimlighet och kan resonera kring sina svar.

Det här är en stor del av nationella proven i matematik.

📘 Viktigt att kunna i slutet av åk 6
Säkert räkna med alla fyra räknesätt i stora talområden.

Förstå och använda bråk, decimaltal och procent.

Beräkna area, omkrets och volym.

Arbeta med skala och vinklar.

Tolka och skapa diagram och förstå statistiska begrepp.

Lösa och förklara textuppgifter med flera steg.

Vill du att jag fortsätter med årskurs 7, eller vill du ha övningar som passar åk 6?

Årskurs 7
I årskurs 7 går matematiken in i en ny fas: eleverna börjar arbeta mer algebraiskt, mer abstrakt och med större krav på att kunna resonera, visa metoder och förstå samband. Det är också året då många områden från mellanstadiet fördjupas och kopplas ihop.

🔢 Taluppfattning och tal i bråk- och decimalform
Eleverna ska kunna:

Arbeta säkert med negativa tal i addition, subtraktion, multiplikation och division.

Förstå och använda prioriteringsregler (parenteser → multiplikation/division → addition/subtraktion).

Växla mellan bråk, decimaltal och procent.

Jämföra och ordna bråk med olika nämnare.

Förstå och använda proportioner och förhållanden.

Det här är grunden för algebra och ekvationer.

✖️➗ Multiplikation och division på högre nivå
Eleverna arbetar med:

Multiplikation och division av decimaltal.

Beräkningar med stora tal och negativa tal.

Effektiva metoder för skriftliga beräkningar.

Problemlösning där flera räknesätt kombineras.

🧮 Algebra och ekvationer
Det här är ett av de största nya områdena i åk 7.

Eleverna ska kunna:

Förstå vad en variabel är.

Tolka och skriva algebraiska uttryck, t.ex. 
3
𝑥
+
2
.

Förenkla uttryck genom att slå ihop termer.

Lösa enklare ekvationer, t.ex.

3
𝑥
+
5
=
20
Förstå samband mellan uttryck, formler och mönster.

Algebra är en av de viktigaste byggstenarna inför åk 8–9.

📏 Geometri och mätning
Geometrin blir mer formell och analytisk:

Beräkna area och omkrets av trianglar, parallellogram och sammansatta figurer.

Förstå och använda Pythagoras sats i enkla fall (ibland introduceras i åk 7, ibland i åk 8).

Arbeta med skala, likformighet och proportioner.

Förstå begrepp som vinkelbisektris, höjd, diagonal.

Räkna med volym av rätblock och andra enkla kroppar.

📊 Statistik och sannolikhet
Eleverna ska kunna:

Tolka och skapa tabeller, stapeldiagram, cirkeldiagram och linjediagram.

Förstå typvärde, median, medelvärde och spridning.

Arbeta med enkel sannolikhet, t.ex. sannolikheten att dra en viss kula ur en påse.

Resonera kring slump och risk.

🔍 Problemlösning och resonemang
I åk 7 förväntas eleverna:

Lösa problem med flera steg och flera metoder.

Motivera sina val av strategier.

Använda matematiska begrepp korrekt.

Visa lösningar tydligt med algebra, tabeller, diagram eller text.

Bedöma rimlighet och kunna förklara varför ett svar är rimligt.

Det här är centralt inför nationella proven i åk 9.

📘 Viktigt att kunna i slutet av åk 7
Arbeta säkert med negativa tal och prioriteringsregler.

Förstå och använda bråk, procent och decimaltal i beräkningar.

Lösa enkla ekvationer och förenkla algebraiska uttryck.

Beräkna area, omkrets och volym av flera typer av figurer.

Tolka och skapa diagram samt förstå statistiska mått.

Resonera tydligt och visa matematiska metoder.

Vill du att jag fortsätter med årskurs 8, eller vill du ha övningar som passar åk 7?

Årskurs 8
Årskurs 8 bygger vidare på allt från åk 7 men går tydligt djupare: algebra blir mer avancerad, geometri mer formell och problemlösning mer krävande. Eleverna ska nu kunna arbeta mer abstrakt, mer metodiskt och med större precision.

🔢 Taluppfattning och aritmetik på högstadienivå
Eleverna arbetar med ett bredare talområde och mer komplexa beräkningar:

Negativa tal i alla fyra räknesätt, även i uttryck med flera steg.

Prioriteringsregler i mer avancerade uttryck, t.ex. 
3
−
2
(
4
−
7
)
2
.

Proportioner, förhållanden och skala i mer komplexa situationer.

Förstå och använda potenser med positiva heltalsexponenter.

Grundläggande arbete med kvadratrötter.

Det här är centralt för att kunna hantera ekvationer och funktioner i åk 9.

🧮 Algebra och ekvationer
Algebra är ett av de största fokusområdena i åk 8:

Förenkla algebraiska uttryck, t.ex. 
5
𝑥
−
3
+
2
𝑥
+
7
.

Multiplicera in i parenteser, t.ex. 
3
(
𝑥
−
4
)
.

Faktorisera enkla uttryck, t.ex. 
4
𝑥
+
8
=
4
(
𝑥
+
2
)
.

Lösa ekvationer med flera steg, t.ex.

4
(
𝑥
−
2
)
+
3
=
19
Förstå och använda formler i olika sammanhang.

Introduktion till funktioner: samband mellan variabler, tabeller och grafer.

Det här är grunden för linjära funktioner i åk 9.

📉 Funktioner och grafer
I åk 8 börjar eleverna arbeta mer systematiskt med funktioner:

Tolka och skapa tabeller och grafer.

Förstå begrepp som variabel, värde, koordinatsystem.

Arbeta med enkla linjära samband, t.ex. “pris = 20x”.

Tolka lutning och förändringstakt i vardagliga situationer.

Det här är en viktig bro till linjära funktioner och ekvationssystem i åk 9.

📏 Geometri och mätning på fördjupad nivå
Geometrin blir mer teoretisk och mer beräkningsintensiv:

Pythagoras sats används regelbundet i problemlösning.

Beräkna area och omkrets av trianglar, parallellogram, cirklar och sammansatta figurer.

Volym av rätblock, prismor och cylindrar.

Arbeta med skala, likformighet och proportioner.

Förstå och använda begrepp som höjd, diagonal, radie, diameter, omkretsformler.

Geometri i åk 8 förbereder för trigonometri i åk 9.

🍰 Bråk, procent och decimaltal
Eleverna ska kunna:

Räkna med bråk i mer avancerade situationer.

Förstå och använda procent i flera steg, t.ex. procentuella förändringar.

Växla mellan bråk, procent och decimaltal.

Arbeta med ränta, förändringsfaktor och procentuella jämförelser.

Det här är centralt för ekonomi och statistik i åk 9.

📊 Statistik och sannolikhet
Statistiken blir mer analytisk:

Tolka och skapa tabeller, diagram och grafer.

Förstå och använda typvärde, median, medelvärde och spridning.

Arbeta med sannolikhet i flera steg, t.ex. två tärningskast.

Resonera kring slump, risk och sannolikhetsmodeller.

🔍 Problemlösning och resonemang
I åk 8 förväntas eleverna:

Lösa problem med flera steg och flera metoder.

Använda algebra som verktyg i problemlösning.

Motivera sina strategier och förklara sina lösningar tydligt.

Bedöma rimlighet och kunna resonera kring olika lösningsvägar.

Det här är en viktig del av förberedelsen inför nationella proven i åk 9.

📘 Viktigt att kunna i slutet av åk 8
Hantera negativa tal, potenser och prioriteringsregler säkert.

Förenkla uttryck och lösa ekvationer med flera steg.

Förstå funktioner och kunna läsa och skapa grafer.

Använda Pythagoras sats och beräkna area/volym i mer avancerade figurer.

Arbeta med procentuella förändringar och bråk i flera steg.

Resonera tydligt och visa matematiska metoder.

Vill du att jag fortsätter med årskurs 9, eller vill du hellre ha övningar som passar åk 8?

Årskurs 9
Årskurs 9 är slutåret i grundskolan och matematikens mål är att eleverna ska vara redo för gymnasiets mer abstrakta och teoretiska matematik. Det innebär att alla områden från åk 7–8 fördjupas, och att eleverna ska kunna arbeta mer självständigt, metodiskt och med tydliga resonemang. Nationella proven i matematik bygger också på dessa kunskaper.

🔢 Taluppfattning och aritmetik på hög nivå
Eleverna ska kunna arbeta säkert med:

Negativa tal i alla räknesätt och i uttryck med flera steg.

Potenser, inklusive kvadrattal, kubiktal och potenser med negativa exponenter i enklare sammanhang.

Kvadratrötter och sambandet mellan kvadrattal och rötter.

Prioriteringsregler i komplexa uttryck.

Proportioner, förhållanden och förändringsfaktorer.

Det här är grunden för algebra, funktioner och problemlösning.

🧮 Algebra och ekvationslösning
Algebra är ett av de mest centrala områdena i åk 9. Eleverna ska kunna:

Förenkla uttryck med flera termer och parenteser.

Multiplicera in i parenteser och faktorisera uttryck, t.ex. 
6
𝑥
+
12
=
6
(
𝑥
+
2
)
.

Lösa ekvationer med flera steg, t.ex.

5
(
2
𝑥
−
3
)
−
4
=
3
𝑥
+
11
Lösa ekvationssystem, både grafiskt och algebraiskt.

Använda formler och omforma dem, t.ex. lösa ut en variabel.

Det här är direkt förberedelse för gymnasiets matematik 1c/1b/1a.

📉 Funktioner och grafer
Funktioner är ett stort fokusområde i åk 9. Eleverna ska kunna:

Förstå begreppen funktion, variabel, värde, koordinatsystem.

Tolka och rita grafer.

Arbeta med linjära funktioner, t.ex.

𝑦
=
𝑘
𝑥
+
𝑚
Förstå lutning (k) och m-värde och vad de betyder i verkliga situationer.

Tolka grafer i vardagliga sammanhang, t.ex. hastighet, pris, temperatur.

Det här är en av de viktigaste delarna av nationella provet.

📏 Geometri och Pythagoras sats
Geometrin i åk 9 är mer teoretisk och problemlösningsinriktad. Eleverna ska kunna:

Använda Pythagoras sats i olika typer av problem.

Beräkna area och omkrets av cirklar, trianglar, parallellogram och sammansatta figurer.

Beräkna volym av rätblock, prismor, cylindrar och andra kroppar.

Arbeta med skala, likformighet och proportionalitet.

Förstå och använda begrepp som höjd, diagonal, radie, diameter, tangent.

Geometriuppgifter i åk 9 kräver ofta flera steg och tydliga resonemang.

🍰 Bråk, procent och förändringar
Eleverna ska kunna:

Räkna med bråk i mer avancerade situationer.

Växla mellan bråk, procent och decimaltal.

Arbeta med procentuella förändringar, t.ex. ökning/minskning i flera steg.

Använda förändringsfaktor, t.ex. 1,25 eller 0,85.

Förstå ränta och enkel ekonomisk matematik.

Det här är centralt för både nationella provet och vardagsmatematik.

📊 Statistik och sannolikhet
Statistik i åk 9 är mer analytisk och kräver tolkning. Eleverna ska kunna:

Tolka och skapa tabeller, stapeldiagram, cirkeldiagram och linjediagram.

Förstå typvärde, median, medelvärde och spridning.

Arbeta med sannolikhet i flera steg, t.ex. två tärningskast eller kortdragning.

Resonera kring slump, risk och sannolikhetsmodeller.

🔍 Problemlösning och resonemang
I åk 9 ska eleverna:

Lösa problem med flera steg och flera metoder.

Använda algebra som verktyg i problemlösning.

Motivera sina strategier och förklara sina lösningar tydligt.

Bedöma rimlighet och jämföra olika lösningsmetoder.

Använda matematiska begrepp korrekt och tydligt.

Det här är en stor del av bedömningen i slutbetyget.

📘 Viktigt att kunna i slutet av åk 9
Hantera negativa tal, potenser och prioriteringsregler säkert.

Förenkla uttryck och lösa ekvationer och ekvationssystem.

Förstå och arbeta med linjära funktioner och grafer.

Använda Pythagoras sats och beräkna area/volym i avancerade figurer.

Arbeta med procentuella förändringar och bråk i flera steg.

Tolka statistik och sannolikhet och resonera tydligt i problemlösning.