# Mermaid i repo:t

Målet: diagram ska vara **lätta att uppdatera**, **rendera i VS Code** och **rendera på GitHub**.

## VS Code-workflow

- Öppna valfri `.md` med Mermaid.
- Öppna preview: `Ctrl+Shift+V` (Preview) eller `Ctrl+K V` (Preview to the Side).
- Skriv/ändra diagram direkt i filen – preview uppdateras.

> Tips: Om preview inte renderar Mermaid, kontrollera att extension `bierner.markdown-mermaid` är installerad.

## GitHub-workflow

GitHub renderar Mermaid i Markdown när du använder:

```mermaid
flowchart TD
  A[Docs] --> B[Mermaid]
```

## Konventioner (rekommenderat)

- Lägg arkitekturdiagram i [docs/ARCHITECTURE.md](ARCHITECTURE.md).
- Lägg flödesdiagram nära respektive funktionsdokument (t.ex. `docs/SERVICES_API.md`).
- Namnge diagram på ett sätt som matchar screenshots/test-namn (t.ex. `UI_TEST_1_quiz_flow`).

## Snabbmallar

### Flowchart

```mermaid
flowchart LR
  A --> B --> C
```

### Sequence

```mermaid
sequenceDiagram
  autonumber
  participant UI
  participant Service
  UI->>Service: request
  Service-->>UI: response
```
