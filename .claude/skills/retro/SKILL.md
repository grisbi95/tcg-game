---
name: retro
description: Rétrospective d'un jalon clos, écrite dans docs/retros/<jalon>.md : ce qui a marché, ce qui a coûté, dettes vers le backlog, décisions à réexaminer, une chose à changer. Usage : /retro J2
---

# Rétrospective d'un jalon

Une rétro par jalon, jamais par étape ; elle tient en une page.

1. Condition : toutes les étapes du jalon sont cochées dans `docs/roadmap.md` ; sinon arrête-toi et dis-le.
2. Lis « État actuel », les étapes du jalon et leurs PR fusionnées (`gh pr list --state merged`), `docs/backlog.md`, les décisions prises pendant le jalon (`docs/decisions/`, par date) avec leurs conditions de réexamen, et les règles PROVISOIRE que le jalon a touchées.
3. Écris `docs/retros/<jalon>.md` (dossier créé au premier fichier) : titre, ligne **Rôle**, date ; sections : Ce qui a marché ; Ce qui a coûté (des faits : reprises, bloquants de relecture, étapes rouvertes) ; Dettes (renvoi au backlog, jamais la liste ici) ; Décisions à réexaminer (numéro, condition atteinte ou non) ; Règles PROVISOIRE à mesurer ; Une chose à changer pour le jalon suivant.
4. Porte les dettes dans `docs/backlog.md`, les questions de règles et les mesures du protocole de playtest à `ruleset-editor`. Ne modifie aucune décision : un réexamen passe par `/decision`.
5. Propose les changements de consignes (`CLAUDE.md` seulement si impératif et court, sinon `docs/code-guidelines.md` ou une skill) et attends l'accord du créateur.
