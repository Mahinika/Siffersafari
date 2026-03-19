# Multiplikation CI/PR README

Detta repo kör automatiska tester via GitHub Actions:

- **core smoke** (snabb, happy-path) körs på pull requests.
- **full smoke** (alla scenarier) + **audit** körs på push till main/master.

Se `.github/workflows/ci.yaml` för detaljer.
