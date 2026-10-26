# 206 · Combat

> Chapitre des règles complètes. Fait foi. Sections `206.1`, règles `206.1.1`, sous-règles `206.1.1a` ; voir [CHARTE.md](../CHARTE.md) §3 et §4. Statut : en cours d'écriture. Créé le 15 octobre 2026.

## Invariants

**206.0.1** [ACTÉ] Aucun dégât ne persiste sur une Unit ni sur un Building (décisions 0001, 0052 et 0125).

**206.0.2** [ACTÉ] La Force est la seule statistique de combat des Units et des Buildings (décision 0128 ; voir 200.2.1a).

## 206.1 Déclenchement d'un combat

**206.1.1** [ACTÉ] La pièce qui attaque est l'attaquant du combat (décision 0052 ; voir 205.1.6 et 205.2.3).

**206.1.2** [ACTÉ] La pièce attaquée est le défenseur du combat (décision 0052).

## 206.2 Comparaison des Forces

**206.2.1** [ACTÉ] Un combat compare la Force de l'attaquant à la Force du défenseur (décision 0052).

**206.2.1a** [ACTÉ] Un combat dont le défenseur est un Hero ne compare aucune Force (décision 0054 ; voir 202.3.9 et 206.4.2).

**206.2.2** [ACTÉ] La Force de chaque pièce d'un combat est lue au moment de ce combat (décision 0055).

**206.2.3** [ACTÉ] La Force lue au moment d'un combat comprend tous les modificateurs en cours (décision 0055 ; voir 206.2.2 et 206.5.1).

## 206.3 Issue du combat

**206.3.1** [ACTÉ] La pièce dont la Force est la plus faible est détruite (décision 0052 ; voir 206.2.1).

**206.3.1a** [ACTÉ] La règle 206.3.1 ne s'applique pas à un combat dont le défenseur est un Hero (décision 0054 ; voir 206.2.1a, 206.4.3 et 206.4.4).

**206.3.2** [ACTÉ] Une pièce détruite va dans la défausse du joueur à qui elle appartient (décision 0052).

**206.3.2a** [ACTÉ] Un jeton détruit ne va dans aucune défausse (décisions 0020 et 0052 ; voir 202.4.3 et 202.4.4).

**206.3.3** [ACTÉ] Si le défenseur est détruit, l'attaquant occupe la case où se trouvait le défenseur (décision 0052).

**206.3.3a** [PROVISOIRE] Si la Force de l'attaquant est égale à celle du défenseur, l'attaquant n'occupe pas la case où se trouvait le défenseur (décision 0053 ; à mesurer en playtest : tours sans combat, parties bloquées, durée de partie ; voir 206.3.6).

**206.3.4** [ACTÉ] Si l'attaquant est détruit, le défenseur reste sur sa case (décision 0052).

**206.3.4a** [PROVISOIRE] Si la Force de l'attaquant est égale à celle du défenseur, le défenseur ne reste pas sur sa case (décision 0053 ; à mesurer en playtest : tours sans combat, parties bloquées, durée de partie ; voir 206.3.6).

**206.3.5** [ACTÉ] Une pièce qui n'est pas détruite par un combat garde toute sa Force (décisions 0001 et 0052).

**206.3.6** [PROVISOIRE] Si la Force de l'attaquant est égale à celle du défenseur, l'attaquant et le défenseur sont détruits (décision 0053 ; à mesurer en playtest : tours sans combat, parties bloquées, durée de partie ; voir 206.2.1).

**206.3.7** [ACTÉ] Une Unit détruit son défenseur quand, dans un combat où elle attaque, le défenseur est détruit sans que l'Unit le soit (décision 0238 ; voir 206.3.1 et 206.3.4).

**206.3.7a** [ACTÉ] Une Unit qui attaque à égalité de Force ne détruit pas son défenseur (décision 0238 ; voir 206.3.6 et 206.3.7).

**206.3.7b** [ACTÉ] Une Unit qui attaque un Hero ne détruit pas son défenseur (décision 0238 ; voir 206.4.3 et 206.3.7).

## 206.4 Perte de PV du Hero

**206.4.1** [ACTÉ] Une Unit peut attaquer le Hero adverse comme toute autre pièce ennemie (décision 0054 ; voir 205.2.3).

**206.4.2** [ACTÉ] Un Hero attaqué perd autant de PV que la Force de l'attaquant (décision 0054 ; voir 206.2.2 et 206.2.3).

**206.4.3** [ACTÉ] Un combat dont le défenseur est un Hero ne détruit pas ce Hero (décision 0054 ; voir 206.3.1a).

**206.4.4** [ACTÉ] Un combat dont le défenseur est un Hero ne détruit pas l'attaquant (décision 0054 ; voir 206.3.1a).

**206.4.5** [ACTÉ] L'attaquant d'un Hero reste sur sa case (décision 0054 ; voir 206.3.3).

**206.4.6** [ACTÉ] Le joueur dont le Hero est attaqué ne perd la partie que si ce Hero atteint 0 PV (décision 0054 ; voir 201.1.2 et 201.1.3).

**206.4.6a** [ACTÉ] Un joueur peut aussi perdre la partie en abandonnant (décision 0058 ; voir 209.2.6).

**206.4.6b** Supprimée en édition 0.40, voir décision 0205.

**206.4.6c** [PROVISOIRE] Un joueur peut aussi perdre la partie par inactivité (décision 0205 ; valeur : 3 tours d'inactivité ; à mesurer en playtest : défaites par inactivité ; voir 209.2.10).

## 206.5 Modificateurs et auras

**206.5.1** [ACTÉ] Les modificateurs qui s'appliquent à la Force d'une même pièce s'additionnent (décision 0055).

**206.5.2** [ACTÉ] Les auras d'un combat se calculent selon les positions des pièces avant que l'attaquant entre sur la case du défenseur (décision 0055 ; voir 206.3.3).

**206.5.3** [ACTÉ] L'attaquant qui perd une aura en quittant sa case garde cette aura pour ce combat (décision 0055 ; voir 206.5.2).

**206.5.4** [ACTÉ] Une aura est un effet statique dont le résultat dépend de la position des pièces, soumis aux règles de la section 207.2 (décision 0101 ; voir 206.5.2 et 207.2.1).

**206.5.5** [ACTÉ] Une aura ne touche une pièce que tant que cette pièce remplit la condition de position de l'aura (décision 0107 ; voir 206.5.2, 206.5.4 et 207.2.7).
