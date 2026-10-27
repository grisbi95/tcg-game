# Instructions de référence pour l'IA

> **Rôle** : comment demander un asset à un outil de génération d'images (Midjourney ou autre) pour qu'il respecte la [bible](bible.md) et les tailles de la [fiche technique](../fiches/ecran-de-duel.md) (§ 7). Direction retenue : A « Vestiaire » (décision 0070), maquette de référence [ecran-de-duel-da-vestiaire.html](../maquettes/ecran-de-duel-da-vestiaire.html). **Statut : version 1 du 26 octobre 2026**, à affiner par les recherches du créateur dans le cadre des invariants ci-dessous.

## 1. Invariants

Une recherche peut changer le trait, la matière ou les teintes sourdes. Elle ne change pas ceci sans nouvelle décision :

- couleurs franches réservées au jeu : joueur A `#2f6fd6`, joueur B `#d43b2f`, Essence et surligné `#f4c542`, choisi `#57c77a` ; aucune illustration ne s'en sert comme couleur dominante ;
- fond sombre et chaud, papier et encre ;
- coins coupés, trait d'encre, ombres en aplat, aucun dégradé hors de la lumière de l'arène ;
- aucun texte, chiffre ni lettre dans une image : Godot les pose ;
- tailles et formats de la fiche et de la décision 0051.

## 2. Bloc de style commun

Les outils comprennent mieux l'anglais ; ce bloc se colle en fin de chaque demande.

```text
flat illustration, thick black ink outline, flat colors, limited muted palette, warm paper texture,
subtle halftone dots in shadows, hard offset shadow, chunky stocky proportions, about three heads tall,
large head, deadpan expression, one quirky accessory, strong readable silhouette, centered, plain background
```

À exclure (paramètre `--no` de Midjourney, ou « negative prompt » ailleurs) :

```text
text, letters, numbers, watermark, signature, frame, border, gradient, glow, blue purple gradient,
rounded corners, photorealistic, 3d render, epic fantasy, knight, armor, emoji
```

Jamais de nom d'auteur ou d'artiste vivant dans une demande (bible, Interdits). Pour garder un même trait d'une image à l'autre, réutiliser une image déjà validée comme référence de style (`--sref` dans Midjourney) plutôt qu'un nom.

## 3. Par famille d'assets

| Famille | Fichier (fiche § 7) | Format à demander | Consignes propres |
| --- | --- | --- | --- |
| Illustration de carte ou de jeton | `cards/art/<id>.webp` | carré, `--ar 1:1`, livré en 1024 au plus | un seul personnage ou objet, entier, dans les 90 % centraux ; fond uni de la teinte du champion ou de la teinte de type ; lisible réduit à 40 px de haut ; affiché en entier, jamais recadré, à deux tailles : 110×110 px sur la pièce, 142×142 px sur la carte en main (312×312 en aperçu à ×2,2), trait d'encre compris |
| Illustration du Hero | `cards/art/<id>.webp` | carré, `--ar 1:1`, 1024 | portrait en pied, plus soigné : sert aussi à la pièce Hero et à l'aperçu (348×484) |
| Fond de table | `ui/table.webp` | `--ar 16:9`, ramené à 1920×1080 | matière seule (papier sombre, bois ou feutre chaud), très peu de contraste, lumière venant d'en haut au centre ; aucun objet sous le plateau (x 615 à 1326, y 98 à 809), ni sous les mains et les Sources |
| Matières (papier, trame, hachures) | servent à fabriquer cadres, cases, panneaux | carré, motif répétable (`--tile` dans Midjourney) | grain léger ; la teinte se règle ensuite, pas dans la demande |
| Cadres, cases, boutons, panneaux, Sources | `ui/*.png`, `cards/frames/*.png` | **pas d'IA pour la forme** | ils doivent tomber au pixel près pour le découpage en 9 parties ; ils se dessinent en vectoriel (SVG ou outil de dessin) avec une matière générée ci-dessus |
| Icônes | `icons/*.svg` | **pas d'IA** | une seule famille, grille 24×24, une couleur (blanc, teinté par le jeu) |

## 4. Après la génération

1. Choisir l'image, la recadrer au carré ou au 16:9, la réduire à la taille de la fiche (le double de la plus grande taille affichée, 1024 px au plus).
2. Vérifier : aucun texte, silhouette lisible à 40 px, aucune couleur franche du jeu en dominante.
3. Enregistrer en WebP sous le nom exact de la fiche (`recrue.webp` pour la carte `recrue`).
4. Ajouter sa ligne à `assets/REGISTRE.md` : outil (par exemple « Midjourney v7 »), date, demande complète, droits (conditions de l'abonnement utilisé), statut `provisoire`.

## 5. Exemples

Recrue (Unit, Force 2), teinte de type Unit :

```text
a small stocky young wrestler in an oversized training towel, square massive body, simple mask,
standing still, olive green plain background, <bloc de style commun> --ar 1:1 --no <exclusions>
```

Stratège (Hero), teinte du deck violet :

```text
a stocky strategist leaning diagonally, arms dangling, impeccable suit and bow tie, full body,
calm, faded lilac plain background, <bloc de style commun> --ar 1:1 --no <exclusions>
```

Ces exemples ne fixent pas le casting : cartes et Heroes appartiennent au ruleset, la bible en donne seulement des pistes.
