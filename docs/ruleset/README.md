# Ruleset du TCG tactique

> Dossier de conception des règles, intégré au dépôt du jeu `tcg-game`, dans `docs/ruleset/` (décision 0014 du projet). Édition courante : **0.53** (expiration du temps pendant le regard sur le dessus du deck, 26 octobre 2026). Historique dans [90-changelog.md](90-changelog.md).

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
| Design, moteur | [50-cartes/](50-cartes/README.md) | **Fait foi.** Catalogue de playtest : 4 Heroes, cartes de couleur et neutres, 4 decks de 30 cartes. Créé le 26 octobre 2026 (décision 0228) ; le journal de conception reste hors ruleset. |
| Arbitres, joueurs | `60-rulings.md` | Interactions de cartes tranchées. Créé avec le catalogue. |
| Design | [70-playtest/](70-playtest/protocole.md) | Protocole, decks de test, métriques, comptes rendus de sessions. Le premier playtest se joue avec le catalogue de playtest (décision 0224, 26 octobre 2026), en 24 parties selon un plan de série (édition 0.50, décisions 0229 à 0232). Protocole du premier playtest écrit le 16 octobre 2026 et complété le même jour (édition 0.28) et le 18 octobre 2026 (édition 0.35, mesure de l'Essence perdue ; édition 0.36, mesures de la fenêtre de réponse) et le 21 octobre 2026 (édition 0.38, définitions des mesures de la fenêtre de réponse sans échéance) et le 22 octobre 2026 (édition 0.39, mesure des PV perdus par un Hero en un tour ; édition 0.40, mesures du temps de tour, du temps de réponse et de l'inactivité), avec les [decks de test](70-playtest/decks-de-test.md) ; les comptes rendus s'ajoutent après chaque série. |
| Tout le monde | [90-changelog.md](90-changelog.md) | Une entrée par édition, avec les règles touchées. |

## Chapitres des règles complètes

| Chapitre | Contenu |
| --- | --- |
| [200](20-regles-completes/200-regles-d-or.md) | Règles d'or : portée des règles et sous-règles, conflits entre cartes et règles, interdictions et permissions, impossibilités |
| [201](20-regles-completes/201-concepts.md) | Concepts : joueurs, but, plateau, zones, information, construction du deck |
| [202](20-regles-completes/202-cartes.md) | Cartes : anatomie, types, Hero, permanents, jetons |
| [203](20-regles-completes/203-ressource.md) | Ressource : Essence, Sources, inclinaison, recyclage, réserve d'Essence |
| [204](20-regles-completes/204-tour.md) | Tour : préparation, mulligan, structure, fin de partie |
| [205](20-regles-completes/205-actions.md) | Actions : déploiement, action normale, déplacement du Hero, sommeil et réveil, combat en attente |
| [206](20-regles-completes/206-combat.md) | Combat : comparaison, égalités, dégâts au Hero, auras |
| [207](20-regles-completes/207-effets.md) | Effets : Spells, effets statiques, déclenchés, durées, cibles, Contrecarrer |
| [208](20-regles-completes/208-pile-et-priorite.md) | Pile et priorité : passes, résolution en bloc, chaînes, fenêtre de réponse, annonces sans réponse |
| [209](20-regles-completes/209-controles-d-etat.md) | Contrôles d'état : Force ≤ 0, victoire, nul, inactivité, temps de tour et temps de réponse, fatigue |
| [210](20-regles-completes/210-mots-cles.md) | Mots-clés : conventions, texte de règle de chacun, mots-clés de déclencheurs et de combat |
| [211](20-regles-completes/211-ordre-du-hero.md) | Ordre du Hero : nature, annonce, coût, cibles |
| [212](20-regles-completes/212-defausser.md) | Défausser : nature de l'effet, défausse comme événement |
| [213](20-regles-completes/213-valeur-x.md) | Valeur X : coût X, valeur X définie par un texte |
| [214](20-regles-completes/214-echanger.md) | Échanger : échange des cases de deux Units alliées |
| [215](20-regles-completes/215-deplacer-par-un-effet.md) | Déplacer une Unit par un effet : nature, conséquences |
| [216](20-regles-completes/216-renvoyer-dans-la-main.md) | Renvoyer dans la main : carte, jeton, Gear, Dernier souffle |
| [217](20-regles-completes/217-regarder-le-dessus-du-deck.md) | Regarder le dessus du deck : visibilité, choix, deck vide |

## Workflow d'une session de travail

1. Ouvrir un sujet depuis [02-questions-ouvertes.md](02-questions-ouvertes.md), ou en ajouter un.
2. Trancher en discussion. La décision est consignée dans `40-decisions/` avec les options écartées.
3. Modifier les règles complètes. Le glossaire et le chapitre 210 suivent.
4. Ajouter une ligne au changelog. Mettre à jour le livret seulement quand un chapitre se stabilise.

Toute modification d'un fichier de ce dossier passe par l'agent `ruleset-editor`, qui applique la [charte](CHARTE.md). La discussion décide, l'agent écrit. Rien n'est écrit dans un document avant d'avoir été tranché en discussion.
