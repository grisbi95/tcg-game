---
name: pr
description: Commite le travail en cours, pousse la branche et ouvre la PR selon le gabarit, puis lit la CI une fois ; fusionne seulement sur demande et CI verte. Usage : /pr
disable-model-invocation: true
---

# Ouvrir une PR

Seul le créateur lance `/pr` : son appel vaut demande de commit et de push. La fusion reste une demande à part.

1. Sur une branche `feat/`, `fix/`, `docs/` ou `chore/`, jamais sur `main` : sinon crée la branche d'abord.
2. `git status` : seuls les fichiers du périmètre sont ajoutés, nommés un par un. Jamais un fichier de travail non suivi (audit, notes), ni `project.godot`, ni `.godot/`, ni `addons/`.
3. Un commit par lot ou par étape, Conventional Commits : `type(portée): sujet`, corps en puces, ligne `Co-Authored-By`. Propose le message si le créateur ne l'a pas vu.
4. `git push -u origin <branche>`, puis `gh pr create --base main` avec un corps selon `.github/PULL_REQUEST_TEMPLATE.md` : Résumé, Vérifications (résultats réels, ce qui n'a pas pu être vérifié), Définition de terminé cochée point par point.
5. Lis la CI une fois (`gh pr checks <n>`) et rapporte ; ne la surveille pas en boucle. Un échec se corrige sur la même branche, puis push.
6. Sur demande explicite et CI verte seulement : `gh pr merge <n> --merge --delete-branch`, puis `git switch main`, `git pull --ff-only`, `git fetch --prune`. Jamais supprimer une branche qui sert de base à une autre PR ouverte : GitHub la fermerait.
