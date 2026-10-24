# Fiche technique — écran de duel

> **Rôle** : spécification vivante de l'écran de duel (décision 0052). Elle donne, pour chaque élément, son node Godot, sa couche, sa taille, sa place, sa transparence, ses états et l'asset qu'il attend. Elle sert à reconstruire l'écran (étape 2b.3) et à générer les assets aux bonnes tailles (2b.4 à 2b.6). Maquette annotée : [ecran-de-duel-gabarit.html](../maquettes/ecran-de-duel-gabarit.html).

- Statut : **version 1, validée par le créateur le 24 octobre 2026** (décision 0053). Ordre de priorité : les décisions fixent les choix ; la fiche en donne les cotes et prime sur la maquette. La décision 0053 a rendu la fiche prioritaire sur les cotes de 0030, 0032, 0035 et 0050, qu'elle reprend avec les changements consignés au journal.
- Une modification de cette fiche se fait par édition directe, avec une ligne au journal en fin de document. Si elle change un comportement, elle passe par `/decision`.

## 1. Repère et principes

| Sujet | Règle |
| --- | --- |
| Repère | 1920×1080 px, origine en haut à gauche. Toutes les cotes de la fiche sont dans ce repère. |
| Mise à l'échelle | `canvas_items` / `expand` (`project.godot`) : en 1280×720, tout est réduit à 2/3 sans changer la disposition. Sur un écran plus haut ou plus large que 16:9, la surface de jeu gagne de la place, et les conteneurs décident qui la prend (§4). |
| Marge | 16 px sur les quatre bords (`MarginContainer`). |
| Joueur du bas | Le joueur de l'appareil, A par défaut. Pour le second écran d'un duel à distance, c'est B (décision 0050). Dans la fiche, « bas » et « haut » désignent le camp de l'appareil et le camp adverse. |
| Couleurs de camp | A en bleu `#2f7fd8`, B en rouge `#d23a3a`, fixes (décision 0030). |
| Style | Thème unique `ui/theme/duel_theme.tres`, avec des variations par `theme_type_variation`, jamais de `theme_override`. Chaque couche reçoit le thème sur sa racine, car un `CanvasLayer` coupe l'héritage du thème (décision 0052). |
| Assets | Rangés dans `assets/`, retrouvés par leur nom, avec un repli sur le dessin actuel (décision 0051). La taille d'asset donnée ici est la taille d'affichage en 1920×1080, notée « @1x ». Un asset se livre en @1x, sauf mention « @2x » pour ce qui s'agrandit (illustrations : aperçu ×2,2). |
| Transparence | `modulate.a` sur un élément entier ; couleur à alpha dans un `StyleBox` pour un fond. Les valeurs fixes sont dans `DuelPalette`. |
| États | Tout élément cliquable a quatre états : normal, survol, enfoncé, désactivé. Les marques de jeu s'y ajoutent : jouable, choisi, survol (décision 0030). |

## 2. Couches

Ordre d'affichage du fond vers l'avant. Un `CanvasLayer` plus haut reçoit la souris en premier.

| Couche | Node | `layer` | Contenu | Souris |
| --- | --- | --- | --- | --- |
| Fond | `BackgroundLayer` (CanvasLayer) | 0 | table, décor | ignorée (`MOUSE_FILTER_IGNORE`) |
| Jeu | `PlayLayer` (CanvasLayer) | 1 | toutes les zones de jeu, bouclier d'entrée | zones cliquables |
| Fenêtres | `ModalLayer` (CanvasLayer) | 2 | abandon, fin de partie ; les choix demandés par le moteur restent sur le plateau (Q5) | bloque tout ce qui est dessous quand une fenêtre est ouverte |
| Informations | `InfoLayer` (CanvasLayer) | 3 | aperçu au survol, bulles | ignorée : ne vole jamais un clic |

> Q1 tranchée le 24 octobre 2026 : l'aperçu reste à sa place fixe à gauche (décision 0030), dans la couche Informations. Les bulles d'information (E27) s'empilent à sa droite.

