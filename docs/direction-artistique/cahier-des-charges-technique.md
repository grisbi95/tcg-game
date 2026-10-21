# Cahier des charges technique des assets

> **Rôle** : liste de tout ce qui doit être dessiné pour l'écran de duel actuel, avec la taille et le format de chaque fichier. Aucune consigne de style : le style relève de [bible.md](bible.md). **Statut : brouillon du 21 octobre 2026.** Les tailles affichées viennent du code de `ui/` (constantes des composants) et des décisions 0027 à 0036 ; celles marquées « ≈ » sont relevées sur capture, à ± 2 px.

## 1. Règles communes

| Sujet | Règle |
| --- | --- |
| Repère | Toutes les tailles affichées sont en pixels du repère 1920 × 1080 (viewport du projet). La fenêtre de développement est en 1280 × 720 ; un écran plus grand agrandit l'image (mode `canvas_items`, aspect `expand`). |
| Fichier maître | **2 × la plus grande taille affichée** de l'élément, pour rester net jusqu'à un écran 4K. Godot réduit ensuite à la taille voulue. |
| Dimensions | Nombres pairs, pour qu'une réduction de moitié tombe sur des pixels entiers. Épaisseurs de trait paires dans le fichier maître. |
| Export | PNG 32 bits RGBA, 8 bits par canal, espace sRGB, sans profil couleur incorporé. Fond transparent, sauf pour les tuiles et fonds opaques signalés. |
| Source | Fichier vectoriel (SVG) ou fichier de calques, conservé à côté de l'export. Le dossier de rangement reste à décider (décision D5 de l'audit). |
| SVG importé directement | Godot le convertit en image à l'import (option `svg/scale`) : il n'est pas redessiné à la volée. Pas de `<text>` (convertir en tracés), pas de filtre, pas d'image incorporée, pas de motif (`<pattern>`), pas de feuille de style externe. |
| Texte et chiffres | **Jamais dans une image.** Noms, textes de règles, coûts, Force, PV, temps et compteurs sont posés par Godot. Chaque élément qui en porte laisse une zone libre pour eux. |
| Couleurs de variante | Un élément d'une seule teinte (liseré de joueur, teinte de type, état) peut être livré **en niveaux de gris** et teinté par Godot (`modulate`) : un fichier au lieu de deux à cinq. Sinon, un fichier par couleur. |
| Extensibles (nine-patch) | Pour tout élément dont la taille varie (étiquette, bouton, panneau). Indiquer les quatre marges fixes (coins) ; le centre s'étire ou se répète. Largeur et hauteur minimales du maître : marges gauche + droite + 4 px, haut + bas + 4 px. |
| Taille fixe | Un élément qui ne change que d'échelle (carte, pièce, Source, case) est livré en image entière, pas en nine-patch. |
| Calques d'un même élément | Même toile, mêmes dimensions, calés au pixel, pour être empilés sans décalage. |
| Limite | Aucune texture au-delà de 4096 × 4096 (limite garantie du WebGL 2 de l'export Web). |
| Import Godot proposé | Interface : compression **Lossless**. Illustrations et fond de table : **Lossy** (WebP, qualité 0,8). Mipmaps activés pour ce qui s'affiche à plusieurs échelles (cartes, illustrations), désactivés ailleurs. « Fix Alpha Border » activé. |
| Nommage proposé | `snake_case`, famille puis élément puis variante : `card_frame.png`, `card_band_unit.png`, `piece_ring_selected.png`, `icon_type_gear.svg`. |

## 2. La carte

Composant `CardView` : **158 × 220** dans la main, la défausse et la carte Hero ; **348 × 484** dans l'aperçu (échelle 2,2) ; **269 × 374** dans l'aperçu avec un Gear (échelle 1,7). La carte ne fait que changer d'échelle : ses calques sont des images entières à la taille de l'aperçu, × 2.

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Contour extérieur | 158 × 220 à 348 × 484 | 696 × 968 | PNG transparent hors de la silhouette | 1 |
| Bande de type (bordure intérieure) | idem | 696 × 968, centre transparent | PNG | 5 (Unit, Building, Spell, Gear, Hero), ou 1 en gris teintée |
| Liseré du joueur (carte Hero) | idem | 696 × 968, centre transparent | PNG | 2 (A, B), ou 1 en gris |
| Panneau intérieur | idem | 696 × 968 | PNG | 1 |
| Fond d'en-tête | ≈ 144 × 42 à 317 × 92 | 634 × 184, ou intégré au panneau | PNG | 1 |
| Cadre d'illustration | ≈ 144 × 50 à 317 × 110 | 634 × 220, ou intégré au panneau | PNG, centre transparent | 1 |
| Bandeau de type | ≈ 144 × 18 à 317 × 40 | 634 × 80, ou intégré au panneau | PNG | 1, ou 5 si teinté par type |
| Fond de la zone de texte | 144 × 84 à 317 × 185 | 634 × 370, ou intégré au panneau | PNG | 1 |

Zones à laisser libres pour Godot, mesurées sur la carte de 158 × 220 : marge extérieure 7 px ; en-tête de 42 px de haut (coût à gauche, nom, Force ou PV à droite) ; illustration sur la hauteur restante ; bandeau de 18 px (icône de type, libellé, vitesse) ; texte de 84 px de haut ; 4 px entre les zones. Ces cotes suivent la mise en page actuelle et se recaleront sur la maquette de carte validée.

**Badges** : formes carrées sur fond transparent, chiffre posé par Godot dans une zone centrale libre d'au moins 60 % du côté.

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Goutte du coût | 34 à 75 | 160 × 160 | PNG ou SVG | 1 |
| Losange de la Force | 42 à 92 | 192 × 192 | PNG ou SVG | 1 (la couleur du chiffre change, pas la forme) |
| Cœur des PV | 46 à 101 | 208 × 208 | PNG ou SVG | 1 |
| Pastille d'ordre (pile, ordre des déclencheurs) | 22 | 48 × 48 | PNG ou SVG | 1 |

**Étiquettes** (nine-patch horizontal, hauteur fixe, largeur selon le texte) :

| Élément | Hauteur affichée | Hauteur du maître | Marges fixes du maître | Variantes |
| --- | --- | --- | --- | --- |
| Mot-clé | ≈ 14 à 31 | 62 | gauche et droite 12, haut et bas 8 | 2 (sur fond clair, sur fond foncé), ou 1 en gris |
| « Pouvoir · N » du Hero | idem | 62 | idem | 1, ou la même que le mot-clé |
| Vitesse « Réaction » ou « Action » (facultatif) | icône de 12 à 31 | 64 × 64 | — | 2 |

**Icônes de type** : grille source de 24 × 24 (celle de `DuelIcons`), une seule couleur, sans texte. Affichées à 12 et 14 px dans les bandeaux, 30 et 40 px en remplacement d'illustration, jusqu'à 88 px dans l'aperçu. Maître : SVG 24 × 24, ou PNG 192 × 192 blanc sur transparent à teinter. Variantes : Unit, Building, Spell, Gear, Hero.

**Dos, défausse et états** :

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Dos de carte, grand (pioche) | 158 × 220 | 316 × 440 | PNG | 2 (A, B), ou 1 et un liseré en gris |
| Dos de carte, petit (main adverse) | 50 × 70 | 100 × 140 | PNG, version simplifiée du grand si ses détails disparaissent | idem |
| Plaque du nombre de cartes | ≈ 80 × 76 | nine-patch 160 × 152, marges 16 | PNG | 1 |
| Emplacement de défausse vide | 158 × 220 | 316 × 440 | PNG | 1 |
| Ombre de survol | 158 × 220 + 12 px de débord par côté | 364 × 488 | PNG transparent | 1 |
| Anneau de survol, jouable, choisi | autour de 158 × 220 ; trait de 3 px, écart de 1 px entre deux anneaux | nine-patch, trait de 6 px, marges 20 | PNG | 2 formes (simple, double), teintées par Godot |
| Carte inactive | — | aucun fichier : transparence réglée par Godot | — | — |

**Illustrations** : figure détourée sur fond transparent, dans une toile carrée, affichée entière et centrée dans sa zone (`TextureRect`, garder les proportions). Ce format sert à la fois la zone large de la carte et la zone de la pièce, sans recadrage.

| Élément | Plus grand affichage | Fichier maître | Format | Contraintes |
| --- | --- | --- | --- | --- |
| Hero, portrait et grand format | ≈ 420 px de haut (affiches de relais et de fin) | 1024 × 1024 | PNG RGBA détouré | sujet entier dans les 90 % centraux ; lisible réduit à 40 px de haut |
| Carte et jeton | ≈ 176 px de haut (aperçu) | 512 × 512 | PNG RGBA détouré | sujet entier dans les 90 % centraux ; lisible réduit à 40 px de haut |

Si une illustration est une scène pleine plutôt qu'une figure détourée, elle doit couvrir la zone d'illustration au rapport largeur sur hauteur de la carte : ≈ 2,9 pour 1 aujourd'hui, 1,7 pour 1 dans la maquette V3. La pièce en recadre le centre.

Nombre : 2 Heroes ; 9 Units, 3 Buildings, 4 Spells, 1 Gear, 2 jetons. Si Units, Buildings et jetons changent selon le champion, ces 14 illustrations sont à faire en deux versions : **21 ou 35 illustrations au total**.

## 3. Le plateau et les pièces

| Élément | Taille affichée | Fichier maître | Format | Variantes et découpe |
| --- | --- | --- | --- | --- |
| Fond de table | 1920 × 1080, plus large sur un écran plus allongé | 3840 × 2160, rien d'essentiel à moins de 10 % des bords ; ou texture répétable 512 × 512 et calque de lumière 3840 × 2160 | Opaque, import Lossy | 1 |
| Cadre du plateau | ≈ 747 × 747 (grille de 731 × 731 et 8 px de bord) | 1494 × 1494, centre transparent | PNG | 1 ; repères de camp (bords, coins) en calques séparés, en gris, si teintés |
| Tuile de case | 143 × 143 | 286 × 286 | PNG opaque | 2 à 3 variantes pour casser la répétition |
| Joints entre cases | 4 px | aucun fichier : fond du plateau | — | — |
| Repères A à E et 1 à 5 | zone de 20 px | aucun fichier : texte | — | — |
| Survol de case | 143 × 143 | 286 × 286 | PNG transparent | 1 |
| Case proposée : bordure | 143 × 143, trait de 4 px | 286 × 286, trait de 8 px | PNG transparent | 1, teintée |
| Case proposée : point central | 16 de diamètre | 32 × 32 | PNG transparent | 1, teinté |

**Pièce** (composant `PieceView`) : **129 × 129**, à 7 px du bord de sa case. Elle n'est jamais agrandie (l'aperçu montre la carte) : maître à 258 × 258.

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Contour et liseré du joueur | 129 × 129 | 258 × 258 | PNG | 2 (A, B), ou 1 en gris |
| Bande de type | 129 × 129, centre transparent | 258 × 258 | PNG | 5, ou 1 en gris |
| Panneau intérieur (en-tête, illustration, bandeau) | 129 × 129 | 258 × 258 | PNG | 1 |
| Onglet du Gear attaché | 129 × 23 | 258 × 46 | PNG | 1 |
| Anneaux de sélection | 143 × 143 (pièce et 7 px), trait de 3 px | 286 × 286, trait de 6 px | PNG transparent | 2 formes (simple, double), teintées : survol, proposé, choisi |
| Badges | 42 (Force), 46 (PV) | ceux de la carte | — | — |

