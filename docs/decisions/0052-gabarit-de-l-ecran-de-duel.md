# 0052 — Gabarit de l'écran de duel : couches, conteneurs et fiche technique

- Statut : acceptée ; complétée par 0053
- Date : 2026-10-24
- Décideur : créateur du projet
- Périmètre : écran de duel (`ui/duel_screen.tscn`), jalon J2b, étapes 2b.2 et 2b.3 : ordre du jalon, construction des scènes, lieu de la spécification

## Contexte

Le jalon J2b « Habillage alpha » (avant le playtest J3) doit sortir l'écran de duel de l'aspect prototype. Les zones sont posées par le code à des cotes fixes (`ui/duel_screen_layout.gd`, `DuelScreenLayout.pin`, appelé dans `ui/duel_screen.gd`), d'après les décisions 0030 et 0035 : la vraie disposition est invisible dans l'éditeur. Aucune fiche ne donne, par élément, sa taille, sa couche, sa transparence, ses états et l'asset attendu, alors que les assets générés par IA (0051) ont besoin de ces tailles.

## Options envisagées

Question 1, ordre du jalon.
- Option A : gabarit d'abord (fiche technique, scènes « en gris » au comportement inchangé, direction artistique, puis assets aux tailles de la fiche posés sans toucher aux scènes). Bénéfice : tailles fixées avant les assets. Coût : l'art arrive plus tard.
- Option B : direction artistique d'abord (ordre initial de la roadmap). Limite : les assets n'auraient pas eu de tailles fixées.

Question 2, construction des scènes.
- Option A : couches et conteneurs. Bénéfice : disposition visible et réglable dans l'éditeur, adaptée aux proportions d'écran, manière standard de Godot. Coût : chantier plus gros.
- Option B : ancres dans l'éditeur. Bénéfice : petit changement. Limite : coordonnées fixes déplacées du code à la scène ; une zone qui grandit ne pousse pas ses voisines.
- Option C : garder les zones posées par le code, avec un nouvel habillage. Bénéfice : la moins chère. Limite : disposition toujours invisible dans l'éditeur.

Question 3, lieu de la spécification.
- Option A : maquette HTML annotée et fiche vivante. Bénéfice : cotes visibles, fiche retouchable sans nouvelle décision, utilisable comme instruction de taille pour l'IA. Coût : deux documents à tenir.
- Option B : tout dans une décision. Bénéfice : plus léger. Limite : chaque retouche demanderait une nouvelle décision.

## Décision

Option A à chaque question, choisie par le créateur le 2026-10-24.

1. Ordre : fiche technique, scènes en gris sans art (comportement inchangé), direction artistique, assets générés aux tailles de la fiche.
2. Quatre `CanvasLayer` : fond (0), jeu (1), fenêtres (2 : abandon, fin, mulligan, choix), informations (3 : aperçu au survol, bulles). Dans la couche jeu : un `MarginContainer` de 16 px, puis un `HBoxContainer` de colonnes : gauche (Sources B, aperçu, Sources A), centre (main adverse, plateau, main du bas), duel (pendule B, pile ou tour, pendule A), droite (deck B, Heroes, deck A). Le plateau est dans un `AspectRatioContainer` et reste carré. Les tailles viennent de `custom_minimum_size` et du thème ; le code ne pose plus de cotes et `DuelScreenLayout` est retiré à l'étape 2b.3. Contrainte de Godot : un `CanvasLayer` coupe l'héritage du thème, donc la racine `Control` de chaque couche porte `duel_theme.tres`.
3. Maquette annotée `docs/maquettes/ecran-de-duel-gabarit.html` (nouvelle maquette, jamais réécrite ensuite) et fiche vivante `docs/fiches/ecran-de-duel.md`. Un tableau par élément : node Godot, parent, couche, taille, ancre ou place dans son conteneur, transparence (`modulate`, alpha), ordre d'affichage, états (normal, survol, enfoncé, désactivé), asset attendu (format, taille, marges 9-patch), comportement en 1280×720.

Rapports : cette décision modifie 0030 et 0035 sur la manière de poser les zones ; leurs cotes restent la référence dans le repère 1920×1080 jusqu'à ce que la fiche les recopie, puis la fiche les remplace si le créateur les change. Elle complète 0051 : la fiche donne la taille de chaque asset. Elle respecte `ui/CLAUDE.md` : thème unique, aucun `theme_override`, le parent câble ses enfants.

## Conséquences et vérification

- Étape 2b.2 : fiche et maquette annotée, validées par le créateur. Étape 2b.3 : écran reconstruit en couches et conteneurs, comportement identique, suites vertes, captures dans les deux tailles.
- Vérification : capture comparée à la maquette annotée ; redimensionnement en 1280×720 sans chevauchement ; rendu contrôlé en 1920×1080 et 1280×720.
- Réexamen si une couche `CanvasLayer` gêne le survol ou l'aperçu, ou si le playtest J3 demande une autre disposition.

## Références

- Décisions 0030 et 0035 (modifiées), 0051 (complétée), 0036 (scène principale).
- `ui/duel_screen.tscn`, `ui/duel_screen.gd`, `ui/duel_screen_layout.gd`, `ui/theme/duel_theme.tres`, `ui/CLAUDE.md`, `docs/roadmap.md` jalon J2b.
