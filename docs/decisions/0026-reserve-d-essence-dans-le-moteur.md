# 0026 — Réserve d'Essence dans le moteur, ajoutée au paiement

- Statut : acceptée
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : Essence et paiement (`rules/`, chapitre 203, 204.5.7)

## Contexte

Le ruleset 0.35 (Q-089 à Q-092, décisions de design 0190 à 0193) donne à un joueur, pendant son propre tour, une réserve d'Essence qu'il remplit en inclinant ou recyclant ses Sources chaque fois qu'il peut agir, et où il paie ses coûts. L'Essence non dépensée est perdue à la fin du tour (204.5.7). Pendant le tour adverse, pas de réserve : paiement à l'annonce avec toutes ses Sources. La décision 0003 (paiement porté par l'intention) reste valable mais est complétée par la présente.

## Options envisagées

- Option A : ajout au paiement (recommandée). Une intention nouvelle (produire de l'Essence : incliner ou recycler, `EssencePayment`) remplit une réserve de `PlayerState`. Les annonces gardent leur `EssencePayment` (0003) : en son tour, l'Essence produite s'ajoute d'abord à la réserve, puis le coût y est pris ; au tour adverse, la réserve est nulle et le paiement égale le coût. Tests et `RandomLegalAgent` presque inchangés.
- Option B : paiement séparé. Plus de paiement sur les annonces pendant son tour, tout passe par la réserve ; l'ancien paiement seulement au tour adverse. Beaucoup de tests et l'IA à réécrire, deux chemins dans le moteur.

## Décision

Option A, recommandée et choisie par le créateur le 18 octobre 2026.

## Conséquences et vérification

- Nouveau champ d'état (réserve d'Essence) avec `clone()` et son test ; à 204.5.7 la réserve se vide.
- Nouvelle intention de production et ses refus (hors de son tour, Source indisponible) ; nouveaux événements : Essence produite, Essence perdue.
- Le journal (0022) et `IntentCodec` connaissent la nouvelle intention ; le test de non-régression est régénéré, le comportement changeant volontairement.
- Tests nommés par identifiant de règle : production, paiement depuis la réserve, perte en fin de tour, tour adverse inchangé.
- À réexaminer si le ruleset retire la réserve ou si deux chemins de paiement gênent la vue.

## Références

Ruleset 203, 204.5.7, décisions de design 0190 à 0193 ; décisions 0003 (complétée), 0019, 0022, 0023 ; roadmap étape 2.2.
