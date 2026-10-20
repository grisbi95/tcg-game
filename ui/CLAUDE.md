# Vue — consignes locales

Complète le `CLAUDE.md` racine pour `ui/`. Décisions 0001 et 0006 ; patron de vue repris du prototype (sa décision 0010).

## Règles

- Aucune règle du jeu ici. Une vue affiche l'état et émet des gestes (`cell_pressed`, `card_pressed`, `pass_pressed`) ; elle ne construit jamais une intention.
- `DuelSelection` (`RefCounted`, testé sans scène, décisions 0023, 0024 et 0031) est une machine à états explicite : `IDLE`, `CARD_CHOSEN`, `PIECE_CHOSEN`, `TARGET_PENDING`. Une annonce part sans confirmation, dès que sa cible est choisie, ou aussitôt sans cible ; seul le mulligan se confirme. Elle reçoit les gestes (`press_card`, `press_source`…), émet `intent_chosen` avec une intention déjà validée, et `snapshot()` rend un `SelectionSnapshot` : ce que les vues surlignent, sans rien en déduire. `SelectionCandidates` fabrique les intentions candidates et ne garde que celles que `engine.validate()` accepte ; `SelectionTarget` porte une cible. Une Source pressée produit de l'Essence pendant son tour, et prépare le paiement de la réponse pendant le tour adverse. Quand le joueur peut répondre ou passer, une carte choisie ou une Source pressée émet `response_started`, que l'écran transmet à `DuelHost.begin_response()` (décision 0029).
- Après `submit()`, `EventPlayer` joue les événements un par un avec `await`, commandes bloquées ; puis chaque vue se recale sur `get_state()`, qui fait foi. Jamais de relecture de l'état dans `_process()`, sauf la pendule et le décompte de la fenêtre de réponse (`DuelHost.get_response_time_left_msec()`, décision 0029) : ils avancent au temps réel sans événement (décision 0021), et ne se redessinent que si leur affichage change.
- Tailles de police et autres réglages de style : variations du thème unique `ui/theme/duel_theme.tres` (`theme_type_variation`), jamais de `theme_override` dans une scène. Couleurs dans `DuelPalette` (teintes des cinq types, couleurs fixes des joueurs), icônes provisoires tracées en code par `DuelIcons` ; une carte agrandie (aperçu) multiplie les tailles du thème par son échelle, d'après la maquette (décisions 0027 et 0028). Écran (décision 0030) : joueur A toujours en bas, couleurs fixes ; en duel local, la main du bas et les Sources pressables sont celles du joueur qui a l'appareil ; aperçu à l'échelle 2,2 seul, 1,7 avec la carte de son Gear.
- Les valeurs dérivées (Force actuelle, pendule qui tourne) viennent des requêtes en lecture de `DuelEngine`, jamais recalculées.
- `DuelViewModel` par joueur masque main, deck et Écart adverses ; le moteur est omniscient, la vue filtre.

## Composants (`ui/components/`)

`CardView`, `CardBackView`, `PieceView`, `CellView`, `SourcesView`, `ClockView`, `StackView`, `HoverPreview`, `LogView` (bac à sable seulement, décision 0028). Survol, surlignage et choix se marquent par des anneaux (`DuelMarks`) qui laissent visible le liseré du joueur ; un clic sur une pièce est un geste sur sa case (`cell_pressed`, décision 0030), que `DuelSelection.press_cell` rapporte à la pièce quand la case n'est pas proposée. Chacun : une scène, un script du même nom, une méthode `setup(...)` ou `show_*(...)`, des signals au passé, et une scène d'essai `ui/components/_try/try_<nom>.tscn` qui l'instancie seul avec des données factices.

## Câblage

- Le parent câble ses enfants directs à l'initialisation (`setup(...)`, connexions de signals), puis s'efface. Pas de `get_parent()`, de `../`, de `/root/`, ni de chemin profond ; `$Enfant` et `%NomUnique` admis dans la scène possédée.
- Les objets éloignés (écrans, audio) passent par `AppEvents` (signals seuls, `app/`).
- `Control` et `Container` partout ; vérifier le redimensionnement ; thème unique dans `ui/theme/`.

## Vérifier avec le MCP `godot-ai` (0011)

Disponible seulement si l'éditeur est ouvert sur le projet ; sinon, lancement headless et vérification à l'écran par le créateur, signalée comme non faite.

- Vérifier : `scene_open` puis `project_run` sur la scène d'essai, `editor_screenshot` pour l'image, `logs_read` lus jusqu'au bout, `game_manage` pour arrêter ; `scene_get_hierarchy` et `node_get_properties` pour l'arbre.
- Construire : `node_create`, `node_set_property`, `scene_save` évitent d'écrire un `.tscn` à la main et d'inventer un `uid://`.
- Jamais par le MCP : écrire un `.gd` (le hook ne passerait pas, utiliser `Edit` ou `Write`), connecter un signal dans la scène (le parent câble par code), toucher `project.godot`, les autoloads ou `addons/`.
- Rapport : chaque capture décrite en une phrase, ce qu'elle confirme et ce qui reste à voir à l'écran.
