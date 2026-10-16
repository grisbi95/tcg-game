# Ruleset du TCG tactique

> Dossier de conception des règles, intégré au dépôt du jeu `tcg-game`, dans `docs/ruleset/` (décision 0014 du projet). Édition courante : **0.30** (réponses aux questions Q-075 à Q-079, 16 octobre 2026). Historique dans [90-changelog.md](90-changelog.md).

## Quel document pour quel lecteur

| Lecteur | Document | Rôle |
| --- | --- | --- |
| Tout le monde | [CHARTE.md](CHARTE.md) | Cahier des charges éditorial : comment on écrit, numérote, décide et versionne. À lire avant toute modification. |
| Équipe de design | [00-vision.md](00-vision.md) | Piliers, public, ce que le jeu n'est pas. Court et stable. |
| Tout le monde | [01-glossaire.md](01-glossaire.md) | Un terme, une définition. Tous les documents emploient ce vocabulaire et aucun autre. |
| Équipe de design | [02-questions-ouvertes.md](02-questions-ouvertes.md) | Backlog des points À ARBITRER, avec options et ce qui manque pour trancher. |
| Joueur | [10-regles-de-base.md](10-regles-de-base.md) | Le livret d'apprentissage, avec exemples. Plan écrit le 15 octobre 2026 ; le texte de chaque partie s'écrit quand le chapitre correspondant est stable. |
| Moteur, arbitres, design | [20-regles-completes/](20-regles-completes/) | **Fait foi.** Règles numérotées, une phrase par règle, sans exemple. |
| Équipe de design | `30-guides-de-design/` | Le pourquoi : écriture des cartes, mots-clés, économie, Heroes, budget de complexité. Créé avec la première édition jouable. |
| Équipe de design | [40-decisions/](40-decisions/) | Une décision par fichier, numérotée, jamais modifiée après coup. |
| Design, moteur | `50-cartes/` | Catalogue en construction. Créé avec la première édition jouable. |
| Arbitres, joueurs | `60-rulings.md` | Interactions de cartes tranchées. Créé avec le catalogue. |
| Design | [70-playtest/](70-playtest/protocole.md) | Protocole, decks de test, métriques, comptes rendus de sessions. Protocole du premier playtest écrit le 16 octobre 2026 et complété le même jour (édition 0.28), avec les [decks de test](70-playtest/decks-de-test.md) ; les comptes rendus s'ajoutent après chaque série. |
| Tout le monde | [90-changelog.md](90-changelog.md) | Une entrée par édition, avec les règles touchées. |

## Chapitres des règles complètes

| Chapitre | Contenu |
| --- | --- |
| [200](20-regles-completes/200-regles-d-or.md) | Règles d'or : portée des règles et sous-règles, conflits entre cartes et règles, interdictions et permissions, impossibilités |
| [201](20-regles-completes/201-concepts.md) | Concepts : joueurs, but, plateau, zones, information, construction du deck |
| [202](20-regles-completes/202-cartes.md) | Cartes : anatomie, types, Hero, permanents, jetons |
| [203](20-regles-completes/203-ressource.md) | Ressource : Essence, Sources, inclinaison, recyclage |
| [204](20-regles-completes/204-tour.md) | Tour : préparation, mulligan, structure, fin de partie |
| [205](20-regles-completes/205-actions.md) | Actions : déploiement, action normale, déplacement du Hero |
| [206](20-regles-completes/206-combat.md) | Combat : comparaison, égalités, dégâts au Hero, auras |
| [207](20-regles-completes/207-effets.md) | Effets : Spells, effets statiques, déclenchés, durées, cibles, Contrecarrer |
| [208](20-regles-completes/208-pile-et-priorite.md) | Pile et priorité : passes, résolution en bloc, chaînes |
| [209](20-regles-completes/209-controles-d-etat.md) | Contrôles d'état : Force ≤ 0, victoire, nul, pendule |
| [210](20-regles-completes/210-mots-cles.md) | Mots-clés : conventions, texte de règle de chacun, mots-clés de déclencheurs et de combat |

## Workflow d'une session de travail

1. Ouvrir un sujet depuis [02-questions-ouvertes.md](02-questions-ouvertes.md), ou en ajouter un.
2. Trancher en discussion. La décision est consignée dans `40-decisions/` avec les options écartées.
3. Modifier les règles complètes. Le glossaire et le chapitre 210 suivent.
4. Ajouter une ligne au changelog. Mettre à jour le livret seulement quand un chapitre se stabilise.

Toute modification d'un fichier de ce dossier passe par l'agent `ruleset-editor`, qui applique la [charte](CHARTE.md). La discussion décide, l'agent écrit. Rien n'est écrit dans un document avant d'avoir été tranché en discussion.
