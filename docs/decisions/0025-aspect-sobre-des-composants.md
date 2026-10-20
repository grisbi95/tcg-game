# 0025 — Aspect sobre des composants

- Statut : remplacée par 0027 (aspect des cartes et des pièces)
- Date : 2026-10-18
- Décideur : créateur du projet
- Périmètre : habillage des composants de vue (`ui/components/`, `ui/theme/`)

## Contexte

L'étape 2.2 crée les composants de vue (cartes, pièces, Sources…) et leurs scènes d'essai. Il faut fixer leur aspect sans bloquer le jalon.

## Options envisagées

- Option A : sobre, sans image (recommandée). Cadres colorés par joueur, texte (nom, coût, Force, mots-clés), un seul thème Godot dans `ui/theme/`. Lisible et immédiat ; austère.
- Option B : avec illustrations. Plus attrayant ; images à trouver, droits à régler, hors périmètre.

## Décision

Option A, recommandée et choisie par le créateur le 18 octobre 2026.

## Conséquences et vérification

- Un seul thème Godot dans `ui/theme/` ; aucune couleur ou police réglée dans les scènes.
- L'habillage pourra changer plus tard sans toucher la logique.
- Vérification : scènes d'essai des composants chargées et capturées.
- À réexaminer après J3 (playtest).

## Références

Décision 0011 (vues par capture) ; `ui/CLAUDE.md` ; roadmap étape 2.2.