## 3. Arbre de scène cible

Les noms entre parenthèses sont les composants existants de `ui/components/`. Leur intérieur ne change pas à l'étape 2b.3, sauf ce que la fiche change : les repères A–E sortent de `BoardView` pour passer sous la barre du bas, et `DuelColumnView` et `SourcesView` changent selon §5.4 et §5.5.

Cotes qui en découlent dans la colonne du milieu (x 424 à 1562, largeur 1138) :
- horizontalement, `PlayRow` est alignée à droite : la colonne de duel garde x 1342 à 1562, et la grille va de x 615 à 1326 (repères 1–5 de x 591 à 611) ;
- verticalement : main adverse de y 16 à 86, barre du haut de 89 à 95, grille de 98 à 809, barre du bas de 812 à 818, lettres A–E de 821 à 841, main du bas de 844 à 1064 ;
- les barres ont la largeur de la grille (711), sous la marge de 24 des repères.

```text
DuelScreen (Control, plein écran, script duel_screen.gd)
├─ BackgroundLayer (CanvasLayer 0)
│  └─ Background (Control plein écran, thème)
│     └─ Table (TextureRect plein écran, stretch « keep aspect covered » ; repli ColorRect)
├─ PlayLayer (CanvasLayer 1)
│  └─ PlayRoot (Control plein écran, thème)
│     ├─ Margins (MarginContainer 16 px)
│     │  └─ Columns (HBoxContainer, séparation 14)
│     │     ├─ LeftColumn (VBoxContainer, largeur 394)
│     │     │  ├─ SourcesTop (SourcesView, compteurs dessous)
│     │     │  ├─ LeftSpacer (Control, s'étend)
│     │     │  └─ SourcesBottom (SourcesView, compteurs dessus)
│     │     ├─ MiddleColumn (VBoxContainer, s'étend)
│     │     │  ├─ OpponentHand (OpponentHandView, centrée)
│     │     │  ├─ PlayRow (HBoxContainer, séparation 16, s'étend en hauteur, alignée à droite)
│     │     │  │  ├─ BoardArea (VBoxContainer, séparation 3, largeur 735)
│     │     │  │  │  ├─ TimeBarTop (TurnTimerBar, nouveau composant, marge gauche 24)
│     │     │  │  │  ├─ BoardFrame (AspectRatioContainer 1:1, s'étend)
│     │     │  │  │  │  └─ Board (BoardView : repères 1–5 à gauche, grille)
│     │     │  │  │  ├─ TimeBarBottom (TurnTimerBar, marge gauche 24)
│     │     │  │  │  └─ ColumnLetters (repères A–E, marge gauche 24, hauteur 20)
│     │     │  │  └─ Column (DuelColumnView, largeur 220)
│     │     │  └─ Hand (HandView, centrée)
│     │     └─ RightColumn (VBoxContainer, largeur 326)
│     │        ├─ DeckCornerTop (DeckCornerView)
│     │        ├─ RightSpacer (Control, s'étend)
│     │        └─ DeckCornerBottom (DeckCornerView)
│     └─ InputShield (Control plein écran, bloque pendant la lecture des événements)
├─ ModalLayer (CanvasLayer 2)
│  └─ Overlays (DuelOverlays : ConcedeConfirm, EndPanel)
├─ InfoLayer (CanvasLayer 3)
│  └─ InfoRoot (Control plein écran, thème, souris ignorée)
│     ├─ Preview (HoverPreview, place §5 E21)
│     └─ Tooltips (VBoxContainer, séparation 8, place §5 E27)
└─ EventPlayer (Node)
```

> Q2 tranchée le 24 octobre 2026 : la main du bas et la main adverse sont centrées sur la colonne du milieu (`MiddleColumn`, centre vers x 993), au lieu de x 424 et du centre de l'écran.

## 4. Place gagnée sur un écran non 16:9

