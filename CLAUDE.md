# tcg-game — TCG tactique, Godot 4.7.2, navigateur

## IMPORTANT

- **Le ruleset fait foi.** Copie épinglée dans `docs/ruleset/` (édition dans `RULESET_EDITION`). Un point non tranché par le ruleset ne devient jamais un comportement implicite : arrêter, et le signaler comme question pour `tcg-ruleset`.
- **Une décision avant un système nouveau** : 2 ou 3 options avec compromis, choix du créateur, consignation dans `docs/decisions/`. Décisions acceptées : `0001` à `0007` ; les respecter.
- **GDScript typé partout** : paramètres, retours, variables, collections. Les warnings `untyped_declaration` et `unsafe_*` sont des erreurs à corriger.
- **Un identifiant de règle sur chaque fonction de règle et chaque test** : `# 206.3.6`, `test_206_3_6_tie_destroys_both`.

## 1. Projet

- Duel 1v1 sur un plateau 5×5, Hero sur le plateau, Units, Buildings, Spells, Gear, Essence et Sources, pile et priorité, 5 mots-clés. Chapitres 200 à 210 de `docs/ruleset/20-regles-completes/`.
- Cible : export **Web** d'abord, desktop pour développer. Contraintes Web dès maintenant : rendu GL Compatibility, aucun thread dans le gameplay, pendule indépendante des images rendues.
- Plan et état : `docs/roadmap.md`, seul plan. Jalons J0 amorçage, J1 moteur, J2 jouable, J3 playtest, J4 IA et catalogue.
- Hors périmètre tant que la roadmap ne le dit pas : réseau, comptes, IA avancée, boutique, mobile.

## 2. Stack

- Godot **4.7.2 stable**, GDScript seul, viewport 1920×1080, fenêtre 1280×720, stretch `canvas_items` / `expand`.
- Tests : GdUnit4 6.2.1 dans `addons/gdUnit4/`, headless ; plugin éditeur non activé.
- Lint et format : gdtoolkit 4 dans `.venv/` (`tools/setup_gdtoolkit.sh`), configuration `.gdlintrc`.
- Aucune scène principale ni preset d'export pour l'instant ; `project.godot` ne se modifie que sur demande explicite.

## 3. Architecture (décisions 0001 à 0007)

- **Couches** : `data/` (cartes JSON) ← `rules/` (moteur pur, `RefCounted`, sans Node) ← `ai/` ← `app/` (hôte, horloge, journal) ← `ui/` (scènes). Une couche ne connaît que celles qui la précèdent. `rules/` ne lit jamais l'heure, n'importe aucun Node, ne tire au hasard que par `state.rng`.
- **Flux** : intentions → `DuelEngine.submit(intent) -> Array[DuelEvent]` → événements. Seul le moteur et ses modules modifient `DuelState`. Une intention illégale produit un unique `IntentRejected` avec sa raison et ne change rien. `validate(intent)` est public et pur.
- **Un module de règles par chapitre** du ruleset (`EssenceRules` 203, `ActionRules` 205, `StackRules` 208…) ; carte dans `rules/CLAUDE.md`.
- **État** en classes typées avec `clone()` complet ; identifiants entiers jamais réutilisés ; `PendingDecision` quand le moteur attend un choix d'un joueur (ordre des déclencheurs, cibles) ; `DuelConfig` porte une valeur par règle PROVISOIRE.
- **Paiement** porté par l'intention : `{incliner, recycler}` (0003). **Choix unique** pris par le moteur sans demander (0004).
- **Cartes en JSON** (`data/cards/`), vocabulaire fermé d'`EffectKind` interprété par le moteur ; un nouveau `kind` = code et tests avant toute carte (0002).
- **Vue** : le parent câble ses enfants par `setup(...)` ; les vues émettent des gestes, `DuelSelection` les traduit en intentions par `validate()`, `EventPlayer` joue la file puis chaque vue se recale sur `get_state()`. Aucune règle dans `ui/`, aucun second état faisant autorité.
- **Bus** : un seul autoload `AppEvents`, signals seuls, pour l'application (écrans, audio, réglages) ; les faits de jeu passent par `Array[DuelEvent]` (0006). Aucun autre autoload.
- **Déterminisme** : même état, même graine, mêmes intentions ⇒ même résultat. Journal et replay au jalon J2.

## 4. Pratiques de code

Guide détaillé, pourquoi et signaux d'alerte : `docs/code-guidelines.md` (synthèse des articles de The Shaggy Dev).

