# Documentation du projet

> **Rôle** : carte des documents : ce que contient chacun, quand le lire, lequel prévaut. Chaque information n'a qu'un document propriétaire ; les autres y renvoient.

## Où trouver quoi

| Document | Contenu | Quand le lire |
| --- | --- | --- |
| [ruleset/](ruleset/README.md) | Ruleset (décision 0014), édition dans son `README.md` : vision, glossaire, questions ouvertes, livret, règles complètes 200 à 210, décisions de design, protocole et decks de test, changelog. **Fait foi sur les règles.** Mode d'édition : `CLAUDE.md` racine et `ruleset/README.md`. | Avant tout travail de gameplay ; pour nommer tests et fonctions. |
| [roadmap.md](roadmap.md) | Jalons, étapes et **État actuel**. Seul plan. | Au début de chaque session. |
| [vocabulaire-des-effets.md](vocabulaire-des-effets.md) | Inventaire du vocabulaire d'effets du moteur (décision 0061) : verbes, variantes, axes, mots-clés ; **fait foi** pour ce que le moteur code et ce qu'une carte peut dire. Mis à jour par `/sync-rule`. | Avant de coder un effet ou d'écrire une carte. |
| [backlog.md](backlog.md) | Dettes techniques (décision 0038) : une ligne par dette, référence, priorité, cible. | À la clôture d'une étape ; avant de choisir un travail de fond. |
| [decisions/](decisions/) | Décisions d'architecture acceptées (`0001` à `0069`, 0025 remplacée par 0027) et modèle `0000`. | Avant de créer ou modifier un système. |
| [retros/](retros/) | Rétrospective de chaque jalon clos (décision 0039) : ce qui a marché, ce qui a coûté, décisions à réexaminer, une chose à changer. | À l'ouverture d'un jalon ; avant de réexaminer une décision. |
| [maquettes/](maquettes/) | Maquettes HTML de référence visuelle (1920×1080, à ouvrir dans un navigateur) ; jamais intégrées au jeu, figées : une nouvelle version est un nouveau fichier. Ordre : les décisions fixent les choix ; une fiche technique (`fiches/`), quand elle existe, donne les cotes et prime sur la maquette ; sinon les cotes des décisions priment (0028, 0030, 0053). | Pour réaliser ou relire un écran. |
| [fiches/](fiches/) | Fiches techniques vivantes des écrans (décision 0052) : par élément, node Godot, couche, taille, place, transparence, états, asset attendu. Éditées directement, avec un journal en fin de fiche. Elles priment sur les maquettes ; une décision les rend prioritaires sur les cotes des décisions précédentes (0053). | Pour construire un écran ou générer ses assets. |
| [code-guidelines.md](code-guidelines.md) | Pourquoi et comment des consignes de code ; signaux d'alerte en relecture. Synthèse des articles de The Shaggy Dev. | Pour concevoir ou relire du code. |
| [../CLAUDE.md](../CLAUDE.md) | Consignes impératives de développement, courtes. Compléments : `rules/CLAUDE.md`, `ui/CLAUDE.md`, `tests/CLAUDE.md`, `.claude/README.md` ; descriptions de ce qui existe dans `app/README.md` et `ui/README.md`. | Toujours chargé. |

Hors de ce dépôt : `../proposition-architecture-workflow.md` est la proposition du 16 octobre 2026 dont les décisions 0001 à 0007 sont issues ; `~/Documents/GameDev/tactical_tcg/` est l'ancien prototype, consultable, jamais importé.

## Hiérarchie

En cas d'écart, le document de rang supérieur prévaut.

- **Règles du jeu** : `ruleset/20-regles-completes/` > `ruleset/70-playtest/` > tout le reste. Un écart entre le code et le ruleset est un défaut du code, ou une question ouverte du ruleset.
- **Production et code** : `roadmap.md` > `decisions/` > `CLAUDE.md` > `code-guidelines.md`.

## Où écrire

| Nouvelle information | Document |
| --- | --- |
| Règle ou arbitrage de jeu | `ruleset/`, par l'agent `ruleset-editor` ; question ouverte si le point n'est pas tranché. |
| Décision d'architecture | `decisions/`, copie de `0000-modele.md` au prochain numéro, via l'agent `adr-writer`. |
| Étape, état, périmètre | `roadmap.md`. |
| Dette technique | `backlog.md` ; jamais dans « État actuel ». |
| Consigne de développement | `CLAUDE.md` si impérative et courte ; sinon `code-guidelines.md` ou le `CLAUDE.md` local. |
| Recette répétable | `.claude/skills/<nom>/SKILL.md`. |
| Leçons d'un jalon clos | `retros/<jalon>.md`, par `/retro` (décision 0039) ; les dettes vont au backlog, pas dans la rétro. |

Noms de fichiers en anglais ou en français selon le dossier source, contenu en français, un titre et une ligne **Rôle** par document.
