---
name: tests
description: Lance les suites GdUnit4 en headless avec la sortie filtrée aux échecs et au résumé. Usage : /tests ou /tests test_208_stack
---

# Lancer les tests

```bash
tools/run_tests.sh                       # tout
tools/run_tests.sh res://tests/<suite>.gd
```

Lis le `Overall Summary` ; code 0 tout passe, 100 au moins un échec. Les lignes `remote port 127.0.0.1:0` sont normales. Pour une sortie longue, passe par l'agent `verifier` plutôt que de la lire ici. Ne jamais écrire « tests réussis » sans avoir vu le résumé.
