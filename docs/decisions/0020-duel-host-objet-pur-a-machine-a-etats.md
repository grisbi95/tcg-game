# 0020 — DuelHost, objet pur à machine à états

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : hôte du duel (`app/`, étape 2.1)

## Contexte

L'étape 2.1 du jalon J2 demande un hôte qui fait vivre un duel : intentions humaines, agents d'IA, pendule réelle, journal. Le moteur `DuelEngine` (`rules/`) reste pur : `start_new_duel`, `validate`, `submit`, `advance_clock`, `clock_owners`, `get_state`. La pendule est avancée par l'hôte (0018). Couches `data` ← `rules` ← `ai` ← `app` ← `ui` ; cible Web : aucun thread, pendule indépendante des images.

## Options envisagées

- Option A : `DuelHost` dans `app/`, `RefCounted` sans Node, à machine à états explicite. Testable entièrement sans scène et déterministe en test ; coût : une petite scène pour l'animer.
- Option B : `DuelHost` en Node qui lit l'heure dans `_process`. Moins de pièces ; mais tests avec scène et temps réel, plus lents et moins fiables.

## Décision

Option A, recommandée et choisie par le créateur le 17 octobre 2026.

## Conséquences et vérification

- `enum HostState` : AWAITING_HUMAN, PLAYING_EVENTS, AWAITING_AI, RELAY, ENDED ; l'énum compte aussi NOT_STARTED, ajouté en fin, état avant `start()` ou après une préparation refusée ; ajouts en fin, jamais de réordonnancement.
- L'hôte possède le `DuelEngine`, un contrôleur par joueur (humain, ou agent d'IA de `ai/`), la source de temps (0021) et le journal (0022). La scène qui l'anime (2.3 ou 2.4) lui transmet les faits : `tick()` à chaque image, intention d'un humain, « événements joués », « relais confirmé ».
- Transitions : après des événements (soumission ou pendule) → PLAYING_EVENTS jusqu'à « événements joués » ; puis ENDED si le duel est fini ; sinon le joueur attendu est le premier de `awaited_players()` (les deux joueurs pendant le mulligan, joueur A d'abord). Un agent → AWAITING_AI (le `tick()` suivant demande l'intention à l'agent et la soumet). Un humain différent de celui qui tient l'écran, quand les deux joueurs sont humains → RELAY jusqu'à « relais confirmé » (y compris au début du duel). Sinon AWAITING_HUMAN.
- Une intention humaine n'est acceptée qu'en AWAITING_HUMAN et passe par `DuelEngine.submit()` ; aucune règle dans l'hôte.
- Les agents d'IA partagent une base `DuelAgent` (`ai/`) avec `choose_intent(engine)`, dont hérite `RandomLegalAgent`.
- L'hôte n'émet jamais un fait de jeu par `AppEvents` (0006).
- Vérification : suite de tests de l'hôte sans scène, avec horloge manuelle et agents à graine.
- À réexaminer si le réseau entre dans le périmètre.

## Références

Décisions 0001, 0006, 0018, 0019 ; 0021 (horloge) et 0022 (journal) ; roadmap étape 2.1 ; ruleset 209.4.
