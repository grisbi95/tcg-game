---
name: close-step
description: Clôture une étape de la roadmap : vérifications, relecture, mise à jour de « État actuel », proposition de commit. Usage : /close-step 1.2
---

# Clore une étape

1. Lance `verifier` ; tout doit être vert.
2. Lance `reviewer` sur `git diff` ; traite les bloquants.
3. Coche l'étape dans `docs/roadmap.md` et réécris la ligne **État actuel** (cinq lignes au plus, décision 0038) : ce qui est fait, la prochaine action, les décisions à prendre avec l'étape suivante, la date du jour. Porte les dettes dans `docs/backlog.md`, les questions de règles au ruleset par `ruleset-editor`, les mesures de playtest au protocole.
4. Vérifie la définition de terminé de `CLAUDE.md` §8 point par point et rapporte ce qui n'a pas pu être vérifié.
5. Propose un commit Conventional Commits (`feat(rules): …`) : ne commite que si le créateur le demande.
