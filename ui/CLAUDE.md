# Vue — consignes locales

Complète le `CLAUDE.md` racine pour `ui/` ; décisions 0023, 0024, 0027 à 0036, 0051 et 0052 ; fiche technique de l'écran de duel : `docs/fiches/ecran-de-duel.md`. Ce que la vue contient et comment elle est câblée : `ui/README.md`.

## Règles

- Une vue ne construit jamais d'intention (racine §3) ; seules `DuelSelection` et ses aides en fabriquent, outils de `_try/` à part. `DuelSelection` (`RefCounted`, testée sans scène, décisions 0023, 0024 et 0031) est une machine à états explicite : `IDLE`, `CARD_CHOSEN`, `PIECE_CHOSEN`, `TARGET_PENDING`. Une annonce part sans confirmation, dès que sa cible est choisie, ou aussitôt sans cible ; seul le mulligan se confirme. `snapshot()` rend ce que les vues surlignent, sans rien en déduire ; `SelectionCandidates` ne garde que ce que `engine.validate()` accepte.
- `EventPlayer` (racine §3) joue les événements un par un avec `await`, commandes bloquées. Jamais de relecture de l'état dans `_process()`, sauf les temps des joueurs (décisions 0021 et 0045), redessinés seulement si son affichage change.
- Style : variations du thème unique `ui/theme/duel_theme.tres` (`theme_type_variation`), jamais de `theme_override` dans une scène. Couleurs fixes dans le thème, recopiées de `DuelPalette` et contrôlées par `test_duel_theme.gd` ; couleurs qui dépendent du joueur par `DuelPalette`, en code.
- Assets (décision 0051) : images, icônes et polices dans `assets/`, cherchées par `DuelAssets` (`ui/theme/`) ; un asset absent garde le dessin actuel (icône du type, tracé de `DuelIcons`, style du thème). Chaque fichier ajouté a sa ligne dans `assets/REGISTRE.md`, contrôlée par `test_assets.gd`.
- Les valeurs dérivées (Force actuelle, temps qui s'écoule) viennent des requêtes en lecture de `DuelEngine`, jamais recalculées. `DuelViewModel` par joueur masque main, deck et Écart adverses : le moteur est omniscient, la vue filtre.
- Composant (racine §4) : un script du même nom que sa scène, `setup(...)` ou `show_*(...)`, scène d'essai `ui/components/_try/try_<nom>.tscn` qui l'instancie seul avec des données factices. Un utilitaire (`RefCounted` sans scène ni essai) vit dans `ui/support/` (`ui/theme/` pour le style, `ui/` pour l'écran) ; seul `CardScaler`, propre à `CardView`, reste à côté d'elle. Un outil de développement appelé par une scène de production (`ScriptedIntentsPlayer`) vit aussi dans `ui/support/`, jamais dans `_try/`, que l'export Web exclura.
- Câblage (racine §3 et §4) : le parent câble ses enfants directs à l'initialisation puis s'efface ; `$Enfant` et `%NomUnique` admis dans la scène possédée. `Control` et `Container` partout ; vérifier le redimensionnement.

## Concevoir un écran

La conception se fait en conversation, avant toute construction par `ui-builder` : une ou deux maquettes HTML autonomes dans `docs/maquettes/` (nommage et règle « jamais réécrite » dans `docs/README.md`, décision 0028), chacune avec ses compromis ; choix du créateur ; décision consignée par `adr-writer` dès que l'écran fixe des cotes ou un comportement, avec les 2 ou 3 options exigées par le `CLAUDE.md` racine ; puis brief pour `ui-builder` (arborescence de `Control` et `Container`, variations de thème, signals, scène d'essai). Repères : les cotes des décisions 0027 à 0036 priment sur toute échelle générale et sur la maquette, en suivant leurs statuts « modifiée par » et « complétée par » ; cotes dans le repère 1920×1080, zones posées par les conteneurs de la fiche technique de l'écran (quatre `CanvasLayer`, `MarginContainer`, `HBoxContainer`, `AspectRatioContainer`, espacements en variations du thème), jamais par code, rendu vérifié aussi en 1280×720 (0035) ; positions fixes là où une décision les cote ; chaque élément interactif a ses états normal, survol, enfoncé et désactivé ; l'appartenance, la Force (0034) et les anneaux reposent sur la couleur seule, le daltonisme reste ouvert (0030, 0032, 0034), à signaler sans le trancher ; peu de polices et de textures. À classer « plus tard », sans en débattre : animations, sons, clavier et manette, tactile, traduction.

## Vérifier avec le MCP `godot-ai` (0011)

Éditeur ouvert sur le projet (racine §2) ; sinon, lancement headless et vérification à l'écran par le créateur, signalée comme non faite.

- Vérifier : `scene_open` puis `project_run` sur la scène d'essai, `editor_screenshot` pour l'image, `logs_read` lus jusqu'au bout, `game_manage` pour arrêter ; `scene_get_hierarchy` et `node_get_properties` pour l'arbre.
- Construire : `node_create`, `node_set_property`, `scene_save` évitent d'écrire un `.tscn` à la main et d'inventer un `uid://`.
- Jamais par le MCP, en plus des interdits de la racine §6 : connecter un signal dans la scène, le parent câble par code.
- Rapport : chaque capture décrite en une phrase, ce qu'elle confirme et ce qui reste à voir à l'écran.