- Dépendances vers le bas, d'un seul niveau : jamais `get_parent()`, `../`, `/root/`, ni chemin `$A/B/C` profond. Dire, ne pas demander : appeler `view.show_card(def)`, jamais régler ses labels.
- Composants de vue réutilisables dans `ui/components/`, chacun avec une scène d'essai. Machines à états explicites (`enum` + `match`) pour le moteur, la sélection et l'hôte.
- Noms avec unité (`time_left_msec`), aucune abréviation maison, aucun nombre magique, `enum` pour tout ensemble fixe (ajouter en fin, jamais réordonner), fonctions courtes à une responsabilité, au plus 4 paramètres, DRY dès la deuxième répétition, API de Godot avant le code maison.
- Commentaires rares : identifiant de règle, contournement Godot ou Web. Jamais de paraphrase.
- Identifiants en anglais, commentaires et textes du jeu en français ; `snake_case` fichiers et fonctions, `PascalCase` classes et nodes, `UPPER_CASE` constantes ; signals au passé ; privés préfixés `_` ; `##` sur les contrats publics ; tabulations, lignes de 100 caractères.
- Ordre d'un script : `@tool`, `class_name`, `extends`, doc, signals, enums, constantes, `@export`, variables, `@onready`, built-in, publiques, privées.

## 5. Arborescence

```text
data/cards/      JSON des cartes et Heroes (0002)
rules/           moteur, état, modules par chapitre ; rules/CLAUDE.md
ai/              agents de jeu (J4)
app/             DuelHost, horloge, journal, AppEvents (J2)
ui/              scènes ; ui/components/ ; ui/CLAUDE.md
tests/           suites GdUnit4 ; tests/support/ ; tests/CLAUDE.md
docs/            README (carte), roadmap, decisions/, code-guidelines, ruleset/ (copie)
tools/           run_tests.sh, lint.sh, sync_ruleset.sh, setup_gdtoolkit.sh
.claude/         settings, hooks, agents, skills
```

Créer un dossier au premier fichier qui y entre ; tout autre dossier racine se valide d'abord.

## 6. Fichiers Godot

- Éditer les `.gd` avec `Edit` ou `Write` : le hook reformate puis analyse. Après une édition par terminal, lancer `bash .claude/hooks/check_changed_gdscript.sh` et `tools/lint.sh`.
- Ne jamais inventer un `uid://` ; ne jamais éditer `.uid`, `.import`, `.godot/`, `addons/`, `docs/ruleset/` (copie : passer par `tcg-ruleset` puis `tools/sync_ruleset.sh`).
- Les `.tscn` s'éditent au strict nécessaire et se vérifient en chargeant la scène.

## 7. Commandes

Définir `GODOT_BIN` comme indiqué dans `CLAUDE.local.md`.

```bash
tools/run_tests.sh                          # toutes les suites, échecs et résumé seulement
tools/run_tests.sh res://tests/test_x.gd    # une suite
tools/lint.sh                               # gdformat --check puis gdlint ; --fix pour reformater
python3 .claude/hooks/check_gdscript.py chemin.gd
"$GODOT_BIN" --headless --path . --import   # après un ajout de ressource ou de classe
```

Code de sortie des tests : 0 tout passe, 100 au moins un échec, autre erreur d'exécution. Les deux lignes `ERROR: … remote port … 127.0.0.1:0` sont voulues par GdUnit4. Ne jamais annoncer « tests réussis » sans avoir lancé une suite.

## 8. Définition de terminé

- [ ] `.gd` modifiés passés par le hook ou `check_changed_gdscript.sh`, `tools/lint.sh` propre.
- [ ] Suites pertinentes exécutées et vertes ; une règle nouvelle ou modifiée a son test nommé par identifiant.
- [ ] Pour la vue, scène lancée et comportement vérifié ; pour le moteur, la suite tient ce rôle.
- [ ] Diff relu contre `docs/code-guidelines.md` §8 ; rien hors périmètre.
- [ ] `docs/roadmap.md` à jour si une étape avance ; décision consignée si un système est né.
- [ ] Rapport : contrôles exécutés, échecs, vérifications impossibles.

## 9. Git et sessions

- Branches `feat/`, `fix/`, `docs/`, `chore/` ; Conventional Commits ; jamais de commit ni de push sans demande explicite.
- Une session, une étape de la roadmap. Clore en mettant à jour « État actuel ». Les agents de `.claude/agents/` exécutent avec un brief complet ; la conversation décide. Regrouper les lancements par étape.
- Garder ce fichier sous 150 lignes ; les recettes vivent dans `.claude/skills/` et les `CLAUDE.md` locaux.
