# 0042 — Mesures de la fenêtre de réponse journalisées

- Statut : acceptée ; modifiée par le ruleset 0.38 (décision de design 0199) le 2026-10-21 : le temps de fenêtre se compte de l'ouverture au geste du joueur, sans échéance ni passe automatique ; une réponse commencée se compte une fois par occasion de répondre (entrée au sommet de la pile), même si la fenêtre se ferme et se rouvre après une production d'Essence (203.6, décision 0026).
- Date : 2026-10-21
- Décideur : créateur du projet
- Périmètre : journal du duel (`DuelJournal`, `app/`), hôte (`DuelHost`), relevé de playtest (`PlaytestRecorder`, étape 2.5)

## Contexte

La fiche de relevé du protocole de playtest (`docs/ruleset/70-playtest/protocole.md`, décision de design 0198 du ruleset) demande, pour chaque joueur, le nombre de réponses commencées pendant une fenêtre de réponse (208.6.5) et les secondes de pendule consommées par les fenêtres de réponse qu'on lui montre, y compris quand il passe automatiquement (208.6.2, 208.6.3, 209.4.4g). Ces deux faits n'existent que dans `DuelHost` (0029 : l'hôte décompte la fenêtre ; `begin_response()` arrête le décompte). Le journal (0022) ne garde que la préparation, les intentions acceptées et le temps écoulé, sans distinguer le temps passé dans une fenêtre. La roadmap notait cette décision à prendre avec l'étape 2.5. Contraintes : aucune règle ne change et 208.6.2 reste PROVISOIRE ; déterminisme et replay (0001, 0022) ; aucun fait de jeu par `AppEvents` (0006) ; Web sans thread.

## Options envisagées

- Option A : journaliser les faits de l'hôte. Le journal passe au format 2 avec deux entrées de plus : temps écoulé pendant la fenêtre de réponse d'un joueur, et réponse commencée par un joueur. Le replay traite la première comme du temps ordinaire et ignore la seconde. `PlaytestRecorder` lit tout dans le journal rejoué dans un moteur neuf : la fiche se produit après coup depuis un fichier, pour toute partie enregistrée. Bénéfice : une seule source de vérité, fiche reproductible et testable, cohérent avec 0022 qui prévoyait le journal pour les fiches. Coût : version 2 du format, codec des entrées, fixture de replay régénérée, ordre de comptage à régler dans l'hôte quand une fenêtre échoit. Limite : le temps entre la dernière image et le clic « répondre » n'est pas compté comme temps de fenêtre, à une image près.
- Option B : compteurs dans l'hôte, relevé en direct. `DuelHost` tient deux compteurs par joueur ; l'écran nourrit `PlaytestRecorder` à chaque lot d'événements et lit les compteurs à la fin. Bénéfice : journal et fixture inchangés, moins de code. Coût : la fiche n'est pas reproductible depuis un journal ; l'hôte porte un état hors journal, deux façons de savoir ce qui s'est passé. Limite : le relevé dépend du flux de l'écran, tests plus lourds, aucune fiche pour une partie rejouée.
- Option C : colonnes vides en 2.5, mesures relevées plus tard. Bénéfice : rien à changer dans l'hôte ni le journal. Coût : la première série du jalon J3 ne mesure pas 208.6.2, ce que le protocole attend de la version sur écran. Limite : une décision de plus avant J3.

## Décision

Option A, recommandée et choisie par le créateur le 2026-10-21. Le ruleset ne change pas.

## Conséquences et vérification

- `DuelJournal.FORMAT_VERSION` passe à 2 ; une entrée est l'une de : intention acceptée, temps écoulé (`elapsed_msec`), temps écoulé pendant la fenêtre de réponse d'un joueur (`response_window_elapsed_msec` et `player`), réponse commencée (`response_begun` et `player`). Les temps consécutifs de même sorte et de même joueur se cumulent ; un temps de fenêtre et un temps ordinaire ne se cumulent pas entre eux. Un journal de format 1 est refusé au chargement, comme le prévoit 0022.
- La fiche CSV suit le modèle du protocole ; son en-tête porte en plus la graine de la partie, pour la rejouer depuis son journal.
- `DuelHost` écrit le temps de fenêtre quand le décompte court pour le joueur attendu (temps compté jusqu'à l'échéance incluse, passe automatique 208.6.3 comprise) et une réponse commencée à chaque `begin_response()` suivi d'effet. Le temps entre la dernière image et le clic n'est pas compté comme temps de fenêtre.
- `replay_into` avance la pendule pour les deux sortes de temps et ignore les réponses commencées : même résultat par déterminisme.
- `PlaytestRecorder` (`app/`) construit la fiche à partir du journal seul, en le rejouant dans un moteur neuf et en lisant l'état entre les entrées ; il ne lit ni l'hôte ni l'écran.
- `tests/fixtures/replay_random_duel.journal.json` régénéré par `tools/record_replay_fixture.gd` (version du format) : écart voulu, à dire dans le rapport ; empreinte inchangée attendue.
- Vérification : tests de `DuelJournal` sur les nouvelles entrées (cumul, refus du format 1, replay), tests de `DuelHost` nommés 208.6.2, 208.6.3 et 208.6.5 sur ce qu'il journalise, tests de `PlaytestRecorder` sur les deux colonnes.
- À réexaminer : si le relevé a besoin d'un fait que l'hôte seul connaît et que le journal ne porte pas, l'ajouter au journal plutôt qu'à l'hôte ; si le format doit être lu hors du jeu.

## Références

Décisions 0001, 0006, 0020, 0021, 0022, 0029, 0040 ; décision de design 0198 du ruleset ; ruleset 208.6.2, 208.6.3, 208.6.5, 209.4.4g ; `docs/ruleset/70-playtest/protocole.md` ; `app/duel_journal.gd`, `app/duel_host.gd` ; `docs/roadmap.md` (étape 2.5).
