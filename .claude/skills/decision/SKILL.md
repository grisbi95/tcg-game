---
name: decision
description: Présente 2 ou 3 options pour un système nouveau, attend le choix, puis fait consigner la décision par adr-writer ; couvre aussi la correction de cap quand une décision en remplace une autre. Usage : /decision <titre court>
---

# Prendre une décision d'architecture

1. Problème concret en trois lignes, contraintes (ruleset, Web, déterminisme, décisions existantes).
2. Deux ou trois options, chacune avec bénéfice, coût et limite ; une recommandation argumentée en une phrase.
3. Attends le choix du créateur. Ne code rien avant.
4. Lance `adr-writer` avec : contexte, options telles que présentées, choix, date du jour, conséquences, condition de réexamen ; demande la mise à jour des renvois de `CLAUDE.md`.

## Correction de cap

Quand la décision en remplace ou en modifie une autre :

- `adr-writer` pose le statut « remplacée par NNNN » ou « modifiée par NNNN » sur l'ancienne, jamais une réécriture.
- Ajuste dans `docs/roadmap.md` le périmètre des étapes touchées et « État actuel » (cinq lignes au plus, décision 0038).
- Signale à `ruleset-editor` les questions ouvertes du ruleset que la décision touche ; aucune règle ne change sans lui.
- Liste le code qui citait l'ancienne décision (`grep -rnw "NNNN" rules app ui tests data docs .claude`) comme travail induit, et les dettes qui en naissent dans `docs/backlog.md`.
