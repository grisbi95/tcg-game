# 0032 — Commandes, pouvoir du Hero et moments particuliers de l'écran

- Statut : acceptée ; complétée par 0036 ; point 3 modifié par 0047 ; modifiée par 0053
- Date : 2026-10-20
- Décideur : créateur du projet
- Périmètre : écran de duel (`ui/`, étape 2.3)

## Contexte

0030 laissait ouverts la place des commandes (« Confirmer » du mulligan, « Annuler », « Pouvoir du Hero »), le compteur Essence, le mulligan, les choix demandés par le moteur, la fatigue, les écrans de relais et de fin. Le créateur les a tranchés un à un. Cette décision complète 0030 ; elle modifie 0028 et 0023 (plus aucun « Annuler » pour le paiement préparé).

## Options envisagées

Retenue d'abord, puis l'autre.

- Commandes : un seul grand bouton qui change selon le moment, sans « Annuler » (une action jouée, pas de retour en arrière) ; ou petits boutons « Annuler » et « Pouvoir du Hero » sous le grand bouton.
- Pouvoir du Hero : une carte Hero à part, cliquable (un seul sens par geste, texte et coût toujours lisibles, place libre à droite) ; ou un clic sur le Hero du plateau pour le déplacement comme pour le pouvoir (gestes mélangés, risque d'action involontaire).
- Compteur Essence : garder le fonctionnement du moteur (203.6, 0026 : réserve publique pendant son tour, paiement préparé au tour adverse) ; ou paiement préparé partout (la réserve du ruleset ne servirait plus, l'Essence produite serait cachée à l'adversaire).
- Mulligan : dans la zone de la main (mêmes gestes) ; ou panneau au centre (un écran de plus, un Écart montré sans raison).
- Choix demandés par le moteur : sur place avec une consigne ; ou panneau au centre (cache le plateau).
- Fatigue : dans le coin du deck, seulement à partir de 1 ; ou pastille permanente sous chaque pendule (inutile presque toute la partie).
- Relais et fin de partie : à l'étape 2.4 comme le prévoit la roadmap ; ou version simple dès 2.3 (grossit l'étape).

## Décision

Choix du créateur, le 2026-10-20, pour chaque option retenue ci-dessus.

1. **Un seul grand bouton** au centre de la colonne de duel, aux couleurs du joueur qui agit : « Terminer le tour » (pile vide), « Passer » (pile non vide), « Confirmer » (mulligan) ; caché pendant un choix demandé par le moteur.
2. **Aucun « Annuler »**, ni pour les Sources ni pour une action : un coup joué est définitif. Recliquer une carte ou une pièce seulement choisie la désélectionne.
3. **Carte Hero** : une par joueur, 158×220, liseré du joueur, à droite de la colonne de duel (A en bas au-dessus de son deck, B en haut sous le sien). Un clic sur sa propre carte lance le pouvoir (202.3.13) : les cibles s'allument, un clic sur la cible l'annonce ; sans cible, il part au clic (0031). Anneau jaune quand le pouvoir est utilisable ; survol = aperçu. Le Hero du plateau ne sert plus qu'au déplacement.
4. **Compteur Essence** dans le bloc de Sources de chaque joueur (en haut pour B quand il a l'appareil) : pendant son tour, la réserve réelle (203.6, 0026), chaque clic définitif ; pendant le tour adverse, le paiement préparé, envoyé avec la Réaction (0003) ou effacé sans réponse.
5. **Mulligan** dans la zone de la main : un clic marque une carte à écarter (deux anneaux verts), un second la démarque ; le grand bouton devient « Confirmer » ; consigne au centre de la colonne ; pas de zone d'Écart.
6. **Choix du moteur** (ordre des effets déclenchés 208.4.6, cibles) sur place : consigne au centre de la colonne, éléments à choisir à l'anneau jaune là où ils sont (entrées de pile numérotées au fil des clics), grand bouton caché.
7. **Fatigue** (209.5) : à partir de 1, libellé du coin « Deck · Défausse · Fatigue N » ; deck vide : « 0 carte ».
8. **Relais et fin de partie** à l'étape 2.4 ; l'écran de 2.3 réserve une couche d'affichage par-dessus le jeu ; d'ici là, relais automatique et fin annoncée en une ligne au centre de la colonne.

Restent ouverts : lisibilité en 1280×720 (capture une fois l'écran construit) ; illustrations, icônes et teintes définitives, daltonisme.

## Conséquences et vérification

- `DuelSelection` : pouvoir du Hero lancé depuis la carte Hero, plus par la pièce. Composants : carte Hero cliquable, Sources sans « Annuler », grand bouton unique, consigne de la colonne.
- Vérifier par les tests de `DuelSelection` et par la scène de l'écran comparée par capture aux maquettes.
- À réexaminer après le playtest J3 (clics involontaires, lisibilité).

## Références

Ruleset 202.3.13, 203.6, 204.2, 208.4.6, 209.5 ; décisions 0003, 0023, 0026, 0028, 0030, 0031 ; roadmap étapes 2.3 et 2.4.
