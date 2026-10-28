# 0068 — Assistant d'annonce pour la sélection en plusieurs temps

- Statut : acceptée
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : `ui/` (`DuelSelection`, `SelectionCandidates`, nouvel objet d'annonce, composants de vue), étape c.7 du jalon J2c

## Contexte

`DuelSelection` (0023, 0024, 0031) est une machine à états (IDLE, CARD_CHOSEN, PIECE_CHOSEN, TARGET_PENDING) qui fait une annonce en un geste après la carte (une cible au plus) et l'émet dès qu'elle est complète, sans confirmation, si `DuelEngine.validate()` l'accepte. L'étape c.7 demande des annonces en plusieurs temps : X d'un Spell à coût X puis ses cibles (213.1.9), deux cibles à la suite (échange 214, déplacement 215 ; 0056), l'Ordre du Hero (211, 0055 : pas une carte de la main). Elle demande aussi de répondre à deux choix posés pendant une résolution (0057) : CHOOSE_DISCARD (212) et CHOOSE_TOP_CARD_PLACE (217, Observatoire ; carte regardée cachée à l'adversaire, 201.4.1a, 217.1.5). Dettes « haute » du backlog ciblant c.7.

Contraintes : aucune règle dans `ui/`, le moteur seul juge la légalité ; annonce émise dès qu'elle est complète (0031) ; Web ; déterminisme. Expiration du temps pendant un choix d'annonce : annonce abandonnée, rien payé (209.4.4h, 209.4.11, 209.4.11b, 209.4.11c, 211.2.2a : le Hero reste éveillé ; ruleset 0.56, décision de design 0254).

## Options envisagées

- A. Agrandir `DuelSelection` : nouveaux états (X en attente, deuxième cible en attente, Ordre choisi) ; X par un sélecteur « − 1 + » dans la colonne du centre ; défausse par clic dans la main comme au mulligan ; Observatoire par deux boutons « Garder dessus » / « Mettre dessous ». Bénéfice : un seul endroit, dans la ligne de 0024 et 0031, le moins de travail. Coût : le fichier grossit (environ 300 à 450 lignes). Limite : chaque nouvelle forme de choix ajoute une étape au même fichier.
- B. Un panneau de choix unique, par-dessus l'écran, qui liste en boutons tout ce qui n'est ni case ni pièce (X, carte à défausser, dessus/dessous, quel Ordre) ; le plateau ne sert qu'aux cibles. Bénéfice : un composant réutilisable, simple à construire et tester. Coût : moins direct (X en liste de boutons, défausse en liste de noms). Limite : le panneau cache une partie du plateau.
- C. Un assistant d'annonce séparé : quand le joueur commence une annonce (carte de la main ou Ordre du Hero), un petit objet dédié demande les étapes une à une dans l'ordre que donne la carte (X, puis chaque cible), puis émet l'intention ; `DuelSelection` lui confie le travail. Les choix de résolution (défausse, regard) gardent les gestes de A. Bénéfice : code découpé et court, une carte à X puis cibles ou à plusieurs cibles marche sans rien ajouter. Coût : plus de travail maintenant, `DuelSelection` en partie remaniée. Limite : deux objets à faire dialoguer, à bien tester.

Recommandation présentée : C.

## Décision

Option C ; A et B écartées. Choix du créateur, en conversation, le 2026-10-27. Gestes retenus : X par « − 1 + » dans la colonne du centre (borné par ce que le moteur accepte), défausse par clic sur la carte dans la main, Observatoire par deux boutons, Ordre lancé depuis le Hero.

## Conséquences et vérification

- Un objet d'annonce dans `ui/` (`RefCounted`, sans règle) interroge le moteur par `SelectionCandidates` et `validate()`, enchaîne X puis cibles et n'émet qu'une intention légale.
- `DuelSelection` lui délègue les annonces et garde les choix de résolution et les autres gestes. Annuler abandonne l'annonce sans rien envoyer.
- L'expiration du temps pendant l'annonce l'abandonne, rien payé (209.4.11, 211.2.2a : le Hero reste éveillé).
- La carte regardée (Observatoire) n'est montrée qu'à son joueur (201.4.1a, 217.1.5).
- Un composant de vue réutilisable par geste nouveau dans `ui/components/`, avec sa scène d'essai ; tests GdUnit4 nommés par identifiant de règle.
- Vérification : un duel local joue chacune des interactions à l'écran (sortie de c.7).
- Réexamen : si une carte demande une forme d'annonce que l'assistant ne sait pas enchaîner, ou si l'IA (J4) a besoin de la même construction d'annonce hors de la vue.

## Références

- Décisions 0023, 0024, 0031, 0055, 0056, 0057, 0058 ; `docs/roadmap.md`, c.7 ; `docs/backlog.md` (dettes c.7).
- Ruleset 0.56 ; 209.4.4h, 209.4.11 à 209.4.11c, 211.2.2a, 212, 213.1.9, 214, 215, 217, 201.4.1a ; décision de design 0254.
