# Guide de conception du code

> **Rôle** : guide de conception du code du jeu (`rules/`, `ai/`, `app/`, `ui/`, `tests/`), hors `addons/`. Il explique le pourquoi et le comment des consignes courtes de [CLAUDE.md](../CLAUDE.md), qui restent la référence impérative ; les [décisions](decisions/) priment sur ce guide. Synthèse adaptée au projet des quatre articles de The Shaggy Dev (voir Sources), relus le 16 octobre 2026.

## 1. Dépendances : vers le bas, et d'un seul niveau

- Un objet ne dépend que de ses enfants directs. Il ne suppose ni parent ni frère : pas de `get_parent()`, de chemin `../`, de `/root/...`, ni de recherche dans l'arbre. `$Enfant` et `%NomUnique` restent acceptables dans la scène possédée.
- Ne pas descendre trop profond : on demande au niveau du dessous (`card_view.show_card(definition)`), on ne règle pas ses labels.
- Le parent commun câble ses enfants à l'initialisation (références, `Callable`, signals), puis s'efface. Chaque enfant reste utilisable seul : chaque composant de `ui/components/` a sa scène d'essai.
- Les nodes ne reçoivent rien par `_init()` : `instantiate()` l'appelle sans argument. Prévoir `setup(...)`.

## 2. Dire, ne pas demander

- Appeler une méthode qui exprime l'intention plutôt que lire l'état d'un autre objet pour le modifier à sa place. Un défaut se cherche à un seul endroit ; plusieurs appelants partagent la même interface.
- Limite propre au projet (décision 0001) : les classes d'état exposent des requêtes en lecture (`can_pay`, `is_cell_free`) ; toute mutation passe par `DuelEngine` et ses modules.
- Piège : la « petite exception, juste cette fois » qui écrit dans un autre objet. Ajouter la méthode manquante.

## 3. Communication par événements

- Un signal est un observateur : l'émetteur annonce un fait sans savoir qui écoute. Objets proches : connexion directe établie par leur parent commun. Déconnecter un écouteur devenu inutile.
- Objets éloignés : l'article recommande un bus d'événements en autoload. Le projet en a **un seul**, `AppEvents` (décision 0006), qui ne porte que des signals d'application : changement d'écran, demande de son, réglages. Il n'a ni variable, ni fonction, ni référence : c'est ce qui le distingue d'un objet dieu. L'autoload `_mcp_game_helper` du plugin Godot AI est de l'outillage de l'éditeur, retiré des exports, que le code du jeu ne référence jamais (décision 0011).
- Les faits de jeu ne passent jamais par ce bus : le flux `Array[DuelEvent]` renvoyé par `submit()` est leur canal unique, joué par `EventPlayer`. Deux canaux pour une même vérité feraient dériver la vue.
- Une vue se met à jour sur événement, jamais en relisant un état distant dans `_process()` ; seule exception, la pendule, qui avance au temps réel (décision 0021).

## 4. Composition, injection, héritage

- Petits objets spécialisés, composés, plutôt qu'un monolithe ou une hiérarchie profonde. Côté vue : `CardView`, `PieceView`, `CellView`, `SourcesView`, `ClockView`, `StackView`, `HoverPreview`. Côté moteur : modules par chapitre et objets de données typés.
- L'héritage est réservé aux objets de même nature : bases `DuelIntent`, `DuelEvent`, `PlayerEvent`. Jamais une couche d'héritage pour raccourcir une fonction.
- Injecter les dépendances (moteur, horloge, catalogue, configuration) par `setup(...)` ou en paramètre. Les modules de `rules/` ne reçoivent que `state`.

## 5. Machines à états

- Dès que des booléens et des `if` imbriqués décrivent « où en est » un objet, une machine à états (`enum` + `match`). Le projet en nomme trois : le moteur (`DuelPhase` et `PendingDecision`), la sélection (`DuelSelection` : `IDLE`, `CARD_CHOSEN`, `PIECE_CHOSEN`, `TARGET_PENDING`), l'hôte (`DuelHost` : `NOT_STARTED`, `AWAITING_HUMAN`, `PLAYING_EVENTS`, `AWAITING_AI`, `RELAY`, `ENDED`).
- Médiateur : `DuelEngine` coordonne les modules de règles ; s'il grossit, il délègue plutôt que de devenir un fourre-tout.
- Référence : Game Programming Patterns, chapitre par chapitre au moment du besoin.

