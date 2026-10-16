# Vue — consignes locales

Complète le `CLAUDE.md` racine pour `ui/`. Décisions 0001 et 0006 ; patron de vue repris du prototype (sa décision 0010).

## Règles

- Aucune règle du jeu ici. Une vue affiche l'état et émet des gestes (`cell_pressed`, `card_pressed`, `pass_pressed`) ; elle ne construit jamais une intention.
- `DuelSelection` (`RefCounted`, testé sans scène) est une machine à états explicite : `IDLE`, `CARD_CHOSEN`, `PIECE_CHOSEN`, `TARGET_PENDING`, `CONFIRM`. Elle énumère les intentions candidates et ne garde que celles que `engine.validate()` accepte ; les cases et cibles légales affichées en découlent.
- Après `submit()`, `EventPlayer` joue les événements un par un avec `await`, commandes bloquées ; puis chaque vue se recale sur `get_state()`, qui fait foi. Jamais de relecture de l'état dans `_process()`.
- Les valeurs dérivées (Force actuelle, pendule qui tourne) viennent des requêtes en lecture de `DuelEngine`, jamais recalculées.
- `DuelViewModel` par joueur masque main, deck et Écart adverses ; le moteur est omniscient, la vue filtre.

## Composants (`ui/components/`)

`CardView`, `PieceView`, `CellView`, `SourcesView`, `ClockView`, `StackView`, `HoverPreview`, `LogView`. Chacun : une scène, un script du même nom, une méthode `setup(...)` ou `show_*(...)`, des signals au passé, et une scène d'essai `ui/components/_try/try_<nom>.tscn` qui l'instancie seul avec des données factices.

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
