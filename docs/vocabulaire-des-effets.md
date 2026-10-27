# Vocabulaire des effets — inventaire de travail

> Inventaire de travail du **27 octobre 2026**, à valider par le créateur. Il ne vaut ni règle ni décision : le ruleset fait foi, et un point qu'il ne tranche pas reste une question de règle, jamais un comportement du moteur.
>
> Édition suivie : **ruleset 0.54**, mise à jour en **0.55** par la note de la section 5 (b) (`docs/ruleset/README.md`). Sources : `docs/catalogue-cartes-playtest.md` §2 et §3 ; chapitres 200 à 217, glossaire et questions ouvertes du ruleset ; catalogue `docs/ruleset/50-cartes/` ; `rules/catalog/` (`effect_definition.gd`, `target_spec.gd`, `effect_condition.gd`, `card_definition.gd`, `hero_definition.gd`, `hero_order.gd`, `effect_target_checks.gd`, `effect_value_checks.gd`), `rules/active_effect.gd`, `rules/keyword_rules.gd`, `rules/effect_rules.gd`, `rules/CLAUDE.md` ; décisions 0055 à 0060 ; `docs/roadmap.md` (étapes c.5c et c.6).

États : **codé** (code et tests présents) ; **codé en partie** (ce qui manque est dit) ; **à coder** (la règle existe, le code non) ; **en attente d'une règle** (le ruleset ne tranche pas). Une **pratique de rédaction** est ce que le texte de la carte dit sans capacité nouvelle du moteur (207.5.18 « ciblée », « puis », « distinctes », valeur d'un mot-clé 210.1.3) ; elle ne se code pas, elle s'écrit.

## 1. Verbes

| Verbe | Statut au catalogue | Règles du ruleset | `kind` du moteur | État |
| --- | --- | --- | --- | --- |
| Déplacer | retenu (case libre précisée) | 215.1.1 à 215.2.6 ; 207.3.14 | `MOVE_UNIT` + `destination` | codé (Units, case libre ciblée) |
| Renforcer | retenu | 206.5.1, 206.5.4, 206.5.5, 207.2, 207.4, 209.1.1 | `MODIFY_FORCE` (montant positif) | codé en partie : portées statiques de c.5c, sujet « cette Unit » |
| Affaiblir | retenu | mêmes règles ; 209.1.2, 209.1.3 | `MODIFY_FORCE` (montant négatif) | codé en partie : portée sur Units ennemies (Obélisque) ; Hero : Q-097 |
| Détruire | retenu | glossaire Détruire, 206.3.2, 206.3.2a, 210.3.2, 216.2.1 | `DESTROY` | codé en partie : sujet pièce source (« détruisez ce Building »), déclencheur « une autre pièce est détruite » |
| Créer | retenu | 202.4.1 à 202.4.13a, 205.5.4a, 209.1.1a | `CREATE_TOKEN` | codé en partie : filtres de case (rangées) |
| Piocher | retenu | glossaire Piocher, 201.3.5, 201.3.6, 209.5.2, 209.5.4 | `DRAW_CARDS` | codé en partie : nombre X, conditions |
| Consulter | retenu | 217.1.1 à 217.1.7, 201.4.1a (carte du dessus seulement) | `LOOK_AT_TOP_CARD` | codé en partie : 4 variantes sur 5 en attente d'une règle |
| Contrecarrer | retenu | 207.6.1 à 207.6.6, 207.5.14 à 207.5.16 | `COUNTER_SPELL` | codé en partie : filtres sur le Spell, déclencheur |
| Réveiller | retenu | glossaire Réveiller, 205.5.1 à 205.5.5, 204.3.10, 204.3.11 | `WAKE` (cible ou pièce source) | codé |
| Endormir | retenu | état seulement : 205.5.1 à 205.5.6 ; Hero par son Ordre : 211.2.2, 211.2.3 | aucun | en attente d'une règle (verbe absent du glossaire) |
| Défausser | retenu | 212.1.1 à 212.2.5 | `DISCARD_CARDS` | codé |
| Renvoyer | retenu | 216.1.1 à 216.2.2 | `RETURN_TO_HAND` | codé (Units) |
| Permuter | retenu ; « Échanger » au ruleset | 214.1.1 à 214.2.5, 207.5.4a, 200.4.2a | `SWAP_CELLS` | codé |
| Prévenir | mis de côté | aucune | aucun | hors périmètre |
| Produire | écarté | 203 (Sources seulement) | aucun | hors périmètre |

