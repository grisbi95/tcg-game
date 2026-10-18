# 209 · Contrôles d'état

> Chapitre des règles complètes. Fait foi. Sections `209.1`, règles `209.1.1`, sous-règles `209.1.1a` ; voir [CHARTE.md](../CHARTE.md) §3 et §4. Statut : en cours d'écriture. Créé le 15 octobre 2026.

## Invariants

Aucun Invariant.

## 209.1 Force nulle ou négative

**209.1.1** [ACTÉ] La Force d'une pièce est la somme de sa Force imprimée et de ses modificateurs (décision 0056 ; voir 206.2.3 et 206.5.1).

**209.1.1a** [ACTÉ] La Force que donne à un jeton l'effet qui le crée tient lieu de Force imprimée pour ce jeton (décision 0118 ; voir 200.1.1, 202.4.9 et 209.1.1).

**209.1.2** [ACTÉ] Si la somme de 209.1.1 est négative, la Force de la pièce vaut 0 (décision 0056 ; voir 209.1.1).

**209.1.3** [ACTÉ] Une pièce à Force 0 reste en jeu (décision 0056 ; voir 209.1.2).

## 209.2 Victoire et défaite

**209.2.1** [ACTÉ] La condition de 201.1.2 se vérifie après chaque effet résolu, y compris pendant la résolution de la pile (décision 0057 ; voir 201.1.2 et 208.3.1).

**209.2.2** [ACTÉ] Si un Hero atteint 0 PV, la partie s'arrête aussitôt (décision 0057 ; voir 209.2.1).

**209.2.3** [ACTÉ] Quand la partie s'arrête, le reste de la pile ne se résout pas (décision 0057 ; voir 209.2.2).

**209.2.4** [ACTÉ] Les PV d'un Hero ne descendent jamais sous 0 (décision 0057).

**209.2.5** [ACTÉ] Un joueur peut abandonner la partie à tout moment (décision 0058).

**209.2.6** [ACTÉ] Un joueur qui abandonne perd la partie (décision 0058 ; voir 209.2.5 et 201.1.3a).

**209.2.7** [ACTÉ] Quand un joueur abandonne, la partie s'arrête aussitôt (décision 0058 ; voir 209.2.5 et 209.2.3).

**209.2.8** [ACTÉ] Un joueur dont le temps est écoulé perd la partie (décision 0113 ; voir 209.4.5 et 201.1.3c).

**209.2.8a** [ACTÉ] Si le temps des deux joueurs est écoulé en même temps, la partie est nulle (décision 0133 ; voir 201.1.2b, 209.3.1 et 209.4.5).

**209.2.9** [ACTÉ] Quand le temps d'un joueur est écoulé, la partie s'arrête aussitôt (décision 0131 ; voir 209.2.8 et 209.2.3).

## 209.3 Partie nulle

**209.3.1** [ACTÉ] Si les deux Heroes atteignent 0 PV en même temps, la partie est nulle (décision 0057 ; voir 201.1.2 et 209.2.1).

## 209.4 Pendule

**209.4.1** [ACTÉ] Chaque joueur a une pendule pour toute la partie (décision 0111).

**209.4.2** [ACTÉ] La pendule d'un joueur ne tourne que quand les règles attendent une décision de lui (décisions 0111 et 0114 ; voir 209.4.4).

**209.4.2a** [ACTÉ] Aucune pendule ne tourne pendant la résolution de la pile tant qu'aucun choix n'est demandé (décision 0114 ; voir 208.3.1 et 208.3.3).

**209.4.2b** [ACTÉ] Aucune pendule ne tourne pendant les étapes du début du tour (décision 0114 ; voir 204.3.8 et 204.3.9).

**209.4.2c** [ACTÉ] Aucune pendule ne tourne pendant les étapes de la fin du tour où aucune décision n'est attendue (décision 0114 ; voir 204.5.6 et 204.5.7).