Zones libres de la pièce, relevées sur capture : en-tête ≈ 36 px, illustration ≈ 113 × 44, bandeau ≈ 18 px. Le jeton utilise le même cadre.

## 4. Le reste de l'écran

**Sources et compteurs**

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Source redressée | 74 × 106 | 148 × 212 | PNG | liseré A, B (ou 1 en gris) |
| Source inclinée | 74 × 106 | 148 × 212 | PNG, ou la redressée estompée par Godot | 1 |
| Emplacement vide | 74 × 106 | 148 × 212 | PNG | 1 |
| Icône d'Essence | 30 sur la Source, ≈ 18 dans le compteur | 64 × 64, ou SVG 24 × 24 | PNG ou SVG | 1 |
| Bouton « Recycler +1 » | 66 × 26 | nine-patch, hauteur 52, marges 10 | PNG | 4 états (normal, survol, enfoncé, désactivé) |
| Plaque de compteur (Essence, Réserve, Fonte) | hauteur ≈ 30, largeur selon le texte | nine-patch, hauteur 60, marges 12 | PNG | 2 (accent pour l'Essence, neutre) |
| Icônes Réserve et Fonte (facultatives) | ≈ 18 | 48 × 48, ou SVG 24 × 24 | PNG ou SVG | 2 |

**Colonne de duel** (220 × 731, taille fixe)

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Panneau de la colonne | 220 × 731 | 440 × 1462 | PNG | 1 |
| Plaque de pendule | 200 × ≈ 118 | nine-patch 400 × 236, marges 16 | PNG | vive A, vive B, estompée (ou 1 en gris) |
| Barre de temps : piste et remplissage | 6 de haut, ≈ 176 de large | nine-patch, hauteur 12, marges 6 | PNG | piste 1 ; remplissage 1 en gris |
| Pastille A ou B | 20 × 20 | 40 × 40 | PNG | 1 en gris, lettre en texte |
| Grand bouton (« Terminer le tour », « Passer », « Confirmer ») | 200 × 64 | nine-patch 400 × 128, marges 20 | PNG | 4 états × 2 joueurs, ou 4 états en gris teintés |
| Bouton « Abandonner » | 200 × ≈ 28 | nine-patch, hauteur 56, marges 10 | PNG | 4 états |
| Encart de consigne | 200 × 44 minimum | nine-patch, hauteur 88, marges 16 | PNG | 1 |
| Entrée de pile | ≈ 200 × 36 | nine-patch, hauteur 72, marges 16 | PNG | teinte du type et liseré du joueur, en gris teintés |
| Décompte de la fenêtre de réponse | barre de 6 de haut | la barre de temps | — | — |

**Panneaux et écrans**

| Élément | Taille affichée | Fichier maître | Format | Variantes |
| --- | --- | --- | --- | --- |
| Rideau de relais | 1136 × 220 aujourd'hui ; ≈ 980 × 580 dans la maquette V3 | nine-patch, marges 40 | PNG | liseré A, B |
| Affiche de fin | ≈ 480 × 290 aujourd'hui ; ≈ 980 × 580 dans la maquette V3 | nine-patch, marges 40 | PNG | victoire A, victoire B, égalité |
| Zone de portrait des affiches | ≈ 400 × 512 | illustration Hero 1024 × 1024 | — | — |
| Confirmation d'abandon | ≈ 480 × 240 | le panneau des affiches | — | — |
| Boutons des panneaux | 200 × 56 et 160 × 56 | nine-patch 400 × 112, marges 20 | PNG | 4 états ; principal et secondaire |
| Voile sombre | plein écran | aucun fichier : couleur | — | — |
| Panneau de préparation | ≈ 624 × 405, 560 de large au moins | nine-patch, marges 40 | PNG | 1 |
| Champ de saisie (graine) | 300 × ≈ 40 | nine-patch, hauteur 80, marges 12 | PNG | normal, focus, désactivé |
| Bouton « Commencer » | 560 × 64 | le grand bouton | — | — |
| Infobulle | hauteur ≈ 28, largeur selon le texte | nine-patch, hauteur 56, marges 10 | PNG | 1 |

## 5. Textures répétables

À répéter sans raccord visible ; import avec la répétition activée.

| Élément | Fichier maître | Format |
| --- | --- | --- |
| Grain des surfaces claires | 256 × 256 | PNG, transparent ou opaque |
| Texture de bordure (bande de type) | 32 × 32 | PNG en gris, teinté par Godot |
| Texture d'ombre ou de fond d'illustration | 16 × 16 | PNG transparent |

## 6. Polices

| Sujet | Exigence |
| --- | --- |
| Nombre | 2 familles au plus : titres et chiffres, textes de règles. |
| Format | TTF, OTF ou WOFF2. |
| Licence | Usage commercial et incorporation dans un jeu autorisés (SIL Open Font License, par exemple). |
| Caractères | Latin de base et accents du français, `œ`, `«` `»`, `’`, `·`, `−` (signe moins), `…`, chiffres tabulaires pour les pendules. |
| Graisses | Au moins régulière et grasse pour les textes ; grasse ou noire pour les titres. |
| Tailles utilisées | 11 à 44 px dans le thème actuel ; jusqu'à ≈ 90 px sur les affiches. Le texte des cartes est agrandi 2,2 fois dans l'aperçu : import en MSDF à envisager pour rester net. |

## 7. Récapitulatif

| Famille | Fichiers (avec teinte par Godot) | Fichiers (une couleur par fichier) |
| --- | --- | --- |
| Carte : calques, badges, étiquettes, icônes, dos, états | ≈ 22 | ≈ 40 |
| Plateau et pièce | ≈ 12 | ≈ 22 |
| Sources, compteurs, colonne, panneaux, écrans | ≈ 22 | ≈ 45 |
| Textures répétables | 3 | 3 |
| Illustrations | 21 ou 35 | 21 ou 35 |
| Polices | 2 familles | 2 familles |
