# 0210 · État endormi ou éveillé public

> Décision consignée le 24 octobre 2026. Statut : ACTÉ. Une décision ne se modifie jamais ; pour revenir dessus, une nouvelle décision la remplace et cette ligne reçoit « Remplacée par NNNN ».

## Contexte

La section 201.4 ne liste aucune information du plateau : elle ne dit pas si l'état endormi ou éveillé d'une Unit ou d'un Hero (205.5.1 et 205.5.2) est visible des deux joueurs. Le créateur a tranché après avoir vu l'affichage choisi pour la version sur écran, où l'illustration d'une pièce endormie passe en gris (décision 0053 du projet, `docs/decisions/0053-fiche-technique-de-l-ecran-de-duel.md`). Question d'origine : Q-104.

## Options envisagées

| Option | Pour | Contre |
| --- | --- | --- |
| A : l'état est visible des deux joueurs | Aucune information du plateau n'est cachée ; moins de charge mentale. | La version du jeu sur écran doit afficher cet état pour chaque pièce. |
| B : l'état n'est visible que du joueur qui contrôle la pièce | Aucun affichage de l'état n'est exigé pour les pièces adverses. | Une information cachée de plus, que l'adversaire ne peut que déduire du déroulé de la partie ; plus de charge mentale. |

## Choix

Option A. L'état endormi ou éveillé de chaque Unit et de chaque Hero est visible des deux joueurs, parce que l'option B ajoutait une information cachée et de la charge mentale.

## Conséquences sur les règles

- Chapitre 201 : identifiant ajouté 201.4.11.
- Aucun terme ajouté ni modifié au glossaire.

## Questions ouvertes créées

- Aucune.
