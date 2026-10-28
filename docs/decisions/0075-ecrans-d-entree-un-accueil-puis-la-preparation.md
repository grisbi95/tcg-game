# 0075 — Écrans d'entrée : un accueil, puis la préparation

- Statut : acceptée
- Date : 2026-10-28
- Décideur : créateur du projet
- Périmètre : écrans d'entrée (`ui/setup_screen`, `ui/main_screen`, nouvelle scène d'accueil), jalon J2b, étape 2b.7a ; modifie 0036 (enchaînement des écrans)

## Contexte

Le jeu s'ouvre sur un seul panneau « Nouvelle partie » (`SetupScreen`, scène racine `ui/main.tscn`, 0036) qui mêle la partie du plan de série (0069), les decks de A et B et le premier joueur (0066), la graine, « Commencer sur cet appareil », « Créer une partie à distance » et « Rejoindre » avec un code (0049). Il est déjà aux couleurs « Vestiaire » (0070, 0071). La bible demande un cérémonial (annonce, affiche) ; le playtest J3 a besoin que partie, decks et graine restent visibles. Contraintes : aucune règle dans `ui/`, rendu en 1920×1080 et 1280×720 (0035), duel à distance inchangé, chaque écran passe par une décision (0052).

## Options envisagées

- Option A, un seul écran réorganisé : nom du jeu en haut, deux colonnes « Sur cet appareil » (partie, decks, premier joueur, graine, Commencer) et « À distance » (Créer, Rejoindre). Le plus court, un clic pour lancer ; écran chargé, sans entrée en matière.
- Option B, un accueil puis la préparation (recommandée) : accueil avec le nom du jeu en grand et deux choix, « Nouvelle partie » ou « Rejoindre » avec le champ du code ; préparation avec partie, decks, premier joueur et graine, puis « Commencer sur cet appareil », « Créer à distance » ou « Retour ». Chaque écran simple et lisible, l'accueil donne le ton de la charte ; un écran et un clic de plus avant chaque partie.
- Option C, comme B, la préparation en affiche de combat (deux decks face à face, Heroes au centre) : cérémonial fort ; bien plus long, pauvre tant que les Heroes n'ont qu'un logo (0072).

## Décision

Option B, choix du créateur le 2026-10-28.

## Conséquences et vérification

- Nouvelle scène d'accueil (composant de `ui/`, essai dans `ui/components/_try/`). `SetupScreen` garde la préparation et « Créer à distance », perd « Rejoindre », qui passe à l'accueil.
- La scène racine (0036) enchaîne accueil, préparation, duel ; « Retour » ramène à l'accueil, la fin de partie garde « Préparation ». L'attente d'un adversaire et les messages de connexion restent là où l'action est lancée (préparation pour Créer, accueil pour Rejoindre).
- Maquette `docs/maquettes/ecrans-d-entree.html` et fiche `docs/fiches/ecrans-d-entree.md` à l'étape ; habillage par le thème unique, sans `theme_override` ; aucune règle de jeu.
- Vérification : suites vertes ; scène lancée en 1920×1080 et 1280×720 ; accueil, préparation, duel, puis Rejoindre et attente vus à l'écran.
- Réexamen : si le playtest J3 trouve le clic de plus gênant, ou quand les illustrations des Heroes permettent l'option C.

## Références

0036 (modifiée), 0035, 0049, 0052, 0066, 0069, 0070, 0071, 0072 ; roadmap 2b.7a.
