# Rétrospective du jalon J2c — Catalogue de playtest

> **Rôle** : leçons du jalon J2c (décisions 0039 et 0054) : ce qui a marché, ce qui a coûté, où sont les dettes, quelles décisions réexaminer, une chose à changer. Les dettes vivent dans [backlog.md](../backlog.md), les questions de règles dans [02-questions-ouvertes.md](../ruleset/02-questions-ouvertes.md).

Date : 28 octobre 2026. Jalon ouvert le 26 octobre 2026 (PR 48, ruleset 0.45 à 0.52), clos le 28 octobre 2026 (étape c.8). Douze étapes au lieu des huit sessions prévues par 0054, PR 48 à 61, décisions 0055 à 0069, ruleset de l'édition 0.52 à la 0.56.

## Ce qui a marché

- **Le vocabulaire avant les cartes a tenu.** Chaque `kind`, filtre, déclencheur et valeur du jeu a été codé et testé avant la carte qui l'emploie (0002, 0010) ; l'étape c.6 n'a écrit que du JSON : 48 cartes, 4 Heroes et 4 decks en une étape. L'inventaire du vocabulaire (0061) a servi de liste de contrôle à c.5c, c.5d et c.5e.
- **Rien de non écrit n'est devenu implicite.** Les cas que le ruleset ne tranche pas sont refusés par le catalogue et posés en questions ouvertes (Q-156 à Q-163) au lieu d'être devinés dans le code.
- **`RULES_AWAITING_IMPLEMENTATION` est vide** : toutes les règles 0.45 à 0.56 sont citées par un test. La suite est passée de 1 071 cas à la fin de J2 à 1 775 cas et 115 suites, sans orphelin.
- **La recette est mesurable** : duels aléatoires sur les 6 affrontements des 4 decks jusqu'à la victoire, aucune violation de l'oracle sur 48 duels de sonde, plan des 24 parties en données et contrôlé contre le protocole (0069).
- **Le cycle a tenu le rythme** : treize PR d'étape en trois jours, chacune fusionnée sur CI verte ; les corrections de cap ont marqué les décisions touchées (0058 et 0060 modifiées par 0065, 0063 précisée par 0067, 0066 modifiée par 0069) au lieu de les réécrire.

## Ce qui a coûté

- **Le jalon a dépassé son estimation** : huit sessions prévues, douze étapes faites. c.5 a été découpée en trois (quatre systèmes nouveaux), la correction de cap 0061 a ajouté une étape, puis c.5d a été coupée en deux. Le seuil de réexamen de 0054 (« nettement plus de 8 sessions ») est atteint.
- **La consigne de la rétro J2 n'a pas été tenue partout** : trois éditions du ruleset sont entrées dans des PR d'étape au lieu de passer entre deux étapes (PR 52 de c.4, PR 54 de c.5b, PR 60 de c.7).
- **La relecture a rouvert des étapes** : c.5c a demandé une seconde décision (0063) après que la relecture a trouvé une boucle d'appels entre deux modules du chapitre 207 ; c.6 a corrigé des identifiants de règle après coup (0067) ; c.7 et c.8 ont eu chacune onze points de relecture, tous corrigés avant la PR. Cinq PR sur treize comptent un commit de clôture ou de suite.
- **Les décisions de vocabulaire se sont remplacées vite** : la condition à vocabulaire fermé de 0060 et le X de 0058 ont été repris un jour plus tard par la valeur du jeu partagée (0065).
- **Des vérifications à l'écran restent à faire** : le rendu de c.7 en 1280×720, l'Observatoire côté adversaire, la revanche et le message de plan illisible de c.8. Les tests les couvrent, la vue non.
- **Deux suites de tests ont chargé des scènes** pendant c.8, ce que `tests/CLAUDE.md` interdit ; la relecture l'a vu, et leur suppression a buté sur les permissions.

## Dettes

Portées dans [backlog.md](../backlog.md) : trois dettes du ruleset 0.46, 0.47 et 0.49 (coût X, valeur X, expiration pendant le choix de X) sont réglées par c.5a et retirées ; les vérifications à l'écran restées à faire de J2c y entrent, cible « avant J3 ». Les dettes ouvertes par J2c (`AnnouncementAssistant` et ses limites, requêtes de la vue vers les modules de règles, `_note_expiry` en attente de Q-163, `trigger_rules.gd` à la limite des 400 lignes) y sont déjà.

## Décisions à réexaminer

| Décision | Condition de réexamen | État |
| --- | --- | --- |
| 0054 ordre J2c puis J2b | J2c dépasse nettement 8 sessions, ou le playtest J3 fait refaire le catalogue | atteinte pour la durée (12 étapes) ; l'ordre a rendu son service, J2c est fini : aucune action, sauf à revoir l'estimation des jalons suivants. |
| 0055 Ordre du Hero | un Ordre de coût ou de vitesse variable | non atteinte : les 4 Heroes ont un Ordre fixe. |
| 0056, 0067 cibles de destination | une carte vise deux pièces aux filtres différents ; adjacence au Hero adverse | non atteinte. |
| 0057 choix à la résolution | un choix pendant un combat ou un effet d'un autre joueur ; troisième genre de choix | non atteinte. |
| 0058, 0060 | deux X sur une carte ; déclencheur dont l'auteur est l'adversaire | non atteinte ; déjà modifiées par 0065. |
| 0059 modules d'un chapitre | plus de cinq modules ou une boucle dans un chapitre | atteinte en partie : 207 compte cinq modules et la boucle `CombatRules` / `EffectRules` / `TriggerRules` reste au backlog (J4). |
| 0061 inventaire | une ligne « à coder » sans règle, ou après J3 | non atteinte ; à reprendre après J3. |
| 0062, 0063 filtre de pièces | un axe absent (Force, mot-clé, état) | non atteinte. |
| 0064, 0065 textes et valeurs | plusieurs déclencheurs par texte ; comparaison autre qu'« au moins » ou « au plus » | non atteinte. |
| 0066, 0069 plan de série | le plan suit la fiche (0066) ; le protocole change le plan ou Q-142 fixe l'ordre (0069) | 0066 atteinte et réglée par 0069 ; 0069 à revoir si Q-142 est tranchée avant J3. |
| 0068 assistant d'annonce | une forme d'annonce non enchaînée, ou l'IA de J4 | à revoir à J4 : l'IA aura besoin de la même construction d'annonce. |

## Règles PROVISOIRE à mesurer

J2c n'a ajouté aucune règle PROVISOIRE au moteur ; le catalogue en apporte : les 4 Heroes (PV et Ordres) et les 48 cartes sont PROVISOIRE, à mesurer à J3 (`ruleset/50-cartes/`). Les mesures du protocole attendent Q-141 (cibles et seuils pour des decks asymétriques), Q-142 (ordre des parties) et Q-163 (champ des choix tirés au sort), à trancher avant la série J3, avec Q-102 (mulligan de la série).

## Une chose à changer pour la suite

**Estimer un jalon en systèmes nouveaux, pas en sessions.** J2c annonçait huit sessions et a demandé quinze décisions (0055 à 0069) ; chaque système nouveau a demandé sa propre étape, parfois deux. À l'ouverture d'un jalon, compter dans la roadmap les systèmes nouveaux qu'il exige (un par décision attendue) et prévoir une étape par système ; le réexamen « dépasse nettement » se juge alors sur ce compte.

Consigne acceptée par le créateur le 28 octobre 2026 et inscrite dans `open-step` (première étape d'un jalon : compter les systèmes nouveaux, une étape par système).
