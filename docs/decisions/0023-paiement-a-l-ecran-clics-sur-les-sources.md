# 0023 — Paiement à l'écran : clics sur les Sources

- Statut : acceptée ; geste de recyclage modifié par 0028
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : paiement des coûts en Essence dans la vue (étape 2.2)

## Contexte

La vue doit laisser le joueur payer ses coûts. Le ruleset passe en édition 0.35 (Q-089 à Q-092, décisions de design 0190 à 0193) : pendant son tour, un joueur remplit une réserve d'Essence en inclinant ou recyclant ses Sources (+1 chacune), y paie ses coûts, et perd l'Essence non dépensée à la fin du tour (204.5.7). Pendant le tour adverse, il n'a pas de réserve et paie à l'annonce, avec toutes ses Sources (décision 0003).

## Options envisagées

- Option A : paiement proposé par défaut, ajustable par + et − (recommandée). Peu de gestes ; mais le joueur ne voit pas ses Sources agir une à une.
- Option B : paiement automatique (incliner d'abord, puis recycler). Simplissime ; retire au joueur le choix de recycler (déjà écarté en 0003).
- Option C : paiement toujours demandé avant chaque annonce. Maximum de contrôle ; une étape de plus à chaque carte.

## Décision

Autre voie que A, B ou C, décrite et choisie par le créateur le 18 octobre 2026 : le joueur clique une Source redressée (elle s'incline, +1 Essence) ou une Source inclinée (elle part en Fonte, +1 Essence). Pendant son tour, chaque clic remplit vraiment sa réserve ; les cartes dont le coût est couvert par l'Essence disponible s'allument.

## Conséquences et vérification

- Pendant son tour, un clic soumet l'intention de production d'Essence (décision 0026).
- Pendant le tour adverse, faute de réserve, les clics composent un brouillon de paiement, sans effet sur l'état, joint à la réponse annoncée (`EssencePayment`, décision 0003) et annulable.
- Aucune règle dans la vue : `DuelSelection` valide chaque geste par `validate()` (décision 0024).
- Vérification : tests de `DuelSelection` sans scène (clic de Source en tour propre et en tour adverse, annulation du brouillon) ; scène d'essai des Sources.
- À réexaminer si le playtest (J3) montre trop de clics pour une carte chère.

## Références

Ruleset 203, 204.5.7, décisions de design 0190 à 0193 ; décisions 0003, 0024, 0026, 0028 ; roadmap étape 2.2.