## 6. Lisibilité

- Écrire pour le lecteur humain. Noms descriptifs avec l'unité (`time_left_msec`, `essence_cost`) ; aucune abréviation maison, seulement `i`, `id`, `ui`.
- Pas de nombre magique : constante nommée (`BOARD_SIZE`, `MAX_COPIES_PER_CARD`) ; les valeurs des règles PROVISOIRE vivent dans `DuelConfig`.
- `enum` pour tout ensemble fixe d'options, jamais des chaînes ni des entiers bruts. Piège Godot : un `enum` sérialisé (journal, JSON, `.tres`) s'enregistre en entier ; ajouter en fin, ne jamais réordonner.
- Une fonction fait une seule chose ; au-delà de 10 à 20 lignes, vérifier son rôle. Une coordinatrice appelle des étapes nommées : résoudre un combat = lire les Forces, comparer, détruire, avancer, blesser le Hero.
- Au plus 4 paramètres (`.gdlintrc`). Une liste longue ou des booléens d'option signalent soit des fonctions spécifiques à écrire, soit un objet de données typé (`RefCounted`, jamais un `Dictionary`).
- Commentaires rares : identifiant de règle (`# 206.3.6`, contrainte externe au code), contournement de Godot ou du Web. Un commentaire qui paraphrase signale un nom à améliorer.
- Mise en forme : gdformat ; lignes de 100 caractères, repère de l'éditeur Godot ; lignes vides entre groupes logiques.

## 7. Ne pas se répéter, ne pas réinventer

- Dès la deuxième répétition, extraire, dans l'ordre : fonction locale ; fonction `static` d'utilitaire (`BoardGeometry`) ; classe de base si même nature ; composant sinon.
- D'abord l'API de Godot : `snapped()`, `clampi()`, `Vector2i`, `Array.filter()` et `map()`, `RandomNumberGenerator` à graine.

## 8. Signaux d'alerte en relecture

| Signal | Remède |
| --- | --- |
| Fonction longue aux rôles multiples | Étapes nommées appelées par une coordinatrice (§6). |
| Liste de paramètres longue, ou booléens d'option | Fonctions spécifiques autour d'un noyau commun, ou objet de données typé (§6). |
| Code dupliqué | Extraire selon l'échelle du §7. |
| Objet fourre-tout global, autoload qui accumule | Rattacher chaque donnée à son propriétaire ; `AppEvents` reste signals seuls (§3). |
| Lecture d'un état distant à chaque image | Événements (§3). |
| Parcours de l'arbre vers le haut ou les frères | Câblage par le parent (§1). |
| Booléens d'état qui s'accumulent | Machine à états (§5). |
| Chaîne ou entier codant une option | `enum` (§6). |
| Héritage ajouté pour raccourcir une fonction | Coordinatrice et composition (§4, §6). |
| Commentaire qui paraphrase le code | Renommer ou découper (§6). |
| Abstraction sans besoin actuel | Simplifier (§9). |

## 9. Juste assez de conception

- Concevoir pour ce qui est **requis** : le ruleset et l'étape en cours de `roadmap.md`. Rien pour le hors périmètre.
- Ce qui est **raisonnablement probable** se prépare par un choix peu coûteux : un paramètre, une valeur d'`enum`. Pas une infrastructure.
- Proportionner le soin à l'**impact** : moteur, état et `clone()` méritent de la rigueur ; un callback de bouton, non.
- Itérer : refactoriser au premier point de douleur réel, protégé par les tests, plutôt que viser une architecture parfaite.

## Sources

Articles de The Shaggy Dev, relus le 16 octobre 2026. Écarts assumés : bus réservé à l'application (§3) ; commentaires d'identifiant de règle (§6).

- [Code flexible](https://shaggydev.com/2022/09/13/flexible-code/) (2022) : hiérarchie, dire ne pas demander, composants, injection, patterns, itération.
- [Pattern observateur](https://shaggydev.com/2022/06/01/observer-pattern/) (2022) : signals, connexions directes, bus d'événements.
- [Code propre](https://shaggydev.com/2022/05/04/clean-code/) (2022) : noms, nombres magiques, fonctions, commentaires, formatage, `enum`, DRY, fonctions natives.
- [Code smells](https://shaggydev.com/2023/01/16/code-smells/) (2023) : fonctions et paramètres longs, duplication, objets dieux, sur-ingénierie.