| Écran | Ce qui grandit | Ce qui reste fixe |
| --- | --- | --- |
| Plus haut (16:10, 4:3) | Les espaceurs des colonnes gauche et droite. Le plateau grandit jusqu'à la place libre, en restant carré, et les barres de temps le suivent. | Mains, Sources, decks, colonne de duel (largeur) |
| Plus large (21:9) | Les marges latérales de la colonne du milieu ; le plateau reste à sa hauteur. | Tout le reste |

> Q3 tranchée le 24 octobre 2026 : sur un écran plus haut que 16:9, le plateau grandit en restant carré, et les barres de temps le suivent.

## 5. Éléments

Légende des colonnes :
- **Taille** : taille en 1920×1080 ; « ext. » veut dire que l'élément s'étend dans son conteneur.
- **Place** : position dans son parent.
- **Alpha** : transparence de l'élément entier (1 = opaque).
- **Asset attendu** : fichier dans `assets/`, avec format et taille @1x, ou « dessin » si l'élément reste dessiné en code.

### 5.1 Fond et cadre

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E01 | Table, fond d'écran | TextureRect (repli ColorRect `#1d2127`) | 1920×1080, couvre l'écran | couche Fond | 1 | — | `ui/table.webp`, 1920×1080 (2560×1440 conseillé pour les grands écrans) |
| E02 | Marges | MarginContainer | plein écran | 16 px | — | — | — |

### 5.2 Plateau (décisions 0030, 0035)

