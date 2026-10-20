## Résumé

Étape ou lot concerné, décisions appliquées, ce que la PR change en trois à six puces.

## Vérifications

Résultats de `tools/lint.sh`, `tools/check_typing.sh` et `tools/run_tests.sh` (ou « sans objet » si aucun `.gd` ne change) ; pour la vue, scène lancée dans l'éditeur et ce qui a été vu ; ce qui n'a pas pu être vérifié.

## Définition de terminé (`CLAUDE.md` §8)

- [ ] `.gd` modifiés passés par le hook, lint et typage propres.
- [ ] Suites pertinentes vertes ; règle nouvelle ou modifiée testée par identifiant.
- [ ] Vue vérifiée à l'écran, ou moteur couvert par la suite.
- [ ] Diff relu contre `docs/code-guidelines.md` §8 ; rien hors périmètre.
- [ ] `docs/roadmap.md`, `docs/backlog.md` et décisions à jour.
- [ ] Rapport : contrôles exécutés, échecs, vérifications impossibles.
