# 0060 — Déclencheurs nommés avec leur auteur et condition à vocabulaire fermé

- Statut : acceptée, complétée par 0061, modifiée par 0065
- Date : 2026-10-27
- Décideur : créateur du projet, en conversation
- Périmètre : `EffectDefinition.TriggerEvent`, condition « si », étape c.5b du jalon J2c

## Contexte

Ruleset 0.54 : 204.3.12 à 204.3.12b (événement « début du tour », après le réveil, le redressement et la Source reçue, avant la pioche), 206.3.7 à 206.3.7b (« détruit son défenseur »), 207.3.12 à 207.3.12c (effet déclenché d'un Gear), 207.3.13 à 207.3.13b (condition « si » lue à l'événement, effet non déclenché si elle est fausse, pas relue à la résolution), 207.3.14, 207.5.18, 212.2.5. Le catalogue demande « au début de votre tour » (6 cartes), « chaque fois que vous annoncez un Spell » (Apprenti, Lame-sort), « quand vous défaussez une carte » (Spectre des archives), « quand l'Unit qui porte ce Gear détruit son défenseur » (Grimoire, Trophée) ; seule condition : Pilleuse « si vous avez une carte ou moins en main ». Le code ne connaît que `ARRIVAL`, `DESTROYED`, `END_OF_TURN`, lus sur la pièce porteuse, et aucune condition. Contraintes : vocabulaire fermé (0002, 0010), enums ajoutés en fin.

## Options envisagées

Question 1, qui fait l'action déclenchante :
- A : événements nommés avec leur auteur (`START_OF_OWN_TURN`, `OWN_SPELL_ANNOUNCED`, `OWN_CARD_DISCARDED`, `DESTROYS_DEFENDER`). Chaque valeur dit le texte d'une carte. Limite : « quand votre adversaire annonce un Spell » demandera une valeur de plus ; aucune carte ne le demande.
- B : événements génériques plus un champ auteur (vous, adversaire, quiconque ; ou cette pièce / son porteur). Plus général, mais des combinaisons sans carte à valider.

Question 2, condition « si » :
- A : condition à vocabulaire fermé, `{kind: HAND_SIZE_AT_MOST, amount: 1}`, `ConditionKind` qui grandit carte par carte. Même logique que les `kind` d'effet, un test par condition.
- B : comparaison générique (`{quantity, comparison, value}`). Couvre d'avance d'autres conditions, mais plus de combinaisons que de cartes et une petite grammaire à valider.

## Décision

Question 1 : option A. Question 2 : option A. Les options B sont écartées. Choix du créateur, en conversation, le 2026-10-27. Pour `DESTROYS_DEFENDER`, l'auteur est la pièce elle-même ou, pour un Gear, l'Unit qui le porte (207.3.12). La condition est lue à l'événement (207.3.13).

## Conséquences et vérification

- Complète 0010 (clés `trigger` nouvelles, `condition`) et 0017 (événements déclencheurs nouveaux).
- À c.5b : `TriggerEvent` (quatre valeurs en fin d'enum), `ConditionKind`, `TriggerRules`, `TurnRules` (événement placé selon 204.3.12b), `CombatRules` (206.3.7), `DiscardRules` (212.2.5), `SpellRules` ; dernière case (207.3.14) ; effets déclenchés d'un Gear (207.3.12 à 207.3.12c) ; un test par identifiant de règle et par condition.
- Hors c.5b : portées et filtres (c.5c), cartes (c.6), vue (c.7).
- Réexamen : au premier déclencheur dont l'auteur est l'adversaire, ou à la troisième condition.

## Références

- Décisions 0002, 0010, 0017 ; `docs/ruleset/` : 204.3.12, 206.3.7, 207.3.12 à 207.3.14, 207.5.18, 212.2.5.
- `docs/roadmap.md`, étape c.5b.
