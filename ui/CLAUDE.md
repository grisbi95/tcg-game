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