## 2. Variantes par verbe

Axes (section 3) : **T** touché, **F** filtres, **P** portées, **M** moments et déclencheurs, **C** conditions, **D** durées, **X** valeur X, **K** contrepartie, **Z** territorial.

| Verbe — variante | Ce qu'elle demande au moteur | Règle | État |
| --- | --- | --- | --- |
| Déplacer — sur une case libre ciblée | T Unit ; F destination adjacente à la cible ou à la source | 215.1.1, 215.2.1 à 215.2.6 | codé |
| Renforcer/Affaiblir — temporaire | T pièce ciblée ou « cette Unit » ; D fin du tour | 207.4.2, 207.4.3, 206.5.1 | codé (cible) ; à coder (sujet pièce source) |
| Renforcer/Affaiblir — continu selon la position | P porteur, adjacentes, même rangée, ennemies | 206.5.4, 206.5.5, 207.2.8 | codé en partie (`BEARER`, `ADJACENT_ALLIED_UNITS`) ; à coder (autres portées) |
| Renforcer/Affaiblir — déclenché | M événement nommé ; D | 207.3.1, 207.4.7 | codé |
| Détruire — directe conditionnelle | F Force bornée, X, adjacence ; C hors cible | 207.5.6, 213.1.10 | codé (filtres) ; en attente (condition sur un Spell) |
| Détruire — sacrifice volontaire | T Unit alliée ciblée ou pièce source ; K | glossaire Détruire, 203.0.1 | codé (cible alliée) ; à coder (pièce source) |
| Détruire — déclenché par une destruction | M destruction de cette pièce ou d'une autre | 210.3.2, 207.3.1 | codé (Dernier souffle) ; en attente (autre pièce, Q-B5) |
| Détruire — synergie avec la position | M détruit son défenseur ; F adjacence à la source | 206.3.7, 207.3.14 | codé |
| Créer — simple | T case libre ciblée ; jeton Unit, Force | 202.4.8, 202.4.9, 202.4.12 | codé |
| Créer — conditionnelle | F rangées ; C | 202.4.12, 205.1.3, 205.1.4 ; 207.3.13 | à coder (filtres, déclenché) ; en attente (Spell) |
| Créer — déclenchée par une destruction | M destruction | 210.3.2, 202.4.6 | codé (Dernier souffle) ; en attente (autre pièce) |
| Créer — Buildings | jeton Building | 202.4.8, 202.4.11 | codé |
| Créer — par sacrifice | K créer puis détruire la source (Chantier) | 202.4.6, glossaire Détruire | à coder (ordre « puis ») ; en attente (« si vous le faites », Q-B2) |
| Piocher — directe | T joueur à qui appartient l'effet | glossaire, 201.3.5, 209.5.2 | codé |
| Piocher — conditionnelle | C | 207.3.13 | codé (déclenché, main) ; en attente (Spell, Ordre) |
| Piocher — déclenchée | M | 207.3.1 | codé |
| Piocher — avec contrepartie | K piocher puis défausser (Étude) | 212.1.5, 203.0.1 | codé (suite d'effets) ; en attente (dépendance) |
| Piocher — territoriale | C ou Z position de pièces | 207.3.13 seul | à coder (déclenché) ; en attente (Spell) |
| Consulter — simple | T joueur ; choix dessus ou dessous | 217.1.1 à 217.1.7 | codé |
| Consulter — avec réorganisation | plusieurs cartes, ordre choisi | aucune | en attente d'une règle |
| Consulter — avec sélection | prendre une carte en main | aucune | en attente d'une règle |
| Consulter — avec filtrage | chercher ou révéler selon un type | aucune (201.4.1) | en attente d'une règle |
| Consulter — conditionnelle | C | 217, 207.3.13 | à coder (déclenché) ; en attente (Spell) |
| Contrecarrer — simple | T Spell de la pile | 207.6.2 | codé |
| Contrecarrer — conditionnel | F coût, vitesse du Spell ciblé | 207.5.6, 213.1.6, 207.1.2 | à coder |
| Contrecarrer — avec contrepartie | K suite d'effets | 207.5.5 | codé (suite) ; en attente (dépendance) |
| Contrecarrer — récompensé | K récompense après le contrecarrage | 207.5.5 | en attente (récompense si la cible est perdue, Q-B2) |
| Contrecarrer — déclencheur | M « un Spell est contrecarré » | 207.3.1, 207.6.4 | à coder |
| Réveiller — simple | T Unit ou Hero ciblé | 205.5.1, 205.5.2 | codé |
| Réveiller — conditionnel | F adjacence au Hero, Force ; C | 207.5.6, 207.3.13 | codé (filtres, déclenché) ; en attente (Spell) |
| Réveiller — déclenché | M Arrivée ; T pièce source | 210.3.1 | codé |
| Réveiller — avec contrepartie | K Hero endormi par l'Ordre | 211.2.2, 211.2.3 | codé (Ordre) ; en attente (carte, Q-B2) |
| Endormir — simple | T Unit ou Hero ; jamais un Building | 205.5.5, 205.5.6 | en attente d'une règle |
| Endormir — conditionnel | idem ; C | idem | en attente d'une règle |
| Endormir — avec contrepartie | idem ; K | idem, 203.0.1 | en attente d'une règle |
| Endormir — auto-endormissement | T pièce source ou Hero | 211.2.2 (Ordre seulement) | codé (Ordre) ; en attente (carte) |
| Défausser — simple | T joueur ; choix à la résolution | 212.1.1 à 212.1.7 | codé |
| Défausser — avec contrepartie | K jamais un coût | 212.1.5 | codé (suite d'effets) |
| Défausser — avec renouvellement | K défausser puis piocher ; X « autant » | 212.2.3, 213.2.1 | codé (nombre fixe) ; à coder (X lu) |
| Défausser — déclencheur | M défausse, une par carte | 212.2.4, 212.2.5 | codé |
| Défausser — conditionnelle | C | 207.3.13 | codé (déclenché) ; en attente (Spell) |
| Renvoyer — simple | T Unit | 216.1.1 à 216.2.2 | codé |
| Renvoyer — conditionnel | F Force, jeton exclu | 207.5.6, 216.1.3 | codé (Force) ; à coder (« non jeton ») |
| Renvoyer — déclenché | M | 207.3.1 | codé |
| Renvoyer — avec contrepartie | T Unit alliée ; K | 216.1.2 | codé (cible alliée) ; en attente (dépendance) |
| Renvoyer — territorial | F rangée d'une pièce | 207.5.6 | à coder |
| Permuter — simple | T deux Units alliées distinctes | 214.1.3, 214.1.4, 214.2.1 | codé |
| Permuter — conditionnelle | F adjacence au Hero, Force | 207.5.6 | codé |
| Permuter — déclenchée | M Arrivée | 210.3.1 | codé |
| Permuter — avec contrepartie | K | 214.2.1 | codé (Ordre « endormez le Hero ») ; en attente (carte) |
| Permuter — territoriale | F rangée d'une pièce | 207.5.6 | à coder |

## 3. Axes génériques

**T — Qui ou quoi est touché.**
- Existe : `EffectSubject` `TARGETS`, `OWNER_PLAYER`, `SOURCE_PIECE` ; `TargetWhat` `PIECE`, `CELL`, `SPELL_ON_STACK` ; `TargetSide` `ANY`, `ALLY`, `ENEMY` ; `piece_kinds` parmi `HERO`, `UNIT`, `BUILDING`.
- Limite : `SOURCE_PIECE` n'est admis que pour `WAKE`, et seulement pour un effet déclenché (`_subjects_for_kind`) ; `OWNER_PLAYER` que pour piocher, défausser et regarder.
- Demandé : « cette Unit a +N Force » (Apprenti, Spectre des archives), « elle » pour l'Unit qui porte le Gear (Trophée), « détruisez ce Building » (Chantier). Règles : 207.5.18, 207.3.12, glossaire Détruire.
- Manque : sujet pièce source pour `MODIFY_FORCE` et `DESTROY` ; filtre « jeton » ou « non jeton » ; effet sur un ensemble sans « ciblée » (« les Units ennemies »), que 207.5.18 permet d'écrire sans dire quand l'ensemble se fixe (Q-B6).
- Hero : `_check_hero_target` refuse un Hero comme cible de `MODIFY_FORCE` et de `DESTROY` tant que Q-097 est ouverte.

**F — Filtres de cible.**
- Existe : `max_force` (nombre ou « X »), `row` `ANY` et `OWN_FIRST` (cases seulement), `adjacent_to` `NONE`, `TARGET_PIECE`, `OWN_HERO`, `SOURCE_PIECE`, `count_min` et `count_max` ; pièces distinctes contrôlées pour l'échange seulement.
- Demandé (c.5c et variantes) : hors rangée centrale (205.1.4), deux rangées les plus proches (205.1.3), rangée d'une pièce (territorial), « distinctes » sur des cases (Rassemblement), coût ou vitesse d'un Spell ciblé.
- Règle : 207.5.6 juge une cible sur les conditions d'origine de la carte ; chaque filtre écrit par la carte est une pratique de rédaction que le moteur doit savoir lire.
- Manque : les valeurs de `CellRow` et un `row` pour les pièces ; un drapeau « distinctes » générique ; des filtres sur `SPELL_ON_STACK` ; la règle générale de distinction (Q-098).

**P — Portées statiques.**
- Existe : `StaticScope` `NONE`, `BEARER`, `ADJACENT_ALLIED_UNITS` (Force et mot-clé accordé).
- Demandé (c.5c) : autres Units alliées adjacentes (Porte-enseigne), même rangée (Ancien du bosquet), Units ennemies adjacentes (Obélisque), Units alliées adjacentes au porteur d'un Gear (Bannière).
- Règle : 206.5.4, 206.5.5, 207.2.2, 207.2.8. Manque : ces quatre valeurs ; rien n'attend une règle.

**M — Moments et déclencheurs.**
- Existe : `EffectTiming` `RESOLVE`, `STATIC`, `TRIGGERED` ; `TriggerEvent` `NONE`, `ARRIVAL`, `DESTROYED`, `END_OF_TURN`, `START_OF_OWN_TURN`, `OWN_SPELL_ANNOUNCED`, `OWN_CARD_DISCARDED`, `DESTROYS_DEFENDER` ; `once_per_turn` ; Ordre (`HeroOrder` : vitesse, coût, effets `RESOLVE`) ; effets déclenchés du Hero et du Gear.
- Auteur : « vous » ou « cette pièce » seulement (décision 0060, réexamen au premier auteur adverse). Rien n'attend « adversaire » ni « quiconque » dans les variantes retenues ; 208.4.7 en règle déjà l'ordre.
- Manque, règle existante : « une autre pièce est détruite » (207.3.1, glossaire Détruire), « un Spell est contrecarré » (207.3.1, 207.6.4).
- Manque, en attente : une pièce détruite en même temps que celle dont elle attend la destruction (Q-B5) ; une carte à plusieurs effets déclenchés avec « une fois par tour », que le code refuse sans règle (Q-B7) ; Q-145 pour le Hero.

**C — Conditions « si ».**
- Existe : `ConditionKind` `HAND_SIZE_AT_MOST`, lue à l'événement, pour un effet déclenché seulement (207.3.13 à 207.3.13b ; décision 0060, vocabulaire fermé, réexamen à la troisième condition).
- Demandé : conditions de position (territorial), de pièces contrôlées, de Force, de coût, sur des Spells, des Ordres et des effets déclenchés.
- Manque : chaque nouvelle `ConditionKind` (à coder pour un effet déclenché) ; toute condition sur un effet non déclenché (Q-B1).
- Une condition qui borne une cible est un filtre (F, 207.5.6), pas une condition « si ».

**D — Durées.**
- Existe : `EffectDuration` `UNTIL_END_OF_TURN`, `WHILE_PIECE_IN_PLAY` ; statique sans durée (207.2.7) ; ponctuel sans durée (207.4.9).
- Règle : 207.4.2 n'admet que ces deux durées. « Jusqu'à la fin du combat » n'est pas validé. Rien ne manque pour les variantes retenues.

**X — Valeur X.**
- Existe : coût X d'un Spell (`has_x_cost`, 213.1) ; `XSource` `NONE`, `CHOSEN`, `TARGET_FORCE` ; « X » admis dans `max_force` et dans `amount` de `MODIFY_FORCE` et `GRANT_KEYWORD`.
- Demandé : « piochez X cartes », « défaussez X », « autant que de cartes défaussées », X lu sur un compte du plateau.
- Règle : 213.1.8 (X choisi lu par l'effet) et 213.2.1 (X défini par une valeur du jeu) ; seule la Force a sa règle de lecture propre (213.2.3, 213.2.4).
- Manque : `amount` « X » pour piocher et défausser ; une `XSource` par valeur lue (à coder, une par carte).

**K — Contrepartie.**
- Ruleset : l'Essence est la seule ressource qui paie un coût (203.0.1) ; défausser n'est jamais un coût (212.1.5) ; endormir le Hero par son Ordre n'est pas un coût (211.2.3). Un sacrifice, une défausse ou un endormissement ne se paient donc jamais à l'annonce : une contrepartie est un **effet** du même texte.
- Existe : effets appliqués dans l'ordre de la définition (`resolve_all`) ; 207.5.5 jugé effet par effet ; Ordre « Endormez le Hero : » (211.2.2) avec coût en Essence (211.1.3).
- Pratique de rédaction : l'ordre écrit par « puis » (Étude, Chantier, Grimoire).
- En attente : aucune règle ne fixe l'ordre des effets d'un même texte ni ne permet « si vous le faites » ; un effet dont la cible est perdue n'empêche pas les suivants, ce qui rend une contrepartie gratuite (Q-B2).

**Z — Territorial.**
- Existe : aura (206.5.4, 206.5.5), adjacence (au Hero, à la source, à la cible), première rangée.
- Demandé : effet selon la rangée ou la zone d'une pièce ; filtre de rangée d'une pièce ; portée « même rangée ».
- Règle : 201.2.5, 205.1.2 à 205.1.4 (rangées et zones de déploiement nommées), 207.5.6 (filtres), 206.5.5 (statique).
- Manque : filtres et portées à coder (F, P) ; un effet ponctuel conditionné par la position attend Q-B1.

## 4. Mots-clés

| Mot-clé | Règles | Code | Ce que les variantes demandent |
| --- | --- | --- | --- |
| Avant-poste | 210.2.1, 210.2.1a | codé (`KeywordRules.is_outpost_cell`) | rien de plus ; un jeton peut le recevoir (202.4.13a), aucune variante ne le demande |
| Arrivée | 210.3.1 à 210.3.1c | codé (`ARRIVAL`, exigé avec le mot-clé) | déclencheur des variantes déclenchées ; accordé à un jeton (202.4.13a, Q-067) non demandé |
| Dernier souffle | 210.3.2 à 210.3.2c, 216.2.2 | codé (`DESTROYED`) | idem ; ne se déclenche pas sur un renvoi |
| Assaut X | 210.4.1 à 210.4.1c, 213.2.4 | codé ; accordé par `GRANT_KEYWORD` (durée, Gear, aura), X lu sur la Force | rien de plus |
| Rempart X | 210.4.2 à 210.4.2c, 213.2.4 | codé ; accordé comme Assaut | rien de plus |

Un mot-clé accordé n'est codé que pour Assaut et Rempart (décision 0058). Aucun intitulé du catalogue (« sacrifice », « territorial ») n'est un mot-clé : les cinq du chapitre 210 restent les seuls.

## 5. Synthèse

### (a) Prêt à coder, la règle existe

1. Sujet pièce source pour `MODIFY_FORCE` et `DESTROY` : Apprenti, Spectre des archives, Trophée, Chantier (207.5.18, 207.3.12, 207.4.7, glossaire Détruire).
2. Portées statiques : autres Units alliées adjacentes, même rangée, Units ennemies adjacentes, adjacentes au porteur d'un Gear (206.5.4, 206.5.5, 207.2.8).
3. Filtres : hors rangée centrale (205.1.4), deux rangées les plus proches (205.1.3), rangée d'une pièce, « distinctes » écrit par la carte, « non jeton » (207.5.6, 202.4.1).
4. Filtres sur le Spell ciblé : coût, X compris, et vitesse (207.5.6, 213.1.6, 213.1.7, 207.1.2).
5. Déclencheurs « une autre pièce est détruite » (207.3.1, 206.3.1) et « un Spell est contrecarré » (207.3.1, 207.6.4), auteur « vous » (0060).
6. Nouvelles `ConditionKind` pour les effets déclenchés, une par carte (207.3.13, 0060).
7. X sur le nombre de cartes piochées ou défaussées, X lu sur une valeur du jeu (213.1.8, 213.2.1).

### (b) À trancher dans le ruleset avant tout code

> Tranchées le 27 octobre 2026, édition 0.55 du ruleset : Q-B1 = Q-148 (décision de design 0244 ; lecture précisée par 0251, Q-155), Q-B2 = Q-149 (0245, « si vous le faites »), Q-B3 = Q-150 (0246, Endormir), Q-B4 = Q-151 (0247, 217 seul), Q-B5 = Q-152 (0248), Q-B6 = Q-153 (0249 ; ensemble figé, 0253), Q-B7 = Q-154 (0250, décompte par effet) ; coût dépensé quand la condition est fausse (0252). Règles nouvelles : 205.5.7 à 205.5.7c, 207.3.7b, 207.3.7c, 207.3.15, 207.4.11 à 207.4.11c, 207.7.1 à 207.7.8, 211.1.5, 217.1.8. Restent ouvertes : Q-097, Q-098, Q-145, Q-147. Les états « en attente d'une règle » des sections 1 et 2 qui dépendaient de ces questions passent à « à coder », sauf Consulter au-delà de la carte du dessus (non retenu, 0247).

- **Q-B1** Quand se lit la condition « si » d'un effet qui n'est pas déclenché (Spell, Ordre), et que fait cet effet si elle est fausse ? 207.3.13 ne vise que l'effet déclenché. Touche toutes les variantes conditionnelles et territoriales.
- **Q-B2** Un effet d'un texte peut-il dépendre d'un autre (« si vous le faites »), dans quel ordre s'appliquent les effets d'un même texte, et l'effet suivant a-t-il lieu quand le premier a perdu ses cibles (207.5.5) ? Touche toutes les contreparties et le contrecarrage récompensé.
- **Q-B3** Que fait « Endormir » appliqué par un effet à une Unit ou à un Hero ? Le glossaire définit Réveiller, pas Endormir ; 205.5 ne décrit que l'état et 211.2.2 le seul cas de l'Ordre.
- **Q-B4** Que permet « Consulter » au-delà de la carte du dessus (217) : plusieurs cartes, réordonner, prendre en main, chercher ou révéler selon un type, information donnée à l'adversaire (201.4.1) ?
- **Q-B5** Un effet déclenché par la destruction d'une autre pièce se déclenche-t-il quand sa pièce est détruite en même temps (206.3.6) ? 207.3.3 ne couvre que l'effet déjà déclenché.
- **Q-097** (existante) Un effet de Force ou de destruction peut-il viser un Hero ? Touche Affaiblir et Détruire.
- **Q-098** (existante) Une même cible peut-elle être désignée deux fois ? Touche les effets à plusieurs cibles.
- **Q-147** (existante) La dernière case d'une pièce ciblée partie vaut-elle pour une destination ? Touche Déplacer.
- **Q-B6** Quand se fixe l'ensemble des pièces d'un effet ponctuel ou à durée qui ne cible pas (« les Units ennemies ont −1 Force jusqu'à la fin du tour ») ?
- **Q-B7** Une carte peut-elle porter « une fois par tour » avec plusieurs effets déclenchés ? 207.3.5 et 207.3.7 décomptent par carte ; le code refuse ce cas.
- **Q-145** (existante) Les déclencheurs impossibles sur une carte Hero sont-ils interdits ?
- Seulement si le créateur les veut : renvoyer un Building (216 ne vise que l'Unit) ; une perte de PV comme contrepartie (aucune règle d'effet).

### (c) Hors périmètre

- Prévenir (mis de côté) et Produire (écarté, 203 inchangé).
- Non sélectionnés : renforcement persistant suivi un à un, contrecarrage contre un paiement offert à l'adversaire, réveil territorial et différé, endormissement déclenché et territorial, défausse adverse, défausse aléatoire, jeu depuis la défausse, renvoi à l'Arrivée, permutation alliée–ennemie, DEP-01 à DEP-10.
- Exclus par le ruleset : déplacement sur une case occupée (215.1.1, 215.2.6), échange avec une Unit ennemie (214.1.3), faire défausser l'adversaire (212.1.2), toute contrepartie payée comme un coût (203.0.1, 212.1.5), durée « jusqu'à la fin du combat » (207.4.2), mot-clé nouveau (210).

### Taille des blocs

- (a) **moyen** : extensions d'enums et de filtres dans des modules existants, un test par règle ; aucun système nouveau, sauf peut-être le drapeau « distinctes » et les filtres de Spell.
- (b) **gros** : Q-B1, Q-B2 et Q-B4 sont des systèmes de règles ; Q-B3, Q-B5, Q-B6 et Q-B7 sont petits ; Q-097, Q-098 et Q-147 ont déjà leurs options.
- (c) **nul** à coder ; à garder hors du moteur.
