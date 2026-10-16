# 0064 · Moment de résolution des effets déclenchés

> Décision consignée le 15 octobre 2026. Statut : ACTÉ. Une décision ne se modifie jamais ; pour revenir dessus, une nouvelle décision la remplace et cette ligne reçoit « Remplacée par NNNN ».

## Contexte

La décision 0063 crée les effets déclenchés sans fixer le moment où ils passent par la pile. Par 208.3.1 et 208.3.3 (décision 0046), la pile se résout d'un bloc, sans réponse entre deux résolutions. Question ouverte d'origine : aucune.

## Options envisagées

| Option | Pour | Contre |
| --- | --- | --- |
| A · Modèle de la chaîne de Yu-Gi-Oh!, référence retenue par la décision 0005 : un effet déclenché pendant la résolution d'une pile attend la fin de cette résolution, puis il est placé sur la pile et les joueurs peuvent y répondre ; un effet déclenché en dehors d'une résolution, par exemple à l'annonce d'une attaque, est placé sur la pile aussitôt après l'annonce qui l'a déclenché ; un effet déclenché n'est jamais manqué : il a lieu même si sa source a quitté le plateau entre-temps ; proposition présentée au créateur | La pile se résout d'un bloc (décision 0046), donc un effet né au milieu du bloc ne peut pas s'y insérer. « Jamais manqué » est indispensable aux effets « quand cette Unit est détruite ». | Non débattu. |
| B · Règle du « timing manqué » de Yu-Gi-Oh! : un effet déclenché peut être manqué selon le moment où il se déclenche | Non débattu. | Écartée par la décision 0005, dans [00-vision.md](../00-vision.md) ; rendrait incertains les effets « quand cette Unit est détruite ». |

Aucune autre alternative n'a été débattue.

## Choix

Le créateur a validé l'option A le 15 octobre 2026 et écarté l'option B. Raison principale : un effet né au milieu d'un bloc ne peut pas s'y insérer, et un effet jamais manqué rend sûrs les effets « quand cette Unit est détruite » sans la règle du timing manqué.

## Conséquences sur les règles

- Chapitre 207, section 207.3 Effets déclenchés : 207.3.2 et 207.3.3 créés, au statut ACTÉ.
- Chapitre 208 : 208.4.2, 208.4.3, 208.4.4 et 208.4.5 créés dans la section 208.4 Chaînes, au statut ACTÉ ; sous-règles 208.3.2a et 208.5.1a créées, au statut ACTÉ, pour la cohérence avec 208.3.2 et 208.5.1, dont le texte n'est pas modifié.
- 208.3.2a : 208.3.2 ne fixe l'ordre de résolution que pour les annonces ; un effet déclenché placé sur la pile se résout avec elles, dans le même ordre. 208.3.1 et 208.3.3 relues, cohérentes, non modifiées.
- 208.5.1a : un effet déclenché qui attend la fin d'un bloc passe sur la pile avant que ce soit de nouveau au joueur actif d'agir (208.5.1).
- « Placé sur la pile » est rédigé « s'ajoute au sommet de la pile », sur le modèle de 208.4.1.
- Le cas « en dehors d'une résolution » est rédigé pour un effet déclenché par une annonce (208.4.4), seul cas que la règle tranchée décrit ; « aussitôt après cette annonce » place l'effet sur la pile avant la réponse de 208.2.1. Les autres événements hors résolution sont reportés en Q-030.
- « Sa source » est rédigé « la pièce qui le porte » (207.3.3), le mot Source désignant l'élément qui produit l'Essence ; « entre-temps » n'est pas repris, la règle couvrant aussi un effet déclenché par le départ du plateau de sa pièce.
- Termes modifiés au glossaire : Pile, qui inclut les effets déclenchés en attente de résolution ; Résoudre, qui s'applique aussi à un effet déclenché ; Vide, qui exige aussi qu'aucun effet déclenché n'attende sur la pile. Terme modifié, renvois seulement : Répondre.
- Rien n'est tranché sur l'ordre de plusieurs effets déclenchés en même temps, en discussion, ni sur les boucles, ni sur les cibles.

## Questions ouvertes créées

- [Q-029](../02-questions-ouvertes.md) · Quel joueur peut le premier répondre ou passer après l'ajout d'un effet déclenché selon 208.4.3 ?
- [Q-030](../02-questions-ouvertes.md) · Quand s'ajoute à la pile un effet déclenché par un événement qui n'est ni une annonce ni une résolution ?
- [Q-031](../02-questions-ouvertes.md) · Dans quel ordre s'ajoutent à la pile plusieurs effets déclenchés en même temps ?
- [Q-032](../02-questions-ouvertes.md) · Que se passe-t-il quand des effets déclenchés se déclenchent les uns les autres sans fin ?
- [Q-033](../02-questions-ouvertes.md) · Quand sont choisies les cibles d'un effet déclenché, et que devient-il si elles ne sont plus valides ?
