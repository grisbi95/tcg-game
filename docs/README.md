# Documentation du projet

> **Rôle** : carte des documents : ce que contient chacun, quand le lire, lequel prévaut. Chaque information n'a qu'un document propriétaire ; les autres y renvoient.

## Où trouver quoi

| Document | Contenu | Quand le lire |
| --- | --- | --- |
| [ruleset/](ruleset/README.md) | Copie épinglée du ruleset (`RULESET_EDITION`) : règles complètes 200 à 210, glossaire, charte, protocole et decks de test. **Fait foi sur les règles.** Lecture seule ici. | Avant tout travail de gameplay ; pour nommer tests et fonctions. |
| [roadmap.md](roadmap.md) | Jalons, étapes et **État actuel**. Seul plan. | Au début de chaque session. |
| [decisions/](decisions/) | Décisions d'architecture acceptées (`0001` à `0013`) et modèle `0000`. | Avant de créer ou modifier un système. |
| [code-guidelines.md](code-guidelines.md) | Pourquoi et comment des consignes de code ; signaux d'alerte en relecture. Synthèse des articles de The Shaggy Dev. | Pour concevoir ou relire du code. |
| [../CLAUDE.md](../CLAUDE.md) | Consignes impératives de développement, courtes. Compléments : `rules/CLAUDE.md`, `ui/CLAUDE.md`, `tests/CLAUDE.md`, `.claude/README.md`. | Toujours chargé. |

Hors de ce dépôt : `../tcg-ruleset/` est le dossier d'édition des règles (agent `ruleset-editor`) ; `../proposition-architecture-workflow.md` est la proposition du 16 octobre 2026 dont les décisions 0001 à 0007 sont issues ; `~/Documents/GameDev/tactical_tcg/` est l'ancien prototype, consultable, jamais importé.

## Hiérarchie

En cas d'écart, le document de rang supérieur prévaut.

- **Règles du jeu** : `ruleset/20-regles-completes/` > `ruleset/70-playtest/` > tout le reste. Un écart entre le code et le ruleset est un défaut du code, ou une question pour `tcg-ruleset`.
- **Production et code** : `roadmap.md` > `decisions/` > `CLAUDE.md` > `code-guidelines.md`.

## Où écrire

| Nouvelle information | Document |
| --- | --- |
| Règle ou arbitrage de jeu | Jamais ici : `../tcg-ruleset` via `ruleset-editor`, puis `tools/sync_ruleset.sh`. |
| Décision d'architecture | `decisions/`, copie de `0000-modele.md` au prochain numéro, via l'agent `adr-writer`. |
| Étape, état, périmètre | `roadmap.md`. |
| Consigne de développement | `CLAUDE.md` si impérative et courte ; sinon `code-guidelines.md` ou le `CLAUDE.md` local. |
| Recette répétable | `.claude/skills/<nom>/SKILL.md`. |

Noms de fichiers en anglais ou en français selon le dossier source, contenu en français, un titre et une ligne **Rôle** par document.
