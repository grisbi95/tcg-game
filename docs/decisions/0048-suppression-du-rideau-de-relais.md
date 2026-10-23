# 0048 — Suppression du rideau de relais

- Statut : acceptée
- Date : 2026-10-23
- Décideur : créateur du projet
- Périmètre : relais entre joueurs sur un même appareil (`ui/`, `app/`)

## Contexte

En duel à deux humains sur le même appareil, la décision 0036 (point 2) affiche un rideau « Joueur X, à vous / Voir ma main » sur la main du bas à chaque changement de joueur : début de tour, chaque fenêtre de réponse (deux relais par carte annoncée, 208.6.6), appel du premier joueur, entre les mulligans de A et B (204.2.3). Le créateur le trouve trop lourd. Le duel à distance (0043, étape 2.8, chacun son navigateur) cachera les mains par lui-même ; le mode même appareil sert surtout au développement et de repli.

## Options envisagées

- Option A : supprimer le rideau partout. Bénéfice : l'écran passe directement au joueur attendu, jeu bien plus fluide ; changement petit (l'écran confirme le relais tout seul, comme pour les intentions scriptées). Coût : sur un même appareil, chacun voit la main de l'autre. Limite : sans gêne une fois le duel à distance en place.
- Option B : rideau optionnel à l'écran de préparation, désactivé par défaut. Bénéfice : fluide au quotidien, rideau gardé pour un playtest sur un seul écran. Coût : un réglage de plus, code et tests pour les deux cas ; rideau à entretenir pour peu d'usage.

## Décision

Option A, choisie par le créateur le 2026-10-23 (recommandée).

## Conséquences et vérification

- Le point 2 de 0036 est modifié ; son corps n'est pas réécrit.
- Interface seulement : aucune règle du ruleset ne change. L'état RELAY de `DuelHost` peut subsister (l'hôte reste neutre) ; `DuelScreen` confirme le relais aussitôt et affiche la main du joueur attendu.
- `RelayCurtainView`, son essai `ui/components/_try/try_relay_curtain_view.*` et leur câblage dans `DuelOverlays` sont retirés ; `ui/theme/duel_palette.gd` ne mentionne plus le rideau.
- Le temps qui s'écoule pendant le passage de l'appareil (209.4.4f) reste vrai ; le passage devient instantané à l'écran.
- La dette du backlog « grand bouton du joueur précédent visible derrière le rideau » disparaît.
- Le mode à distance (0043) n'est pas touché.
- Vérification : un duel sur un même appareil enchaîne les changements de joueur sans rideau, la main affichée est celle du joueur attendu.
- Réexamen : si un playtest sur un seul écran a besoin de cacher les mains (retour à l'option B).

## Références

- Décisions 0036 (point 2), 0043, 0020, 0029.
- Règles 204.2.3, 208.6.6, 209.4.4f.
