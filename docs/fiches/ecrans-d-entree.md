# Fiche technique des écrans d'entrée

> **Rôle** : spécification vivante de l'accueil et de la préparation (décisions 0052 et 0075). Elle donne, pour chaque élément, son node Godot, sa taille, sa place, ses états et l'asset attendu. Maquette de référence : [maquettes/ecrans-d-entree.html](../maquettes/ecrans-d-entree.html). Cotes dans le repère 1920×1080 ; rendu vérifié aussi en 1280×720 (0035). **Version 1 du 28 octobre 2026.**

## 1. Enchaînement

`MainScreen` (`ui/main.tscn`, 0036 modifiée par 0075) n'affiche qu'un écran à la fois :

- au lancement : **accueil** ;
- accueil, « Nouvelle partie » : **préparation** ;
- préparation, « Retour » : **accueil** ;
- préparation, « Commencer sur cet appareil » : duel local ;
- préparation, « Créer une partie à distance » : attente sur la préparation, puis duel (le créateur joue A, 0050) ;
- accueil, « Rejoindre » : attente sur l'accueil, puis duel (B) ;
- fin de partie, « Préparation », ou connexion perdue pendant un duel : **préparation** ;
- connexion perdue pendant l'attente : l'écran de l'attente, avec le message.

Pendant une attente, les choix de l'écran sont grisés, « Annuler » est visible et arrête la connexion ; « Retour » est caché.

## 2. Accueil (`HomeScreen`, `ui/home_screen.tscn`)

| ID | Élément | Node | Taille | Place | États | Asset attendu |
| --- | --- | --- | --- | --- | --- | --- |
| H01 | Table | `ColorRect` plein écran | 1920×1080 | fond | — | `ui/table.webp` (fiche de l'écran de duel, E01) |
| H02 | Titre « TOURNOI » (provisoire) | `Label`, variation `HomeTitleLabel` | Archivo noir 120, capitales espacées, papier `#efe5cf`, ombre d'encre décalée de 6 px | centré, haut à y 250 | — | aucun (texte posé par Godot) |
| H03 | Sous-titre « DUEL SUR UN SOL DE 5 × 5 » | `Label`, variation `HomeSubtitleLabel` | Archivo 22, capitales espacées, gris `#8b8274` | centré sous le titre, écart 8 | — | — |
| H04 | Panneau | `PanelContainer`, variation `ModalPanel` | 500 de large, hauteur du contenu, marge 32 | centré, haut à y 560 | — | `ui/modal_panel.png` |
| H05 | « Nouvelle partie » | `Button`, variation `MainButton` | 436×64 | haut du panneau | normal, survol, enfoncé (papier, encre) | `ui/button_main_{normal,hover,pressed}.png` |
| H06 | « REJOINDRE UNE PARTIE » | `Label`, variation `ModalSectionLabel` | Archivo 18, capitales espacées, gris | centré, 28 sous H05 | — | — |
| H07 | Code | `LineEdit`, variation `ModalLineEdit` | 264×64, 4 caractères, majuscules | rangée avec H08, écart 12 | modifiable, grisé pendant l'attente | — |
| H08 | « Rejoindre » | `Button`, variation `ModalButton` | 160×64 | à droite de H07 | désactivé tant que le code n'a pas 4 caractères | `ui/button_modal_*.png` |
| H09 | Message | `Label`, variation `ModalMutedLabel` | Archivo 18, gris, centré, retour à la ligne | sous la rangée, écart 16 | vide, connexion, attente, erreur | — |
| H10 | « Annuler » | `Button`, variation `ModalButton` | 200×56 | sous H09 | visible pendant l'attente seulement | `ui/button_modal_*.png` |

## 3. Préparation (`SetupScreen`, `ui/setup_screen.tscn`)

Panneau `ModalPanel` de 800 de large, centré, haut à y 150, marge 32 ; rangées `ModalRow` (libellé de 170, champ du reste), écart 18.

| ID | Élément | Node | Taille | États |
| --- | --- | --- | --- | --- |
| P01 | « Nouvelle partie » | `Label`, variation `ModalTitleLabel` | Archivo 40, centré | — |
| P02 | Partie | `OptionButton`, variation `ModalOptionButton` | reste de la rangée × 44 | partie libre ou partie du plan (0069) |
| P03 | Joueur A, Joueur B | libellé à la couleur du joueur, `OptionButton` | idem | imposés par une partie du plan, libres sinon (0066) |
| P04 | Commence | `OptionButton` | idem | idem |
| P05 | Graine | `LineEdit`, variation `ModalLineEdit` | 300×44 | entier positif, 18 chiffres au plus |
| P06 | « Commencer sur cet appareil » | `Button`, variation `MainButton` | 736×64 | normal, survol, enfoncé, désactivé |
| P07 | « Créer une partie à distance » | `Button`, variation `ModalButton` | 736×64 | idem |
| P08 | Message | `Label`, variation `ModalMutedLabel` | centré, deux lignes | code de la partie et attente, erreur |
| P09 | « Retour » | `Button`, variation `ModalGhostButton` | 736×52 | caché pendant l'attente |
| P10 | « Annuler » | `Button`, variation `ModalButton` | 200×56 | visible pendant l'attente seulement |

## 4. Assets attendus

Aucun fichier n'est exigé : le thème dessine tout (0071). Les images ci-dessus remplacent le dessin dès leur dépôt dans `assets/`, avec leur ligne au registre.

## 5. Journal

- 2026-10-28 : version 1, étape 2b.7a (0075).
