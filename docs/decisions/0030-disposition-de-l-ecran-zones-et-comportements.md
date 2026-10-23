# 0030 — Disposition de l'écran de partie : zones et comportements

- Statut : acceptée ; complétée par 0032 ; modifiée par 0035 ; modifiée par 0047 ; complétée par 0050
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : écran de duel (`ui/`, étape 2.3)

## Contexte

0028 a fixé la disposition V1. Le créateur a ensuite décrit chaque zone (contenu, comportement, raison) ; l'agent `godot-ui-ux` a proposé une maquette et un audit. Il faut fixer le repère, les zones et leurs comportements avant de construire la scène. Cette décision complète 0028, qui reste en vigueur pour ce qu'elle ne contredit pas.

## Options envisagées

- Relais à deux humains : A toujours en bas (retenu ; à terme, chaque joueur ne joue que sa propre main), ou écran retourné pour mettre en bas le joueur qui a l'appareil (proposé par l'agent ; même ergonomie pour les deux, mais le plateau change de sens à chaque relais).
- Enregistrer la spécification : compléter 0028 par une nouvelle décision (retenu ; garde l'historique), ou réécrire 0028.
- Aperçu avec Gear : 348×484 par carte (spécification initiale ; deux cartes débordent sur le plateau, 705 px pour 555 disponibles), ou deux cartes à l'échelle 1,7, soit 269×374 (conseil de l'agent, retenu).

## Décision

Choix du créateur, le 2026-10-18. Repère 1920×1080, marges 16 px. Joueur A toujours en bas, jamais d'écran retourné. Couleurs fixes, A bleu et B rouge, pour toute appartenance. En duel local à deux humains, ce qui sert à jouer va au joueur qui a l'appareil : la main du bas montre ses cartes, la main du haut des dos ; seules ses Sources réagissent, en haut ou en bas.

1. **Plateau** x 595, y 94, 731×731 ; cases de 143, écart 4 ; colonnes A–E dessous, rangées 1–5 à gauche, rangée 1 en bas. Un clic sur une pièce est un geste sur sa case ; surlignage par `DuelSelection` ; appartenance au liseré de la pièce, jamais à la couleur de la case ; PV d'un Hero seulement sur sa pièce.
2. **Main du bas** x 424, y 844, 1136×220 : jusqu'à 7 cartes 158×220, écart 5, droites, entières ; survol = aperçu ; clic = `card_pressed`.
3. **Main adverse** y 16, centrée : dos 50×70, écart 8, sans chiffre.
4. **Sources**, un bloc 394×220 par joueur. A : x 16, y 844, compteurs au-dessus (y 806) Essence, Réserve, Fonte. B : x 16, y 16, compteurs dessous (y 244) Réserve, Fonte. Dix emplacements 74×106 (écarts 6 et 8), vides en pointillé ; Source inclinée estompée, bordure grise, sans pivoter ; clic sur une Source redressée ; « Recycler +1 » au survol d'une Source inclinée ; « Annuler ».
5. **Deck et défausse** dans le coin de chaque joueur (A en bas à droite, B en haut à droite), 158×220 chacun, écart 10, sur la marge droite, libellé « Deck · Défausse » côté plateau ; deck face cachée avec son nombre ; défausse avec sa carte du dessus ; survol de la défausse = aperçu.
6. **Colonne de duel** x 1342, y 94, 220×731 : pendule de B en haut, de A en bas (nom, temps, barre ; vive quand elle tourne, selon `clock_owners()` du moteur). Centre, pile vide : « Tour N », qui doit jouer, « Terminer le tour » aux couleurs du joueur qui agit. Pile non vide : la pile (dernière entrée en haut, teinte de la carte, liseré du joueur, survol = aperçu), qui peut répondre, « Passer » aux couleurs de ce joueur, et dessous le décompte de la fenêtre de réponse (0029).
7. **Aperçu** centré dans la colonne gauche entre les compteurs des deux joueurs (vers x 120, y 301), sans libellé : 348×484 pour une carte seule ; avec un Gear, la carte et celle du Gear côte à côte à 269×374.
8. **Pas de journal à l'écran** (`DuelJournal`, 0022, conservé pour le replay et les fiches).

Marques (0027 complétée) : la carte jouable, ou la pièce et l'entrée de pile ciblables, portent un anneau jaune ; choisies, deux anneaux verts ; au survol, un anneau clair ; le liseré du joueur reste visible.

Références visuelles : `ecran-de-partie-v1.html` et `ecran-de-partie-v2.html` (maquette de `godot-ui-ux`) dans `docs/maquettes/`. Dans la V2, l'état 6 (écran retourné) ne vaut pas : A reste en bas. Les cotes ci-dessus priment.

Restent ouverts, à soumettre au créateur : compteur Essence (brouillon partout, ou réserve réelle pendant son tour comme 0028) ; mulligan (main de départ, Écart) ; place de « Confirmer », « Annuler la sélection » et « Pouvoir du Hero », absents de la spécification ; choix demandés par le moteur (ordre des déclencheurs, cibles) ; compteur de fatigue (209.5) ; écrans de relais et de fin (étape 2.4) ; lisibilité en 1280×720 ; illustrations, icônes et dos définitifs, teintes finales, daltonisme (vert et orange de la Force).

## Conséquences et vérification

- Scène de l'écran de duel construite à ces cotes, comparée par capture aux deux maquettes. Composants à créer : plateau avec repères, main, main adverse, coin deck et défausse, colonne de duel.
- À réexaminer après le playtest J3, ou à l'arrivée d'un mode à un seul joueur humain par écran.

## Références

Ruleset 201.2.5, 201.3.4, 201.4.1 à 201.4.8, 202.2.10, 203.2.1, 203.2.2, 203.5.3, 203.5.7, 208.6, 209.4 ; décisions 0003, 0022, 0023, 0026, 0027, 0028, 0029 ; `ui/CLAUDE.md` ; les deux maquettes ; roadmap étape 2.3.
