# 0022 — Journal des coups et du temps, replay et non-régression

- Statut : acceptée
- Date : 2026-10-17
- Décideur : créateur du projet
- Périmètre : journal et replay de l'hôte (`app/`, étape 2.1)

## Contexte

L'étape 2.1 demande un journal et un replay avec test de non-régression. Le moteur est déterministe : même état, même graine, mêmes intentions donnent le même résultat (0001), et le temps entre dans le moteur par `advance_clock` (0018). Le journal doit donc porter les coups et le temps. Il servira aussi aux fiches de playtest (2.5).

## Options envisagées

- Option A : `DuelJournal` rejouable à travers le moteur (préparation, intentions acceptées, temps). Vrai test de non-régression ; coût : un codec d'intentions à maintenir.
- Option B : journal des événements seuls. Lisible ; mais ne se rejoue pas à travers le moteur, donc pas de vrai test de non-régression.
- Option C : états complets à chaque coup. Accès direct à tout instant ; fichier énorme, cassé au moindre changement de l'état.

## Décision

Option A, recommandée et choisie par le créateur le 17 octobre 2026.

## Conséquences et vérification

- `DuelJournal` (`app/`) contient : version du format, édition du ruleset, préparation (`DuelSetup` : decks, Heroes, graine, premier joueur imposé), puis les entrées dans l'ordre : intention acceptée, ou temps écoulé.
- Les temps consécutifs sans intention entre eux se cumulent en une entrée (équivalent : les pendules qui tournent ne changent qu'à une soumission). Seules les intentions acceptées s'inscrivent ; une intention refusée ne change rien.
- Fichier JSON lisible. Les intentions s'écrivent par un codec (`IntentCodec`, `app/`) qui associe un nom à chaque classe d'intention et lit leurs champs typés ; un test vérifie que chaque classe d'intention du moteur est connue du codec.
- Replay : moteur neuf, préparation, puis entrées rejouées ; même résultat par déterminisme (0001).
- Non-régression : un journal enregistré dans `tests/` (duel aléatoire à graine fixe de `RandomLegalAgent`, temps compris) est rejoué et comparé à une empreinte attendue (empreinte des événements et résumé de l'état final). Un script de `tools/` le régénère quand un changement de règle est voulu.
- Un journal d'une autre version de format est refusé au chargement.
- À réexaminer si le format doit être lu hors du jeu, ou si l'empreinte se révèle trop fragile.

## Références

Décisions 0001, 0012, 0018, 0019, 0020, 0021 ; roadmap étapes 2.1 et 2.5.
