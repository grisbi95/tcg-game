---
name: decision
description: Présente 2 ou 3 options pour un système nouveau, attend le choix, puis fait consigner la décision par adr-writer. Usage : /decision <titre court>
---

# Prendre une décision d'architecture

1. Problème concret en trois lignes, contraintes (ruleset, Web, déterminisme, décisions existantes).
2. Deux ou trois options, chacune avec bénéfice, coût et limite ; une recommandation argumentée en une phrase.
3. Attends le choix du créateur. Ne code rien avant.
4. Lance `adr-writer` avec : contexte, options telles que présentées, choix, date du jour, conséquences, condition de réexamen ; demande la mise à jour des renvois de `CLAUDE.md`.