**209.4.2d** [ACTÉ] Aucune pendule ne tourne tant que les mulligans des deux joueurs ne sont pas exécutés (décision 0188 ; voir 204.2.2 et 204.2.9).

**209.4.3** [PROVISOIRE] La pendule de chaque joueur compte 10 minutes avant tout décompte (décision 0112 ; à mesurer en playtest : nombre de parties perdues au temps, durée moyenne d'une partie, temps restant en fin de partie).

**209.4.3a** [PROVISOIRE] Aucun temps ne s'ajoute à la pendule d'un joueur pendant la partie (décision 0112 ; à mesurer en playtest : nombre de parties perdues au temps, durée moyenne d'une partie, temps restant en fin de partie ; voir 209.4.3).

**209.4.4** [ACTÉ] La pendule d'un joueur tourne dès que les règles attendent une décision de lui (décision 0114 ; voir 209.4.2).

**209.4.4a** [ACTÉ] La pendule du joueur actif tourne pendant sa phase principale quand la pile est vide (décision 0114 ; voir 204.4.1 et 208.5.1).

**209.4.4b** [ACTÉ] La pendule d'un joueur tourne chaque fois qu'il peut répondre ou passer (décision 0114 ; voir 208.2.4 et 208.3.1).

**209.4.4c** [ACTÉ] La pendule d'un joueur tourne pour l'ordre de ses effets déclenchés (décision 0114 ; voir 208.4.6 et 208.4.7).

**209.4.4d** [ACTÉ] La pendule d'un joueur tourne pour le choix des cibles d'une entrée de la pile qui lui appartient (décision 0114 ; voir 207.5.1 et 207.5.2).

**209.4.4e** Supprimée en édition 0.34, voir décision 0188.

**209.4.4f** [ACTÉ] La pendule d'un joueur dont les règles attendent une décision tourne aussi pendant le passage de l'appareil d'un joueur à l'autre et pendant l'affichage des effets, dans une version du jeu sur écran (décision 0187 ; voir 209.4.2 et 209.4.4).

**209.4.4g** [ACTÉ] La pendule d'un joueur tourne pendant la fenêtre de réponse qu'on lui montre (décision 0198 ; voir 208.6.1 et 209.4.4b).

**209.4.5** [ACTÉ] Le temps d'un joueur est écoulé quand sa pendule atteint 0 minute (décision 0113 ; voir 209.4.3 et 209.2.8).

## 209.5 Compteur de fatigue

**209.5.1** [PROVISOIRE] Chaque joueur a un compteur de fatigue qui vaut 0 au début de la partie (décision 0059 ; à mesurer en playtest : tour de la première augmentation d'un compteur de fatigue, parties finies par la perte de PV de 209.5.3).

**209.5.2** [PROVISOIRE] Chaque fois qu'un joueur doit piocher une carte alors que son deck est vide, son compteur de fatigue augmente de 1 (décision 0059 ; à mesurer en playtest : tour de la première augmentation d'un compteur de fatigue, parties finies par la perte de PV de 209.5.3 ; voir 200.4.1).

**209.5.2a** [ACTÉ] Le compteur de fatigue d'un joueur augmente selon 209.5.2 même si la main de ce joueur est pleine (décision 0179 ; voir 201.3.4 et 209.5.4a).

**209.5.3** [PROVISOIRE] Chaque fois que le compteur de fatigue d'un joueur augmente, le Hero de ce joueur perd autant de PV que la nouvelle valeur de ce compteur (décision 0059 ; à mesurer en playtest : tour de la première augmentation d'un compteur de fatigue, parties finies par la perte de PV de 209.5.3 ; voir 209.5.2).

**209.5.4** [ACTÉ] Une carte non piochée à cause de la limite de main n'augmente pas le compteur de fatigue de son joueur (décision 0059 ; voir 201.3.5 et 209.5.2).

**209.5.4a** [ACTÉ] La règle 209.5.4 ne vise qu'une carte présente dans le deck de son joueur (décision 0179 ; voir 209.5.2a).
