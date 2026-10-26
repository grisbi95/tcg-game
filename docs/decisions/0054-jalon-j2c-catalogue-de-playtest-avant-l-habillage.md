# 0054 — Jalon J2c « Catalogue de playtest » avant la suite de J2b

- Statut : acceptée
- Date : 2026-10-26
- Décideur : créateur du projet
- Périmètre : ordre des jalons de la roadmap (J2b, J2c, J3, J4), correction de cap après le ruleset 0.52

## Contexte

Le ruleset est passé de 0.44 à 0.52 le 26 octobre 2026 : décisions de design 0211 à 0241, chapitres 211 à 217 nouveaux (Ordre du Hero, Défausser, coût X, Échanger, déplacer, renvoyer, regarder le dessus du deck), Hero sur tout le plateau (0223), catalogue de playtest dans `docs/ruleset/50-cartes/` (4 Heroes, 48 cartes, 4 decks) et série J3 de 24 parties à quatre decks. Rien n'en est codé (dettes au backlog) ; le moteur contredit même 0223 (`ActionRules` rejette un Hero hors de ses deux rangées, `test_205_normal_action.gd` et `DuelOracle` le vérifient). La roadmap prévoyait J2b (2b.4 à 2b.8), puis J3 avec 20 parties et les decks de test, puis l'intégration du catalogue en J4 ; 2b.6 prévoyait 18 illustrations, le catalogue en demande 52. Contraintes : un module de règles par chapitre, un nouveau `kind` = code et tests avant toute carte (0002, 0010), une session une étape ; 0047 a retiré le pouvoir du Hero du code, l'Ordre le modifiera par sa propre décision.

## Options envisagées

- Option A : nouveau jalon J2c avant la suite de J2b, puis J3. Pour : direction artistique et illustrations portent sur la liste définitive ; règles nouvelles éprouvées par des duels aléatoires avant tout habillage ; moteur remis en accord avec les règles d'abord. Contre : l'habillage attend environ 8 sessions. Limite : si le playtest change beaucoup les cartes, une partie des illustrations sera à refaire.
- Option B : finir J2b, puis J2c, puis J3. Pour : la branche `docs/direction-artistique` est reprise tout de suite, le jeu a son visage plus tôt. Contre : 2b.6 illustrerait 18 cartes qui ne sont plus jouées au playtest ; moteur en désaccord avec les règles pendant J2b. Limite : habillage d'écrans qui changent ensuite (Ordre, choix de X, défausse).
- Option C : J2c et J2b en parallèle, sessions alternées. Pour : les deux avancent. Contre : deux fronts, branches divergentes, « une session, une étape » plus dur à tenir. Limite : 2b.6 attendrait quand même la fin de c.6.

## Décision

Option A, choisie par le créateur le 2026-10-26, avec le découpage proposé sans modification :

- c.1 Remise en accord : Hero sur tout le plateau (0223), pas de déploiement sur la case du Hero ennemi (0225).
- c.2 Ordre et effets déclenchés du Hero (chapitre 211) ; décision de code qui modifie 0047.
- c.3 Effets de mouvement : déplacer (215), échanger (214), renvoyer (216).
- c.4 Effets de cartes et de main : piocher, défausser (212), regarder (217), réveiller.
- c.5 Coûts et déclencheurs : coût X et valeur X (213), nouveaux déclencheurs, effet déclenché d'un Gear, dernière case, nouvelles portées statiques, condition « si ».
- c.6 Cartes : 48 cartes, 4 Heroes, 4 decks en JSON, choix du deck à la préparation.
- c.7 Vue : utiliser l'Ordre, choisir X, choisir la carte à défausser, Observatoire.
- c.8 Recette : duels aléatoires sur les 6 affrontements avec l'oracle, plan des 24 parties dans la fiche de relevé.

Puis 2b.4 à 2b.8 (2b.6 : illustrations du catalogue, 52 au lieu de 18), puis J3.

## Conséquences et vérification

- La roadmap gagne la section J2c entre J2b et J3 ; J2c passe avant 2b.4. J3 devient la série de 24 parties du protocole (décisions de design 0229 à 0232), Q-141 et Q-142 du ruleset à trancher avant ; J4 n'intègre plus `50-cartes/`.
- Les decks de test restent les decks de référence du moteur.
- Vérification : chaque étape c.1 à c.8 a sa ligne « Sortie » dans la roadmap ; suites vertes et duels aléatoires sans violation de l'oracle à c.8.
- Réexamen de l'ordre J2c / J2b si le playtest J3 montre que le catalogue doit être largement refait, ou si J2c dépasse nettement 8 sessions.

## Références

- Décisions 0002, 0010, 0038, 0047 (modifiée par la décision de c.2), 0052.
- `docs/ruleset/` édition 0.52, `docs/ruleset/50-cartes/`, décisions de design 0211 à 0241, `docs/backlog.md`, `docs/roadmap.md`.
