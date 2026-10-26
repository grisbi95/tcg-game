# Catalogue de playtest — quatre decks, neutres et Heroes (version de travail 0.1)

> Document de travail créé le **26 octobre 2026**, à affiner. Il complète le suivi des décisions [catalogue-cartes-playtest.md](catalogue-cartes-playtest.md), qui reste la référence pour ce qui est validé ou non.
>
> Base de règles : **ruleset 0.44**, puis **0.45 à 0.48** pour les arbitrages de la section 8 (décisions 0211 à 0224, branche `docs/ordre-du-hero`, pas encore fusionnée). Ce document ne modifie aucune règle, n'est pas le catalogue officiel et ne décrit aucune carte implémentée. Il est volontairement placé hors de `docs/ruleset/`.
>
> **Statut : base de travail acceptée par le créateur** (« Très bien, cela est une très bonne réflexion de deck, consigne ça dans un doc que l'on va affiner »). Cet accord retient l'ensemble comme point de départ. Il ne fige ni les coûts, ni les Forces, ni les textes, ni les compositions de decks. Les arbitrages de la section 8 sont tranchés depuis le 26 octobre 2026 ; le marqueur ⚠️ signale les cartes qui en dépendent.

## 1. Légende

- ★ : carte issue d'une piste du créateur (section 9), reformulée dans le style du ruleset.
- ⚠️ : carte qui dépend d'une règle nouvelle des éditions 0.45 à 0.48 (section 8), tranchée mais pas encore codée.
- Échelle de valeurs reprise du deck de test : Unit sans texte, Force = coût + 1 ; Unit à texte ou à mot-clé, Force ≤ coût ; Building sans texte, Force = coût + 2 ; Building moteur, Force faible pour rester une cible.
- Toutes les valeurs sont des propositions à mesurer en playtest.

## 2. Format

- Format validé dans le suivi : **4 couleurs**, **4 Heroes** (un par couleur, hors deck, 202.3.5), **48 cartes distinctes** de deck : 9 par couleur et 12 neutres.
- Système de Hero validé dans le suivi : couleur principale fixe, seconde couleur libre, plus les neutres. Les quatre decks ci-dessous sont des listes fixes : l'écart avec la règle 201.6.3 (le Hero ne limite pas le deck) reste à traiter, sans gêner ces essais.
- Decks de **30 cartes**, **3 exemplaires** au plus (201.6.1 et 201.6.2, PROVISOIRE).
- **Répartition par type retenue par le créateur le 26 octobre 2026** :

| | Units | Spells | Buildings | Gear | Total |
|---|---|---|---|---|---|
| Par couleur (× 4) | 4 | 2 | 2 | 1 | 9 |
| Neutres | 6 | 4 | 1 | 1 | 12 |
| **Total** | **22** | **12** | **9** | **5** | **48** |

Deux Buildings par couleur donnent à chaque couleur de vrais Buildings moteurs : des Buildings dont l'effet justifie que l'adversaire veuille les détruire. La répartition précédente du suivi (4 Units, 3 Spells, 1 Building, 1 Gear par couleur) n'est pas retenue.

## 3. Heroes

Les quatre Heroes reposent sur **l'Ordre du Hero**, acté par la décision 0211 (ruleset 0.45, chapitre 211) ; un Hero porte au moins une capacité, le passif est facultatif (0212, 0218) et son texte est public (0213) :

> **Ordre** (Action ou Réaction) — *Endormez le Hero* [+ éventuellement un coût en Essence] : effet.

L'Ordre réutilise l'état endormi ou éveillé du Hero (205.5.2 et 201.4.11). Le Hero s'endort déjà quand il se déplace (205.4.7) : chaque tour, le joueur choisit entre déplacer son Hero et utiliser son Ordre. Un Hero qui n'a pas servi reste éveillé pendant le tour adverse, et un Ordre de vitesse Réaction y devient une menace visible.

| Hero | Couleur | PV | Capacité | Moment | Rôle du Hero |
|---|---|---|---|---|---|
| **Chef de guerre** | 🔴 Rouge | 13 | Ordre (Action) — Endormez le Hero : réveillez une Unit alliée adjacente au Hero. | Ton tour, à l'avant | Commandant qui monte au front |
| **Recruteuse** | 🟢 Vert | 16 | Ordre (Action) — Endormez le Hero, payez 2 Essence : créez un jeton Unit de Force 1 sur une case libre adjacente au Hero. | Ton tour, à l'arrière | Source de troupes : sa position décide où elles apparaissent |
| **Stratège** | 🟣 Violet | 15 | Ordre (Réaction) — Endormez le Hero : échangez les cases de deux Units alliées ciblées distinctes adjacentes au Hero. | Tour adverse | Menace éveillée qui rend chaque attaque incertaine |
| **Pilleuse** | 🔵 Bleu | 15 | Au début de votre tour, si vous avez une carte ou moins en main, piochez deux cartes. | Début de ton tour | Libre de bouger : sa capacité ne l'endort pas |

Points propres aux Heroes :

- **Chef de guerre** : depuis la décision 0223 (ruleset 0.48), tout Hero se déplace sur tout le plateau sans jamais attaquer ; le Chef peut donc accompagner l'assaut jusqu'au camp adverse, au risque d'y être attaqué.
- **Pilleuse** : la fatigue (209.5) est sa limite naturelle ; ses PV sont à ajuster selon le tour où son deck se vide.
- Inspirations : Recruteuse (Viktor), Pilleuse (Jinx) de Riftbound, sans reprise de leurs règles ni de leurs chiffres.

## 4. Cartes des couleurs

### 🔴 Rouge — frapper vite, frapper deux fois

| Carte | Type | Coût | Force | Texte |
|---|---|---|---|---|
| Éclaireur | Unit | 1 | 1 | Arrivée : réveillez cette Unit. |
| Pillard | Unit | 2 | 2 | Assaut 1 |
| Maraudeur | Unit | 3 | 3 | Assaut 2 |
| Furieux | Unit | 4 | 4 | Assaut 1. Arrivée : réveillez cette Unit. |
| ★ Charge | Spell, Action | 1 | — | Réveillez une Unit alliée ciblée. |
| ★ Furie ⚠️ | Spell, Action | 3 | — | Une Unit alliée ciblée a Assaut X jusqu'à la fin du tour, X étant sa Force à la résolution. |
| Forge | Building | 2 | 2 | Au début de votre tour, une Unit alliée ciblée a +2 Force jusqu'à la fin du tour. |
| Tambour de guerre | Building | 3 | 3 | Les Units alliées adjacentes à ce Building ont Assaut 1. |
| ★ Hache de guerre | Gear | 1 | — | La Unit qui porte ce Gear a Assaut 2. |

### 🟢 Vert — grandir en nombre

| Carte | Type | Coût | Force | Texte |
|---|---|---|---|---|
| Semeuse | Unit | 2 | 1 | Arrivée : créez un jeton Unit de Force 1 sur une case libre ciblée adjacente à cette Unit. |
| Porte-enseigne | Unit | 3 | 2 | Les autres Units alliées adjacentes au Porte-enseigne ont +1 Force. |
| Compagnon tenace | Unit | 3 | 3 | Dernier souffle : créez un jeton Unit de Force 1 sur une case libre ciblée de votre première rangée. |
| Ancien du bosquet | Unit | 5 | 4 | Les autres Units alliées situées dans la même rangée que cette Unit ont +1 Force. |
| Rassemblement | Spell, Action | 3 | — | Choisissez deux cases libres ciblées distinctes parmi les deux rangées les plus proches de vous. Créez un jeton Unit de Force 1 sur chacune. |
| ★ Sève ⚠️ | Spell, Réaction | 2 | — | Une Unit alliée ciblée a Rempart X jusqu'à la fin du tour, X étant sa Force à la résolution. |
| Garnison | Building | 4 | 3 | Au début de votre tour, créez un jeton Unit de Force 1 sur une case libre ciblée adjacente à ce Building, hors de la rangée centrale. |
| Chantier | Building | 3 | 2 | Au début de votre tour, créez un jeton Unit de Force 4 sur une case libre ciblée adjacente à ce Building, puis détruisez ce Building. |
| ★ Bannière | Gear | 2 | — | Les Units alliées adjacentes à l'Unit qui porte ce Gear ont +1 Force. |

Porte-enseigne, Compagnon tenace et Rassemblement sont les prototypes FJ-01, FJ-03 et FJ-02 du suivi.

### 🟣 Violet — déplacer, renvoyer, piéger

| Carte | Type | Coût | Force | Texte |
|---|---|---|---|---|
| Ombre ⚠️ | Unit | 2 | 2 | Arrivée : échangez les cases de deux Units alliées ciblées distinctes. |
| Sentinelle | Unit | 3 | 3 | Rempart 2 |
| Passeur | Unit | 3 | 2 | Arrivée : renvoyez une Unit ennemie ciblée de Force 2 ou moins dans la main de son joueur. |
| Manipulateur | Unit | 4 | 3 | Arrivée : déplacez une Unit ennemie ciblée sur une case libre ciblée adjacente à cette Unit ennemie. |
| ★ Glissement | Spell, Action | 1 | — | Déplacez une Unit ennemie ciblée sur une case libre ciblée adjacente à cette Unit. |
| Reflux | Spell, Action | 2 | — | Renvoyez une Unit ennemie ciblée de Force 3 ou moins dans la main de son joueur. |
| Obélisque | Building | 3 | 4 | Les Units ennemies adjacentes à ce Building ont −1 Force. |
| Poudrière | Building | 2 | 3 | Dernier souffle : détruisez une Unit ennemie ciblée de Force 4 ou moins adjacente à la case de ce Building. |
| ★ Cape d'ombre | Gear | 1 | — | La Unit qui porte ce Gear a Rempart 2. |

### 🔵 Bleu — piocher, lancer, répondre

| Carte | Type | Coût | Force | Texte |
|---|---|---|---|---|
| Apprenti | Unit | 2 | 2 | Chaque fois que vous annoncez un Spell, cette Unit a +1 Force jusqu'à la fin du tour. |
| Spectre des archives ⚠️ | Unit | 2 | 2 | Une fois par tour, quand vous défaussez une carte de votre main, cette Unit a +2 Force jusqu'à la fin du tour. |
| Lettré | Unit | 3 | 2 | Arrivée : piochez une carte. |
| Lame-sort | Unit | 3 | 3 | Une fois par tour, quand vous annoncez un Spell, une Unit alliée ciblée a +1 Force jusqu'à la fin du tour. |
| ★ Étude ⚠️ | Spell, Action | 1 | — | Piochez deux cartes, puis défaussez une carte de votre main. |
| ★ Contre | Spell, Réaction | 2 | — | Contrecarrez un Spell ciblé. |
| Bibliothèque | Building | 3 | 2 | Au début de votre tour, piochez une carte. |
| Observatoire | Building | 2 | 3 | Au début de votre tour, regardez la carte du dessus de votre deck ; vous pouvez la mettre sous votre deck. |
| ★ Grimoire ⚠️ | Gear | 1 | — | Quand l'Unit qui porte ce Gear détruit son défenseur, piochez une carte, puis défaussez une carte de votre main. |

## 5. Cartes neutres

| Carte | Type | Coût | Force | Texte |
|---|---|---|---|---|
| Recrue | Unit | 1 | 2 | — |
| Soldat | Unit | 2 | 3 | — |
| Gardien | Unit | 2 | 2 | Rempart 1 |
| Vétéran | Unit | 3 | 4 | — |
| Champion | Unit | 4 | 5 | — |
| Colosse | Unit | 5 | 6 | — |
| ★ Inspiration | Spell, Réaction | 1 | — | Piochez une carte. |
| ★ Renfort | Spell, Réaction | 1 | — | Une Unit alliée ciblée a +2 Force jusqu'à la fin du tour. |
| ★ Choc | Spell, Réaction | 2 | — | Une Unit ennemie ciblée a −2 Force jusqu'à la fin du tour. |
| ★ Exécution ⚠️ | Spell, Action | X | — | Détruisez une Unit ennemie ciblée de Force X ou moins. |
| Campement | Building | 3 | 4 | Avant-poste |
| ★ Trophée | Gear | 2 | — | Quand l'Unit qui porte ce Gear détruit son défenseur, elle a +1 Force tant que la pièce est en jeu. |

Recrue, Soldat, Gardien, Vétéran, Champion, Colosse, Renfort et Campement reprennent les cartes du [deck de test](ruleset/70-playtest/decks-de-test.md).

## 6. Les quatre decks

Chaque couleur sert une fois de couleur principale et une fois de seconde couleur.

### 🔴 Percée — Chef de guerre, Rouge et Violet

**Plan :** attaquer tôt, réveiller pour frapper deux fois, Glissement pour ouvrir un couloir, Furie pour finir le Hero adverse. **Faiblesses :** Hero à 13 PV, peu de cartes en fin de partie.

- **Rouge (18) :** Éclaireur ×3, Pillard ×3, Maraudeur ×2, Furieux ×2, Charge ×3, Furie ×2, Forge ×1, Hache de guerre ×2
- **Violet (3) :** Glissement ×2, Passeur ×1
- **Neutres (9) :** Recrue ×3, Soldat ×3, Renfort ×2, Campement ×1
- **Total :** 17 Units, 2 Buildings, 9 Spells, 2 Gear

### 🟢 Phalange — Recruteuse, Vert et Bleu

**Plan :** poser Garnison et Chantier, remplir le plateau de jetons, souder une ligne avec Porte-enseigne, Bannière et l'Ancien, puis avancer sur plusieurs colonnes ; le Bleu apporte des cartes pour durer. **Faiblesses :** démarrage lent, jetons perdus au moindre renvoi, moteurs exposés.

- **Vert (18) :** Semeuse ×3, Porte-enseigne ×3, Compagnon tenace ×2, Ancien du bosquet ×1, Rassemblement ×2, Sève ×2, Garnison ×2, Chantier ×1, Bannière ×2
- **Bleu (3) :** Lettré ×2, Bibliothèque ×1
- **Neutres (9) :** Soldat ×2, Gardien ×2, Vétéran ×2, Champion ×1, Choc ×2
- **Total :** 18 Units, 4 Buildings, 6 Spells, 2 Gear

### 🟣 Échiquier — Stratège, Violet et Vert

**Plan :** se retrancher derrière Sentinelles et Obélisque, échanger les défenseurs au moment où l'adversaire attaque, renvoyer et déplacer ses pièces, puis finir avec Champion et Colosse. **Faiblesses :** peu de pression avant le milieu de partie, débordé par le nombre.

- **Violet (17) :** Ombre ×3, Sentinelle ×3, Passeur ×2, Manipulateur ×2, Glissement ×2, Reflux ×2, Obélisque ×1, Poudrière ×1, Cape d'ombre ×1
- **Vert (4) :** Sève ×2, Compagnon tenace ×2
- **Neutres (9) :** Gardien ×2, Vétéran ×2, Champion ×2, Colosse ×2, Exécution ×1
- **Total :** 20 Units, 2 Buildings, 7 Spells, 1 Gear

### 🔵 Grimoire — Pilleuse, Bleu et Rouge

**Plan :** cartes bon marché, vider sa main chaque tour pour piocher deux cartes ; l'Apprenti grossit à chaque Spell, Charge et Furie donnent un tour d'attaque explosif. **Faiblesses :** corps fragiles, fatigue, dilemme entre garder une Réaction et vider sa main.

- **Bleu (16) :** Apprenti ×3, Spectre des archives ×2, Lame-sort ×2, Lettré ×1, Étude ×3, Contre ×2, Observatoire ×1, Grimoire ×2
- **Rouge (5) :** Éclaireur ×2, Charge ×2, Furie ×1
- **Neutres (9) :** Recrue ×2, Soldat ×2, Inspiration ×1, Renfort ×2, Choc ×2
- **Total :** 14 Units, 1 Building, 13 Spells, 2 Gear

### Affrontements visés (hypothèses à mesurer)

Phalange > Percée (le mur absorbe la vague) ; Percée > Grimoire (frappe avant que les Spells s'installent) ; Grimoire > Échiquier (contrecarre ses Spells et pioche davantage) ; Échiquier > Phalange (un jeton renvoyé disparaît). Les deux autres confrontations doivent rester équilibrées.

## 7. Couverture

- **Mots-clés :** les 5 (Avant-poste, Arrivée, Dernier souffle, Assaut X, Rempart X).
- **Verbes :** 12 des 13 retenus. **Endormir** est absent volontairement : une pièce endormie se réveille au début de son tour (204.3.10), le verbe a donc peu d'effet avec les règles actuelles. Il est à repenser avant usage.
- **Autres outils :** Buildings moteurs déclenchés au début du tour, jeton Unit, Gear sur Units et jetons, Réactions pendant le tour adverse, Contrecarrer, recyclage des Sources, fatigue.

## 8. Arbitrages tranchés le 26 octobre 2026

| # | Sujet | Choix du créateur | Règles | Cartes concernées |
|---|---|---|---|---|
| 1 | Ordre du Hero et effets déclenchés du Hero | Ordre : endormir le Hero, plus l'Essence indiquée ; vitesse Action ou Réaction ; déclencheurs sur tout événement ; pas d'Ordre avant le premier réveil | 0211, chapitre 211 | les 4 Heroes |
| 1b | Passif, capacité minimale, texte du Hero | Passif facultatif ; au moins une capacité ; texte du Hero public | 0212, 0218, 0213 (201.4.12, 202.3.22) | les 4 Heroes |
| 2 | Défausser | Choix à la résolution, pas une cible ; seule une défausse par Défausser compte ; plusieurs cartes choisies ensemble, une défausse par carte ; tirage au sort à l'expiration du temps | 0214, 0219, chapitre 212, 209.4.13 | Étude, Spectre des archives, Grimoire |
| 3 | Coût variable X | X choisi à l'annonce, au moins 1, Spells seulement, sans partie fixe ; X avant les cibles | 0215, 0220, 0221, chapitre 213 | Exécution |
| 4 | Valeur X définie par un texte | Lue une seule fois à la résolution ; Assaut et Rempart n'y comptent jamais | 0216, 0222, 213.2 | Furie, Sève |
| 5 | Échanger | Tout ou rien ; n'endort ni ne réveille ; ne déclenche pas Arrivée ; deux Units alliées | 0217, chapitre 214 | Ombre, Stratège |
| 6 | Bonus durable de Trophée | Gardé ; « détruit son défenseur » = l'attaquant gagne le combat (égalité et attaque d'un Hero exclues) | décision du catalogue, sans règle nouvelle (207.4.2) | Trophée |
| 7 | Limite de rangées du Hero | Levée pour tous les Heroes ; le Hero n'attaque jamais | 0223 (205.3.2 supprimée) | Chef de guerre, Recruteuse, Stratège |
| 8 | Répartition par type | 2 Buildings par couleur (22 / 12 / 9 / 5) | décision du catalogue | section 2 |
| 9 | Premier playtest | Joué avec ce catalogue, et non avec le Capitaine et les decks de test | 0224 | tout le catalogue |

Questions encore ouvertes qui touchent ce catalogue : Q-124 (expiration pendant le choix de X), Q-125 (un échange est-il un déplacement), Q-126 (Unit déployée sur la case d'un Hero adverse avancé), Q-127 à Q-131 (lieu du catalogue dans le ruleset, organisation des séries de playtest avec quatre decks).

## 9. Pistes du créateur (26 octobre 2026)

Liste d'origine, pour la traçabilité :

- **Spells :** pioche 1 ; pioche 2 défausse 1 ; réveille une Unit endormie ; contrecarre l'effet d'un sort ; déplace une Unit alliée ; déplace une Unit ennemie ; renforce de 1 Force ; affaiblit de 2 Force ; détruit un Gear attaché à une Unit ; inflige des dégâts de X Force, X étant l'Essence payée ; détruit une Unit ; donne Assaut égal à la Force de l'Unit pour le tour ; donne Rempart égal à la Force de l'Unit pour le tour.
- **Gears :** Rempart +2 ; Assaut +2 ; +1 Force par combat remporté ; Units adjacentes +1 Force ; pioche 1 défausse 1 par combat remporté ; si l'Unit meurt, le Gear est détruit à sa place et l'Unit revient sur la première rangée.

Pistes non reprises dans cette version :

- **Détruire un Gear** : trop peu de Gear dans le catalogue pour que la carte serve souvent ; un effet ne cible pas un Gear (207.5.11), il faudrait cibler l'Unit.
- **Dégâts** : le jeu n'a pas de dégâts (206.0.1 et 206.0.2) ; la piste devient Exécution. Une perte de PV directe du Hero serait un nouveau verbe et une décision de design.
- **Détruire une Unit sans condition** : couvert par Exécution avec un X élevé.
- **Gear qui sauve l'Unit** : c'est une prévention par substitution, donc le verbe Prévenir, mis de côté. Alternative jouable : « Quand l'Unit qui porte ce Gear est détruite, créez un jeton Unit de Force 2 sur une case libre ciblée de votre première rangée. »
- **Renforce de 1** : devenu Renfort (+2), plus lisible pour le même coût.

## 10. Modèles de fiche pour affiner

### Fiche carte de deck

```markdown
### [Nom provisoire]

**Statut de l'idée :** idée / à tester / retenue / écartée — **Date :**

| Champ | Valeur |
|---|---|
| Type | Unit / Building / Spell / Gear |
| Vitesse (Spell seulement) | Action / Réaction |
| Coût | |
| Force (Unit, Building) | |
| Mot-clé(s) | Avant-poste / Arrivée / Dernier souffle / Assaut X / Rempart X / aucun |
| Direction de jeu | Agressive / Contrôle / Snowball / Jetons / Pioche-défausse / Spells et Réactions |
| Deck ou couleur envisagé | |

**Texte de la carte :**
>

**Comment l'effet fonctionne**
- Verbe(s) :
- Moment : statique / à la résolution (Spell) / déclenché quand :
- Cible : aucune / pièce alliée / pièce ennemie / case / Spell sur la pile — condition :
- Durée : ponctuel / jusqu'à la fin du tour / tant que la pièce est en jeu
- Limite : aucune / une fois par tour

**Intention de jeu**
- Le choix que la carte donne au joueur :
- Pourquoi c'est fun :
- La réponse possible de l'adversaire :
- Synergies (cartes, Heroes) :

**Risques et points à vérifier**
- Risque d'équilibrage :
- Règles concernées ou question à poser au ruleset :
- Nouveauté : ✅ jouable avec les règles actuelles / ⚠️ arbitrage nécessaire / 🆕 nouveau système

**Notes de playtest**
-
```

### Fiche Hero

```markdown
### [Nom provisoire du Hero]

**Statut de l'idée :** idée / à tester / retenue / écartée — **Date :**

| Champ | Valeur |
|---|---|
| PV | |
| Couleur principale | Rouge / Vert / Violet / Bleu |
| Deck associé | |

**Capacité :**
>

- Mécanique : passif statique / déclenchée (quand : ) / Ordre (Action ou Réaction)
- Coût de l'Ordre : endormir le Hero + Essence :
- Cible et condition :

**Ce que le Hero change à la partie**
- Le moment où le joueur agit :
- Le rôle du Hero sur le plateau :
- Ce que le joueur met dans son deck à cause de lui :
- Le choix qu'il pose à chaque tour :
- Ce que l'adversaire lit et peut punir :

**Risques et points à vérifier**
- Risque d'équilibrage (PV, capacité) :
- Règles concernées ou décision nécessaire :

**Notes de playtest**
-
```

## 11. Historique

- 2026-10-26 : version de travail 0.1 — 4 Heroes, 36 cartes de couleur, 12 neutres, 4 decks de 30 cartes ; acceptée comme base à affiner.
- 2026-10-26 : arbitrages de la section 8 tranchés (ruleset 0.45 à 0.48, décisions 0211 à 0224) ; répartition par type retenue ; Ordre du Stratège précisé (Units « ciblées distinctes ») ; premier playtest joué avec ce catalogue.
