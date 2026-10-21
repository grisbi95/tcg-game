---
name: open-step
description: Ouvre une étape de la roadmap : lit l'état, les décisions et le ruleset concernés, crée la branche, pose le périmètre et la définition de terminé. Usage : /open-step 2.5
---

# Ouvrir une étape

1. Lis « État actuel » et l'étape `N.M` dans `docs/roadmap.md`. Elle doit être la prochaine action, l'étape précédente cochée ; sinon arrête-toi et dis-le.
2. Lis les décisions que l'étape cite et les « décisions à prendre » qu'« État actuel » lui attache ; lis la source de l'étape dans le ruleset : le chapitre de `docs/ruleset/20-regles-completes/` concerné, ou `70-playtest/protocole.md` pour une étape de playtest, et les questions ouvertes qui les touchent dans `02-questions-ouvertes.md`. Une question ouverte bloquante se signale, elle ne se tranche jamais en code.
3. `git status` propre (fichiers de travail non suivis exceptés) ; sinon arrête-toi. Puis `git switch main`, `git pull --ff-only`, et branche `feat/N.M-<sujet>` (ou `docs/`, `chore/` selon le contenu).
4. Pose en cinq lignes au plus : périmètre (fichiers, modules, identifiants de règles), hors périmètre, « terminé = » (tests nommés par identifiant, suites, vue vérifiée à l'écran), agents à lancer (`/implement`, `/cards`, `ui-builder`, ou la conversation pour `app/`). Attends l'accord du créateur avant d'éditer.
5. Après l'accord, si l'étape exige un système nouveau : `/decision` avant tout code, sur la branche de l'étape.
