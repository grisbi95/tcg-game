# Bible visuelle

> **Rôle** : identité graphique du jeu, en une page. Fait foi pour toute maquette, tout asset et tout habillage de `ui/`, aux tailles de la [fiche technique de l'écran de duel](../fiches/ecran-de-duel.md) (décisions 0051 à 0053). **Statut : charte de référence, choisie par le créateur le 26 octobre 2026 (décision 0070, option « Vestiaire »)** ; brouillon du 21 octobre 2026, repris à l'étape 2b.4. Les recherches Midjourney du créateur peuvent affiner illustrations, matières et teintes sourdes, mais pas les invariants (palette de jeu, fond sombre, coins coupés, encre, ombres en aplat, aucun texte dans l'image, polices, tailles de la fiche).

## Intention

Un tournoi dont on ne sait rien, où des champions venus de tous les genres s'affrontent sur un sol de 5 × 5 cases. Le calme d'une partie d'échecs, la chaleur d'une table entre amis. Ton sérieux et sobre, avec une pointe de malice. Aucun lore : le joueur est tiré par le jeu, comme dans le donjon de Slay the Spire.

**Règle d'or : l'unité vient du traitement graphique, la variété vient du casting.** Un robot et un zombie se rencontrent naturellement parce qu'ils sont dessinés au même trait, sur le même papier, sous la même lumière.

## Références

| Référence | Ce qu'on en retient | Ce qu'on n'en reprend pas |
| --- | --- | --- |
| Slay the Spire | lisibilité, casting hétéroclite sans explication, silhouettes fortes | ses personnages, ses cadres, son univers |
| Label 619, Mathieu Bablet et Guillaume Singelin (*Frontier*, *Carbone & Silicium*, *Shin Zero*) | encrage noir épais, aplats, proportions trapues, atmosphères à peu de couleurs | leurs personnages et leurs images ; jamais « à la manière de » un auteur dans un prompt |
| Le catch et les tournois | cérémonial : annonce, fiche de combattant, affiche de résultat | la violence, le décor de salle |

## Casting

Chaque champion est un Hero du catalogue (`ruleset/50-cartes/heroes.md`) : une forme dominante, un accessoire décalé et une teinte sourde d'illustration, tirée de la couleur de son deck. Les Units de son deck reprennent sa forme. Les liens mécaniques sont des pistes : cartes, Heroes et decks appartiennent au ruleset.

| Hero | Deck, couleur | Forme | Accessoire | Teinte | Piste |
| --- | --- | --- | --- | --- | --- |
| Chef de guerre | Percée, rouge | carré massif, masque | serviette de vestiaire | brique `#b0644e` | réveille une Unit, assaut |
| Recruteuse | Phalange, vert | rectangle vertical, trapu | arrosoir | vert-de-gris `#7d9c95` | crée des jetons |
| Stratège | Échiquier, violet | diagonale penchée, bras ballants | costume impeccable, nœud papillon | lilas éteint `#9a8cab` | échange les cases |
| Pilleuse | Grimoire, bleu | triangle, cape | jeu de cartes qui fume | bleu nuit `#4f5f86` | pioche |

Personnages : environ trois têtes de haut, tête large, corps compact, visage impassible, un seul détail décalé. Lisibles en silhouette à la taille d'une pièce (125 px, case de 139 px).

## Palette

Fond sombre et chaud, pour le confort à l'écran ; plateau et cartes en papier. Les couleurs franches sont réservées à ce qui se joue.

| Rôle | Valeur |
| --- | --- |
| Table, panneau, alvéole | `#1c1916`, `#26221d`, `#2f2a24` |
| Sol de l'arène | `#3d362e` au centre, `#2b2620` au bord |
| Encre | `#15120f` |
| Papier, papier ombré, papier sombre | `#efe5cf`, `#e0d3b6`, `#c7b896` |
| Gris chauds | `#8b8274`, `#5c554b` ; texte clair sur fond sombre `#cdbfa6` |
| Joueur A, joueur B (franches, 0027) | `#2f6fd6`, `#d43b2f` ; le rouge ne sert qu'au joueur B |
| Essence, surligné (franches) | `#f4c542` |
| Choisi (franche) | `#57c77a` |
| Force au-dessus, en dessous (sur papier) | `#2d7a2f`, `#b0560f` |
| Teintes de type (sourdes, modifient 0027) | Unit `#a8b88f`, Building `#cfae74`, Spell `#9ea6c4`, Gear `#c98f72`, Hero `#c79aa3` |

La teinte de type colore la bande hachurée du cadre ; la teinte du champion colore le fond de l'illustration.

## Formes et matières

- Coins coupés partout, jamais de coin arrondi. Trait d'encre de 2 à 4 px à la taille réelle.
- Ombres en aplat d'encre décalé, jamais floues. Aucun dégradé, sauf la lumière de l'arène, qui tombe d'en haut.
- Matières : papier légèrement grainé, hachures dans les cadres, trame de points dans les ombres et les fonds d'illustration.
- Un emplacement vide est une alvéole creusée, jamais un pointillé.

## Typographie

Deux familles au plus (`ui/CLAUDE.md`), sous licence libre (OFL) : **Archivo**, grotesque grasse pour les titres et les chiffres (chiffres de même largeur), et **Source Serif 4** pour les textes de règles (0070). Mots-clés et bandeaux en capitales espacées. Rôles et tailles : fiche technique, § 6.

## États

Normal, survol (soulèvement et ombre plus grande), surligné (anneau jaune et point dans une case libre), choisi (deux anneaux verts), désactivé (estompé, bord gris). Le liseré du joueur reste toujours visible. Forme et couleur portent chaque état ; le daltonisme reste à trancher.

## Cérémonial

Le relais est une annonce (« Au tour du Chef de guerre »), la carte Hero une fiche de combattant, la fin de partie une affiche de résultat. La malice tient en une phrase, jamais plus.

## Interdits

Coins arrondis uniformes, dégradés bleus ou violets, pilules et cartes de tableau de bord, style par défaut de Godot, pointillés, emoji, heroic fantasy (chevaliers, dragons épiques), faux texte dans une image, mélange de familles d'icônes, prompt « à la manière de » un auteur vivant.

## Pour aller plus loin

Maquette de référence : [ecran-de-duel-da-vestiaire.html](../maquettes/ecran-de-duel-da-vestiaire.html). Demander un asset à une IA : [instructions-ia.md](instructions-ia.md).