Chaque barre de temps (E17) prend 9 px, soit 6 de barre et 3 d'écart, au-dessus et au-dessous de la grille. La grille passe donc de 731 à 711 (cases de 139 au lieu de 143) et commence en y 98 ; la pièce passe de 129 à 125. Les cotes ci-dessous en tiennent compte (Q2b, acceptée avec le brouillon 2).

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E03 | Plateau | BoardView (Control) dans AspectRatioContainer | grille 711×711 (cases 139, écart 4), plus les repères (20 px et 4 d'écart) à gauche et, sous la barre du bas, en bas | grille à x 615, y 98 | 1 | — | `ui/board_frame.png`, cadre 9-patch autour de la grille, 751×751, marges 20 (optionnel) |
| E04 | Case | CellView (Control) | 139×139, écart 4 | grille 5×5, rangée 1 en bas | 1 | normal, survol `#333a44`, ciblable (anneau jaune 4 px), point de déplacement légal (rayon 8) | `ui/cell_normal.png`, `ui/cell_hover.png`, 139×139 ; marques dessinées |
| E05 | Repères A–E, 1–5 | Label `BoardCoordinateLabel` | 20 px, plus 4 d'écart, police 13 | 1–5 à gauche de la grille ; A–E sous la barre du bas (y 821) | 1 | — | police (§6) |
| E06 | Pièce : Unit, Building, jeton | PieceView (PanelContainer) | 125×125, 7 px de marge dans la case | centrée dans la case | 1 ; endormie : illustration en gris (Q4) | normal, survol (anneau clair `#ffffff99`), jouable (anneau jaune), choisie (deux anneaux verts), endormie | cadre par type `cards/frames/piece_<type>.png` 9-patch 125×125 ; illustration `cards/art/<id>.webp` (zone d'art à mesurer en 2b.6) |
| E07 | Pièce Hero | PieceView | 125×125 | dans sa case | 1 | idem E06, avec les PV en cœur 46 px ; survol = aperçu de la carte Hero en E21 (remplace E23) | `cards/frames/piece_hero.png` ; `cards/art/<hero_id>.webp` |
| E08 | Gear attaché | bande de la PieceView | 125×23 qui dépasse | sous la pièce | 1 | — | icône `icons/gear.svg` |
| E09 | Pastilles Force et PV | Control dessiné (`DuelIcons.Badge`) avec Label | losange 42, cœur 46 | coin de la pièce | 1 | Force en hausse vert `#1a6b1a`, en baisse orange `#a34a00` (0034) | dessin (décision 0033) ; asset possible en 2b.6 |

> Q4 tranchée le 24 octobre 2026 : une pièce endormie (dette « avant J3 ») montre son illustration en gris (désaturée), tout le reste en couleur : liseré de camp, pastilles, nom. Sans illustration, c'est l'icône du type qui passe en gris. Le rendu se fait par un shader de niveaux de gris sur la zone d'illustration (`ui/theme/grayscale.gdshader`, compatible GL Compatibility), sans asset en plus. Le survol ajoute la bulle « Endormie » (E27). Le gris s'applique aux pièces du joueur de l'écran : en duel à distance, celui de l'appareil ; en duel à deux sur un appareil, celui qui a l'appareil (décision 0030 : ce qui sert à jouer va au joueur qui a l'appareil). Les pièces adverses endormies sont grises elles aussi : l'état est visible des deux joueurs (201.4.11, ruleset 0.44, Q-104 tranchée le 24 octobre 2026).

### 5.3 Mains

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E10 | Main du bas | HandView (HBoxContainer) | 1136×220 (7 cartes de 158, écart 5) | centrée dans la colonne du milieu : x 425, y 844 | 1 | — | — |
| E11 | Carte en main | CardView (PanelContainer) | 158×220 | dans la main | 1 | normal, survol (anneau clair, et aperçu E21), jouable (anneau jaune), choisie (deux anneaux verts), écartée au mulligan | cadre par type `cards/frames/card_<type>.png` 9-patch 158×220 (@2x 316×440 pour l'aperçu) ; illustration `cards/art/<id>.webp` @2x |
| E12 | Main adverse | OpponentHandView (HBoxContainer) | hauteur 70, dos 50×70, écart 8 | y 16, centrée dans la colonne du milieu (centre x 993) | 1 | — | dos `cards/frames/card_back_small.png`, 50×70 (@2x 100×140) |

### 5.4 Sources et compteur d'Essence (décisions 0023, 0026, 0030)

Choix du créateur : un seul compteur, la réserve d'Essence (201.4.10). Les règles 201.4.4 (Sources inclinées), 201.4.5 (nombre de Sources en réserve) et 201.4.6 (Fonte) veulent que ces informations restent visibles des deux joueurs. Les emplacements les montrent donc sans texte, chacun dans l'un de quatre états : en jeu redressée, en jeu inclinée, en réserve, en Fonte. Ils se remplissent dans cet ordre. Leur nombre est `DuelConfig.total_sources_per_player` (203.5.7, PROVISOIRE, 10 aujourd'hui), jamais un 10 écrit dans la vue.

Le compteur garde le comportement actuel (203.6, décision 0032) : pendant son tour, la réserve d'Essence du joueur ; pendant le tour adverse, où il n'a pas de réserve (203.6.2), le paiement qu'il prépare.

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E13 | Bloc Sources | SourcesView (VBoxContainer) | 394×220 de grille, plus le compteur E15 | du bas : x 16, y 844, compteur au-dessus (y 806) ; du haut : x 16, y 16, compteur dessous (y 244) | 1 | — | — |
| E14 | Emplacement de Source | PanelContainer | 74×106, écarts 6 et 8, 5 colonnes × 2 rangées (10 emplacements selon `DuelConfig`) | grille | inclinée : 0,55 ; réserve : contour pointillé seul ; Fonte : 0,55, barrée | en jeu redressée (survol `#46505e`, cliquable), en jeu inclinée (bordure grise, estompée, « Recycler +1 » au survol), en réserve (pointillé), en Fonte (barrée d'une croix, estompée) | `ui/source_upright.png`, `ui/source_tilted.png`, `ui/source_reserve.png`, `ui/source_fonte.png`, 74×106 ; icône `icons/source.svg` 30 px |
| E15 | Compteur d'Essence (réserve, ou paiement préparé pendant le tour adverse) | PanelContainer avec icône et Label | 124×32, police 17 | au-dessus de la grille pour soi, dessous pour l'adversaire, aligné à gauche | 1 | — | fond 9-patch `ui/counter.png` ; icône `icons/essence.svg` 18 px (nouvelle icône à ajouter à `DuelIcons.Icon`) |

### 5.5 Colonne de duel et barres de temps (décisions 0029, 0030, 0032, 0045)

Choix du créateur : il n'y a plus de pendule (décision 0045 : 90 s par tour, en pause pendant la pile, 30 s par réponse). Une barre qui se vide longe le plateau du côté du joueur qui doit agir. La colonne de duel ne garde que le tour, la pile et les boutons.

Choix du créateur (option A, « colonne rangée ») : trois parties fixes, de haut en bas.
1. **En-tête** : le tour ou la taille de la pile, le joueur qui doit agir, et l'abandon.
2. **Pile** : la zone qui s'étend. La pile vide se montre par un cadre en pointillé « Pile vide ». Avec des entrées, c'est une liste dont la dernière arrivée est en haut, sous « ↑ résout en premier ».
3. **Bouton** : ancré en bas, à la couleur du camp qui agit, avec une ligne d'aide sous son libellé.

Arbre : `DuelColumnView` (PanelContainer) › `Column` (VBoxContainer) › `Header` (HBoxContainer), `StackArea` (PanelContainer qui s'étend, avec `EmptyLabel` et `StackScroll` › `StackView`), `BigButton`.

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E16 | Panneau de colonne | DuelColumnView (PanelContainer `ColumnPanel`) | 220×711, marges internes 10 | x 1342, y 98, à droite du plateau, de la hauteur de la grille | 1 | — | `ui/column_panel.png` 9-patch, marges 16 |
| E17 | Barre de temps, une par camp | TurnTimerBar : `TextureProgressBar` (repli `ProgressBar`) et Label des secondes | largeur de la grille (711) × 6 ; secondes en police 15 au bout, à droite | au-dessus de la grille pour l'adversaire (y 89), au-dessous pour soi (y 812), 3 px de la grille | deux états seulement. **Active** (ce camp doit agir) : 1. **Inactive** (ce camp n'a pas à agir) : piste vide à 0,25, sans secondes. | active : se vide de 90 s (tour) ou de 30 s (réponse), à la couleur du camp, puis en orange `#f2a33a` sous 10 s, avec les secondes en gras (signal visuel seul, sans effet de règle, 0053). Le reste d'un tour en pause s'écrit au bout de la barre de ce camp, active ou inactive, en petit à 0,55 : « tour : 54 s » (Q8). Pendant le mulligan, aucun temps ne s'écoule (209.4.2d) : les deux barres sont inactives. | `ui/time_bar_fill.png` et `ui/time_bar_track.png`, 9-patch 711×6, marges 3, en blanc, teintés par code |
| E18 | En-tête | HBoxContainer : deux Labels (`TurnNumberLabel` : « Tour 4 » ou « Pile · 2 » ; `TurnActorLabel` : « À toi de jouer », « B peut répondre », « Mulligan : choisis les cartes à écarter ») avec une pastille de camp de 10 px, puis E20c à droite | 200×56, filet de 1 px dessous | haut de la colonne | 1 | — | police ; filet dessiné |
| E19 | Pile | PanelContainer qui s'étend, avec ScrollContainer et StackView ; vide : Label « Pile vide » dans un cadre en pointillé | 200 × reste de la hauteur ; entrée 200×52, écart 6 | entre l'en-tête et le bouton | 1 | entrée : normal, survol (aperçu E21), ciblable (anneau jaune), choisie (deux anneaux verts) ; pastille d'ordre 22 px pour l'ordre des déclencheurs, comme aujourd'hui : seul le joueur qui choisit l'ordre voit ses déclencheurs en attente (208.4.6, 201.4.7) ; défilement au-delà de 10 entrées | `ui/stack_entry.png` 9-patch 200×52, marges 8 ; liseré de camp de 5 px à gauche, dessiné ; vignette de teinte du type 30×38 (illustration recadrée en 2b.6) ; cadre vide `ui/stack_empty.png` 9-patch |
| E20 | Grand bouton : « Terminer le tour », « Passer », « Confirmer » | Button `BigButton`, avec une seconde ligne en police 11 (« Fin du tour 4 », « laisser résoudre », « garder ces cartes ») | 200×64, police 19 | ancré en bas de la colonne | 1 ; désactivé : gris à 0,55, avec un texte qui dit ce qu'on attend (« Tour de B », « En attente de B ») (Q6) | normal, survol (+12 % de clarté), enfoncé (−12 %), désactivé ; couleur du camp qui agit | `ui/button_big_{normal,hover,pressed,disabled}.png` 9-patch, 200×64, marges 16, en blanc et gris, teinté par code à la couleur du camp |
| ~~E20b~~ | ~~Décompte de réponse~~ | supprimé : le temps de réponse est sur la barre E17 | — | — | — | — | — |
| E20c | Abandonner | Button à icône (`ConcedeButton`), drapeau | 26×26 | à droite de l'en-tête | 1 | normal (contour seul), survol, enfoncé ; ouvre E25 | `ui/button_icon_{normal,hover,pressed}.png` 9-patch 26×26 ; icône `icons/concede.svg` (nouvelle icône) |

### 5.6 Coin droit, decks et défausses, et aperçu (décisions 0030, 0032)

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E21 | Aperçu au survol | HoverPreview (HBoxContainer), couche Informations | carte seule 348×484 (×2,2) ; carte et Gear 2 × 269×374 (×1,7) | place fixe, centre x 294, y 543 (colonne gauche) | 1 | — | reprend E11 en @2x |
| E27 | Bulles d'information : mots-clés, effets, état (endormie…) | VBoxContainer de PanelContainers (titre en gras et texte), couche Informations, souris ignorée | 260 de large, hauteur selon le texte, écart 8, police 14 | à droite de l'aperçu, alignées sur son haut (x 478, y 301) ; avec un Gear, à droite de la paire (x 597). Elles passent par-dessus le bord gauche du plateau le temps du survol. | 1 ; ombre portée | apparaissent et disparaissent avec l'aperçu | `ui/tooltip_panel.png` 9-patch 260×80, marges 12 ; police (§6) |
| E22 | Coin deck et défausse | DeckCornerView (VBoxContainer) | 326×244 (libellé, puis deux emplacements 158×220, écart 10) | coin haut droit pour l'adversaire, bas droit pour soi | 1 | défausse : survol (aperçu) | dos `cards/frames/card_back.png` 158×220 (@2x 316×440) ; emplacement vide 9-patch |
| ~~E23~~ | ~~Carte Hero~~ | supprimée (choix du créateur, 24 octobre 2026) : elle servait au pouvoir du Hero, retiré par la décision 0047. Le survol de la pièce Hero (E07) montre sa carte dans l'aperçu E21. `HeroCardView` sera retiré à l'étape 2b.3. | — | — | — | — | le cadre `cards/frames/card_hero.png` reste pour l'aperçu |

### 5.7 Fenêtres (couche Fenêtres, décision 0036)

| ID | Élément | Node | Taille | Place | Alpha | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- | --- |
| E24 | Voile | ColorRect | plein écran | sous la fenêtre | couleur `#0f1217` à 0,72 | — | dessin |
| E25 | Fenêtre d'abandon | ConcedeConfirmView, panneau centré | ≈ 400×200 ; boutons 160×56 | centre de l'écran | 1 | — | `ui/modal_panel.png` 9-patch, marges 32 |
| E26 | Fenêtre de fin | EndPanelView, panneau centré | ≈ 700×320 ; trois boutons 200×56 ; titre en police 40 | centre | 1 | — | `ui/modal_panel.png` ; `ui/button_modal_*.png` 9-patch 200×56 |

### 5.8 Marques de jeu (décisions 0027, 0030)

| ID | Marque | Forme | Couleur et alpha | Où |
| --- | --- | --- | --- | --- |
| M1 | Jouable ou ciblable | anneau 3 px, écart 1, rayon 10 | jaune `#f2c14e` | cartes, pièces, cases, entrées de pile |
| M2 | Choisi | deux anneaux 3 px | vert `#4ecb71` | idem |
| M3 | Survol | anneau 3 px | blanc à 0,6 | idem |
| M4 | Camp | liseré 4 px | bleu ou rouge du camp | pièces, Heroes, entrées de pile |

Les marques restent dessinées en code : elles doivent rester nettes à toute taille et ne dépendent pas de la direction artistique.

## 6. Polices

| Rôle | Tailles actuelles (px) | Asset attendu |
| --- | --- | --- |
| Titres (fin de partie) | 40 | `fonts/<titre>.woff2` ou `.ttf`, libre (OFL) |
| Chiffres (deck 28, pastilles 15 à 19, secondes 15) | 15 à 28 | police à chiffres de même largeur |
| Texte courant et boutons | 11 à 22 | `fonts/<texte>.ttf` |
| Texte des cartes | 9 à 14 | lisible en 1280×720, soit 6 à 9 px réels (décision 0035) |

Deux polices au plus (`ui/CLAUDE.md`), choisies à l'étape 2b.4.

## 7. Inventaire des assets de l'écran de duel

Une ligne par fichier, à ajouter à `assets/REGISTRE.md` le jour de sa livraison.

| Fichier | Format | Taille @1x | 9-patch | Pour |
| --- | --- | --- | --- | --- |
| `ui/table.webp` | WebP | 1920×1080 | non | E01 |
| `ui/board_frame.png` | PNG | 751×751 | 20 | E03 |
| `ui/cell_normal.png`, `ui/cell_hover.png` | PNG | 139×139 | non | E04 |
| `ui/source_upright.png`, `ui/source_tilted.png`, `ui/source_reserve.png`, `ui/source_fonte.png` | PNG | 74×106 | non | E14 |
| `ui/counter.png` | PNG | 124×32 | 8 | E15 |
| `ui/column_panel.png` | PNG | 220×711 | 16 | E16 |
| `ui/time_bar_fill.png`, `ui/time_bar_track.png` | PNG blanc | 711×6 | 3 | E17 |
| `ui/stack_entry.png` | PNG | 200×52 | 8 | E19 |
| `ui/stack_empty.png` | PNG | 200×200 | 12 | E19 |
| `ui/button_big_{normal,hover,pressed,disabled}.png` | PNG | 200×64 | 16 | E20 |
| `ui/button_icon_{normal,hover,pressed}.png` | PNG | 26×26 | 6 | E20c |
| `ui/modal_panel.png` | PNG | 400×200 | 32 | E25, E26 |
| `ui/tooltip_panel.png` | PNG | 260×80 | 12 | E27 |
| `ui/button_modal_{normal,hover,pressed,disabled}.png` | PNG | 200×56 | 16 | E25, E26 |
| `cards/frames/card_<type>.png` (unit, building, spell, gear, hero) | PNG | 158×220, @2x 316×440 | à mesurer en 2b.6 | E11, E21 |
| `cards/frames/piece_<type>.png` | PNG | 125×125, @2x 250×250 | à mesurer en 2b.6 | E06, E07 |
| `cards/frames/card_back.png`, `card_back_small.png` | PNG | 158×220 et 50×70 (@2x) | non | E12, E22 |
| `cards/art/<id>.webp` | WebP | @2x, 1024 au plus | non | E06, E07, E11 |
| `icons/<icône>.svg`, dont `essence.svg` et `concede.svg` | SVG blanc | 24×24 | non | E08, E14, E15 |
| `fonts/*` | TTF, OTF, WOFF2 | — | — | §6 |

## 8. Questions ouvertes pour le créateur

- ~~Q1~~ : tranchée. L'aperçu a une place fixe à gauche, et les bulles (E27) sont à sa droite.
- ~~Q2~~ : tranchée. Les mains sont centrées sur la colonne du milieu.
- ~~Q2b~~ : tranchée. Le créateur a accepté le brouillon 2 : cases de 139, plateau de 711.
- ~~Q3~~ : tranchée. Le plateau grandit en restant carré.
- ~~Q4~~ : tranchée. L'illustration passe en gris.
- ~~Q5~~ : tranchée. Les choix demandés par le moteur restent sur le plateau et dans la pile : les cibles s'allument (M1), l'en-tête E18 dit « Choisis une cible », le bouton E20 devient « Confirmer », et l'ordre des déclencheurs s'indique par les pastilles 1, 2, 3 de la pile (E19). Aucune fenêtre ne s'ouvre.
- ~~Q6~~ : tranchée. Le bouton désactivé reste à sa place, en gris à 0,55, avec un texte qui dit ce qu'on attend.
- ~~Q8~~ : tranchée. Une seule barre, celle qui se vide. Le reste d'un tour en pause s'écrit à côté, en petit : « tour : 54 s ».
- ~~Q9~~ : tranchée le 24 octobre 2026. La place libérée à droite par les cartes Hero (de y 260, bas du coin du haut, à y 820, haut du coin du bas) reste vide : le fond de la table respire, et la direction artistique pourra y poser un décor (2b.4). L'historique des coups et les plaques des joueurs ont été écartés.
- Q7 (technique, sans choix à faire) : un SVG est importé à sa taille native. Pour rester net sur une case ou dans l'aperçu, il faut régler son échelle d'import (`svg/scale`) d'après la plus grande taille d'affichage de la fiche, puis la contrôler dans `test_assets.gd`.

## Journal

- 2026-10-24 : brouillon 1, relevé de l'écran actuel (étape 2b.2).
- 2026-10-24 : brouillon 2. Seul le compteur d'Essence reste ; réserve et Fonte se lisent par les emplacements (201.4.6). Les cartes Hero sont supprimées, l'aperçu passe par la pièce Hero. La pendule est remplacée par une barre de temps au bord du plateau (0045). La grille est proposée à 711.
- 2026-10-24 : colonne de duel rangée (option A, choix du créateur) : en-tête, pile qui s'étend, bouton ancré en bas ; décompte de réponse retiré au profit de la barre E17 ; abandon en bouton à icône.
- 2026-10-24 : Q9 tranchée, la place libre à droite reste vide.
- 2026-10-24 : Q1 tranchée. L'aperçu a une place fixe à gauche ; les bulles d'information (E27, 260 de large) s'empilent à sa droite et passent par-dessus le bord du plateau pendant le survol. La place réservée sous l'aperçu a été écartée, faute de hauteur.
- 2026-10-24 : Q2, Q3 et Q4 tranchées. Les mains sont centrées sur la colonne du milieu ; le plateau grandit sur un écran plus haut ; une pièce endormie a son illustration en gris.
- 2026-10-24 : Q5, Q6 et Q8 tranchées. Les choix restent sur le plateau et dans la pile ; le bouton désactivé est grisé, avec un texte ; une seule barre de temps, avec le reste du tour en texte. Brouillon 3, à valider.
- 2026-10-24 : version 1, validée par le créateur ; choix consignés par la décision 0053.
- 2026-10-24 : corrections de la relecture de clôture. La grille passe en x 615 (`PlayRow` alignée à droite), les barres se placent entre la grille et les lettres A–E, et la main du bas en x 425. La barre de temps n'a que deux états, et l'alerte orange est gardée par le créateur comme signal visuel seul. Les règles citées sont 201.4.4 à 201.4.6 et 201.4.10 ; le nombre d'emplacements vient de `DuelConfig`. Sont précisés : le compteur hors de son tour, le mulligan, le duel sur un seul appareil et les déclencheurs en attente.
- 2026-10-24 : Q-104 tranchée (ruleset 0.44, 201.4.11). Le gris d'une pièce endormie vaut pour les pièces des deux camps.
