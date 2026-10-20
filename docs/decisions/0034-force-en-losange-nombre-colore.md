# 0034 — Force en losange, nombre coloré

- Statut : acceptée
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : Force des cartes et des pièces (`ui/components/` : CardView, PieceView ; `ui/theme/` ; étape 2.3)

## Contexte

Sur les captures de 0033, la goutte (coût) et le cœur (PV) conviennent au créateur ; l'épée de la Force ressemble à une cloche (« pas fan »). Le créateur veut aussi alléger l'affichage d'une Force modifiée. Cette décision modifie 0027 (pastille de Force colorée, Force imprimée barrée à côté) et 0033 (épée pour la Force).

## Options envisagées

- Forme de la Force, un losange plein : retenu « pour le moment », en attendant une icône définitive. Contre : garder l'épée, dont la silhouette reste ambiguë.
- Force modifiée, couleur du nombre seul, sans la valeur imprimée barrée : retenu, à la demande du créateur. Diminuée en orange foncé : recommandé, car le rouge reste réservé au joueur B (0027) et le couple vert-orange se distingue un peu mieux pour les daltoniens. Contre : le rouge, plus immédiat, mais confondu avec le liseré du joueur B et formant le couple rouge-vert, le plus difficile pour les daltoniens, alors que la couleur devient la seule information.

## Décision

Choix du créateur le 2026-10-20. La Force s'affiche sur un losange plein neutre, le même dans tous les cas. Le nombre est foncé (neutre) si la Force actuelle égale la Force imprimée, vert au-dessus, orange foncé en dessous. La Force imprimée barrée n'est plus affichée. La goutte du coût et le cœur des PV de 0033 restent. Le rouge reste réservé au joueur B (0027).

## Conséquences et vérification

- La Force modifiée ne se lit plus que par la couleur du nombre ; la valeur imprimée reste lisible sur la carte complète de l'aperçu.
- Vérification : captures des scènes d'essai de CardView et PieceView ; contraste du nombre (vert et orange foncé) sur le losange d'au moins 4,5:1 visé.
- À réexaminer à l'arrivée d'une icône définitive pour la Force, ou si le playtest J3 montre qu'une Force modifiée passe inaperçue (daltonisme notamment).

## Références

Décisions 0027, 0030, 0033 ; ruleset 202.1.5 à 202.1.8, 209.1 ; roadmap étape 2.3.
