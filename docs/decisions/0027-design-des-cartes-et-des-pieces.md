# 0027 — Design des cartes et des pièces dans la vue

- Statut : acceptée ; complétée par 0030 ; modifiée par 0033 et 0034 ; modifiée par 0047
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : présentation des cartes (main, aperçu) et des pièces du plateau (`ui/components/` : CardView, PieceView, HoverPreview ; étape 2.3)

## Contexte

L'étape 2.2 a créé CardView, PieceView et HoverPreview avec l'aspect sobre de la décision 0025 ; il s'agit de les faire évoluer. Le ruleset impose : carte de deck = nom, coût, type, texte, Force pour Units et Buildings seulement (202.1.1 à 202.1.8) ; carte Hero = nom, PV, texte avec passif et pouvoir, coût du pouvoir, pas de Force (202.3.6 à 202.3.13) ; jeton = Unit ou Building créé par un effet, avec une Force, sans carte (202.4.2, 202.4.8, 202.4.9), sans mot-clé (décision 0137 du ruleset), pouvant porter un Gear (décision 0136) ; une Unit porte au plus un Gear (202.2.10) ; seules les Sources s'inclinent. Aucune illustration n'existe. Cible : navigateur 1920×1080, duel local à deux humains sur un même écran. Pilier 4 : « la puissance reste lisible ».

## Options envisagées

1. Gabarit de la carte en main
   - A, classique avec illustration : carte et pièce se reconnaissent ; place réservée à une image absente.
   - B, lisibilité d'abord sans illustration : texte large ; carte et pièce se ressemblent peu.
   - C, bandeau compact, carte au survol : main discrète ; texte illisible sans survol.
   - B d'abord retenu, puis le créateur l'a fait évoluer vers A, en s'inspirant de Riftbound pour le type et les mots-clés, sans en reprendre formes ni ornements.
2. Pièce au plateau : A, jeton compact (Force, icône), discret mais sans rappel de la carte ; B, mini-carte, reconnaissable mais plus large. B retenue, carrée et remplissant la case, plutôt que portrait réduit et centré (bandes vides, Force petite).
3. Marque du joueur : A, liseré épais (visible, encadrement plus lourd) ; B, case teintée (conflit avec le surlignage des cases légales) ; C, bandeau du bas (le bandeau perd la couleur du type). Couleurs fixes (A bleu, B rouge) plutôt que relatives, qui s'inverseraient à chaque relais.
4. Force modifiée : A, pastille colorée et valeur imprimée barrée (lisible, un peu plus de place) ; B, pastille neutre et écart signé (sobre, calcul mental).
5. Mots-clés : une couleur par mot-clé (distinctif, mais bruyant et en conflit avec les teintes de type) ou une seule (sobre).
6. Jetons : A, mini-carte au même gabarit (cohérent, Gear emboîté comme pour toute Unit) ; B, pion rond (Gear mal emboîté, variante Building nécessaire).

## Décision

Choix du créateur, le 2026-10-18 : option A du sujet 1, mini-carte du sujet 2, liseré du sujet 3, pastille colorée du sujet 4, une seule couleur de mots-clés, option A du sujet 6. Remplace la décision 0025 pour l'aspect des cartes et des pièces.

- Carte en main : coût en haut à gauche, nom, Force en haut à droite (Units et Buildings seulement) ; illustration au centre, remplacée par l'icône du type tant qu'il n'y en a pas ; bandeau de type dessous (icône et libellé ; vitesse d'un Spell à droite : « Réaction » ou « Action ») ; texte en bas, mots-clés en étiquette en tête de leur texte, d'une même couleur sombre distincte des teintes de type ; toute la carte, opaque, prend la teinte de son type (cinq teintes : Unit, Building, Spell, Gear, Hero).
- Carte Hero : même gabarit ; PV (avec un cœur) à la place de la Force ; coût du pouvoir dans une étiquette « Pouvoir · N » en tête du texte du pouvoir.
- Pièce (PieceView) : mini-carte carrée remplissant la case : nom, Force en haut à droite, illustration, bandeau de type portant les étiquettes de mots-clés ; aucun coût. Le Hero porte ses PV à la place de la Force.
- Joueur : liseré épais, A bleu, B rouge, fixes. Le rouge n'est employé pour rien d'autre.
- Force : lue par une requête de `DuelEngine`, jamais recalculée dans la vue. Pastille neutre si elle égale l'imprimée ; verte au-dessus, orange en dessous, valeur imprimée barrée à côté.
- Gear attaché : sa carte, de même largeur que l'Unit, est derrière la mini-carte et dépasse d'une bande en haut (icône et nom) ; une seule bande au plus.
- Jeton : même mini-carte, sans bord distinct ; bandeau « Unit · Jeton » ou « Building · Jeton » ; nom affiché « Jeton », teinte et icône de son type. Un nom de jeton exigerait d'abord une règle du ruleset (202.4.2) ; le nom remplacerait « Jeton ».
- Survol : HoverPreview affiche la carte complète de la pièce survolée, et celle de son Gear à côté s'il y en a un.
- Laissé à l'étape 2.3, dans le thème unique `ui/theme/` : valeurs exactes des teintes et choix des icônes.

## Conséquences et vérification

- La carte en main et la pièce se reconnaissent ; la puissance se lit par la pastille de Force ; le texte se lit au survol. Le liseré ne gêne pas le surlignage des cases légales.
- Il faut cinq teintes et des icônes de type provisoires, jusqu'aux illustrations.
- Vérification : scènes d'essai existantes de CardView et PieceView avec les 17 cartes et le Hero Capitaine de `data/cards/test_deck.json`, lisibles en 1280×720 ; Force et nom d'une mini-carte lisibles à la taille d'une case, avec et sans Gear.
- À réexaminer : à l'arrivée des illustrations, si le playtest montre un plateau illisible, ou quand les jetons auront un nom.

## Références

Ruleset 202.1, 202.2.10, 202.3, 202.4 ; décisions 0136 et 0137 du ruleset ; vision (pilier 4) ; décisions du projet 0001, 0006, 0025, 0028 ; `ui/CLAUDE.md` ; roadmap étapes 2.2 et 2.3.
