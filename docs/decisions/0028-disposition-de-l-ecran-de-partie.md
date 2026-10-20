# 0028 — Disposition de l'écran de partie

- Statut : acceptée ; complétée par 0030
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : écran de duel (`ui/`, étape 2.3)

## Contexte

L'étape 2.3 assemble l'écran. Cible : navigateur 1920×1080, duel local à deux humains sur un même écran, couleurs de joueur fixes (A bleu, B rouge, décision 0027). Ruleset 0.36 : réserve d'Essence pendant son tour (203.6, décision 0026), fenêtre de réponse de 2 s (208.6, décision de design 0198 du ruleset), une passe résout toute la pile (208.3.1a). Référence visuelle : `docs/maquettes/ecran-de-partie-v1.html` (HTML 1920×1080 à ouvrir dans un navigateur, référence et non code). Les cotes ci-dessous priment sur la maquette en cas d'écart ; la maquette reste telle quelle, une version suivante irait dans un nouveau fichier.

## Options envisagées

- Disposition : maquette V1 présentée par le créateur, retenue telle quelle.
- Compteur d'Essence : brouillon de `DuelSelection` en tout temps (brief initial ; incompatible avec la réserve du moteur, 0026), ou réserve réelle pendant son tour et brouillon pendant le tour adverse (retenue).
- Recyclage : clic direct sur la Source inclinée (0023 ; risque de recyclage par erreur), ou bouton « Recycler +1 » au survol (retenu).
- Journal : à l'écran (roadmap initial), ou aucun (retenu ; la place va à l'aperçu).

## Décision

Choix du créateur, le 2026-10-18 (cotes en 1920×1080).

- Plateau 5×5 centré : cases de 143 px, écart 4 px (731×731), x 595, y 94. Coordonnées A–E sous le plateau, 1–5 à gauche ; rangée 1 en bas (première rangée du joueur A).
- Main du joueur en bas : 7 cartes droites et entières, sans chevauchement ni effet, 158×220 px, écart 5 px, y 844, à partir de x 424. Main adverse en haut au centre : dos de cartes 50×70 px.
- Sources : 10 emplacements en 2 rangées de 5, à gauche de la main, de la hauteur d'une carte de main (cartes 74×106, écarts 6 et 8 px). Emplacements vides en pointillé ; Source inclinée estompée, bordure grise, sans pivoter. Au-dessus, compteurs lisibles : Essence, Réserve (Sources pas encore en jeu, glossaire), Fonte. Adversaire : en haut à gauche, compteurs Réserve et Fonte sous ses Sources.
- Paiement : un clic sur une Source redressée l'incline (+1 Essence) ; au survol d'une Source inclinée, un bouton « Recycler +1 » la recycle (+1 Essence, elle passe dans la Fonte). Cela modifie le geste de recyclage de 0023.
- Compteur Essence : pendant son tour, il montre la réserve réelle du moteur (0026), sans bouton « Annuler » (l'Essence produite ne se reprend pas) ; pendant le tour adverse, il montre le brouillon de `DuelSelection`, sans effet sur l'état, envoyé avec la réponse sous la forme {incliner, recycler} (0003), et « Annuler » le remet à zéro.
- Deck et défausse à la taille d'une carte de main (158×220), dans le coin droit de chaque joueur ; le deck montre son nombre de cartes, la défausse sa carte du dessus.
- Colonne de duel collée à droite du plateau, de sa hauteur (220×731) : pendule du joueur B en haut, du joueur A en bas (nom, temps, barre du temps restant ; vive quand elle tourne, estompée sinon). Au centre : « Tour N », qui doit jouer, et « Terminer le tour » aux couleurs du joueur qui agit. La pile ne s'affiche que non vide : le centre montre alors la pile (dernière entrée en haut, teinte de la carte, liseré du joueur), qui peut répondre, le bouton « Passer » et, dessous, le décompte de la fenêtre de réponse (208.6). Où vit ce décompte (hôte ou vue) reste une décision séparée, à prendre au début de l'étape 2.3.
- Aperçu au survol en grand (environ 348×484), centré dans la colonne gauche entre les compteurs des deux joueurs, sans libellé.
- Pas de journal à l'écran : `DuelJournal` (0022) reste pour le replay et les fiches de playtest ; LogView ne reste que dans le bac à sable (`ui/components/_try/try_duel_sandbox.tscn`).
- Laissé au créateur, sur proposition dans `ui/theme/` avec capture : valeurs exactes des teintes et icônes (à partir de la maquette), fond de table.

## Conséquences et vérification

- Un clic de plus pour recycler, contre aucun recyclage par erreur ; aucune règle dans la vue.
- Vérification : capture de l'écran assemblé comparée à la maquette à l'étape 2.3 ; tests de `DuelSelection` pour le compteur d'Essence et « Annuler » en tour adverse.
- À réexaminer après le playtest J3 (lisibilité, nombre de clics), ou si l'écran doit tenir dans un autre format que 1920×1080.

## Références

Ruleset 203.5, 203.6, 208.3.1a, 208.6 ; décisions 0003, 0022, 0023, 0024, 0026, 0027 ; `ui/CLAUDE.md` ; `docs/maquettes/ecran-de-partie-v1.html` ; roadmap étape 2.3.
