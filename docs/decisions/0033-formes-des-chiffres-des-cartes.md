# 0033 — Formes des chiffres des cartes

- Statut : acceptée ; modifiée par 0034
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : chiffres des cartes et des pièces (`ui/components/` : CardView, PieceView, HoverPreview, carte Hero ; `ui/theme/` ; étape 2.3)

## Contexte

Sur les captures des cartes et des pièces, les trois chiffres (coût, Force, PV) sont dans des pastilles rondes identiques. Le créateur veut reconnaître le type de chiffre d'un coup d'œil : « plus lisible comme cela ». Cette décision modifie 0027, qui prévoyait des pastilles rondes pour le coût et la Force et un cœur à côté des PV.

## Options envisagées

- A, la forme remplace la pastille : une goutte pleine pour le coût en Essence, une épée pleine pour la Force, un cœur plein pour les PV du Hero, le chiffre posé au centre. L'épée garde les couleurs de 0027 (neutre à la Force imprimée, verte au-dessus, orange en dessous, valeur imprimée barrée à côté). Pour : le type de chiffre se reconnaît à sa forme, sans lire. Contre : un chiffre sur une épée fine se lit mal ; l'épée aura une lame large, vérifiée par capture.
- B, garder les pastilles rondes avec une petite icône (goutte, épée, cœur) à côté du chiffre. Pour : fond uni, chiffre très lisible. Contre : la forme se voit moins, l'icône est petite.

## Décision

Option A, choix du créateur le 2026-10-20, partout où une carte ou une pièce montre ces chiffres : main, aperçu, défausse, carte Hero, pièces du plateau. Formes tracées en code par DuelIcons, couleurs dans DuelPalette.

## Conséquences et vérification

- Le coût, la Force et les PV se distinguent par leur forme ; les couleurs de la Force modifiée restent celles de 0027.
- Vérification : captures des scènes d'essai de CardView, PieceView et HoverPreview ; contraste du chiffre sur sa forme.
- À réexaminer si le playtest J3 montre un chiffre mal lu (en particulier sur l'épée), ou à l'arrivée des icônes définitives.

## Références

Ruleset 202.1.5 à 202.1.8 (Force), 202.3.7 (PV), 203 (Essence) ; décisions 0027, 0030, 0032 ; roadmap étape 2.3.
