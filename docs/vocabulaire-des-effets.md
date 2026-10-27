# Vocabulaire des effets — inventaire de travail

> Inventaire de travail du **27 octobre 2026**, à valider par le créateur. Il ne vaut ni règle ni décision : le ruleset fait foi, et un point qu'il ne tranche pas reste une question de règle, jamais un comportement du moteur.
>
> Édition suivie : **ruleset 0.54**, mise à jour en **0.55** par la note de la section 5 (b), puis à la clôture de c.5c (axes T, F, P codés, décision 0062) et de c.5d (axes K et C, ensemble figé, décision 0064) et de c.5e (axes M, C, X, décision 0065) (`docs/ruleset/README.md`). Sources : `docs/catalogue-cartes-playtest.md` §2 et §3 ; chapitres 200 à 217, glossaire et questions ouvertes du ruleset ; catalogue `docs/ruleset/50-cartes/` ; `rules/catalog/` (`effect_definition.gd`, `target_spec.gd`, `effect_condition.gd`, `card_definition.gd`, `hero_definition.gd`, `hero_order.gd`, `effect_target_checks.gd`, `effect_value_checks.gd`), `rules/active_effect.gd`, `rules/keyword_rules.gd`, `rules/effect_rules.gd`, `rules/CLAUDE.md` ; décisions 0055 à 0060 ; `docs/roadmap.md` (étapes c.5c et c.6).

États : **codé** (code et tests présents) ; **codé en partie** (ce qui manque est dit) ; **à coder** (la règle existe, le code non) ; **en attente d'une règle** (le ruleset ne tranche pas). Une **pratique de rédaction** est ce que le texte de la carte dit sans capacité nouvelle du moteur (207.5.18 « ciblée », « puis », « distinctes », valeur d'un mot-clé 210.1.3) ; elle ne se code pas, elle s'écrit.

## 1. Verbes

| Verbe | Statut au catalogue | Règles du ruleset | `kind` du moteur | État |
| --- | --- | --- | --- | --- |
| Déplacer | retenu (case libre précisée) | 215.1.1 à 215.2.6 ; 207.3.14 | `MOVE_UNIT` + `destination` | codé (Units, case libre ciblée) |
| Renforcer | retenu | 206.5.1, 206.5.4, 206.5.5, 207.2, 207.4, 209.1.1 | `MODIFY_FORCE` (montant positif) | codé (cible, pièce source, portées, ensemble ; c.5c, c.5d) |
| Affaiblir | retenu | mêmes règles ; 209.1.2, 209.1.3 | `MODIFY_FORCE` (montant négatif) | codé ; Hero : Q-097 |
| Détruire | retenu | glossaire Détruire, 206.3.2, 206.3.2a, 210.3.2, 216.2.1 | `DESTROY` | codé (pièce source c.5c, déclencheur « une autre pièce est détruite » c.5e) ; Hero : Q-097 |
| Créer | retenu | 202.4.1 à 202.4.13a, 205.5.4a, 209.1.1a | `CREATE_TOKEN` | codé |
| Piocher | retenu | glossaire Piocher, 201.3.5, 201.3.6, 209.5.2, 209.5.4 | `DRAW_CARDS` | codé (X et conditions par `GameValue`, c.5e) |
| Consulter | retenu | 217.1.1 à 217.1.7, 201.4.1a (carte du dessus seulement) | `LOOK_AT_TOP_CARD` | codé (carte du dessus seulement, 217.1.8) ; 3 variantes non retenues (0247) |
| Contrecarrer | retenu | 207.6.1 à 207.6.6, 207.5.14 à 207.5.16 | `COUNTER_SPELL` | codé (filtres c.5c, déclencheur c.5e) |
| Réveiller | retenu | glossaire Réveiller, 205.5.1 à 205.5.5, 204.3.10, 204.3.11 | `WAKE` (cible ou pièce source) | codé |
| Endormir | retenu | 205.5.7 à 205.5.7c ; Hero par son Ordre : 211.2.2, 211.2.3 | `SLEEP` (cible, pièce source, ensemble) | codé (c.5c) |
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
| Renforcer/Affaiblir — temporaire | T pièce ciblée ou « cette Unit » ; D fin du tour | 207.4.2, 207.4.3, 206.5.1 | codé (cible, pièce source : c.5c) |
| Renforcer/Affaiblir — continu selon la position | P porteur, adjacentes, même rangée, ennemies | 206.5.4, 206.5.5, 207.2.8 | codé (portée `PieceFilter`, décision 0062, c.5c) |
| Renforcer/Affaiblir — déclenché | M événement nommé ; D | 207.3.1, 207.4.7 | codé |
| Détruire — directe conditionnelle | F Force bornée, X, adjacence ; C hors cible | 207.5.6, 213.1.10 | codé (filtres ; condition « si » d'un Spell, c.5d) |
| Détruire — sacrifice volontaire | T Unit alliée ciblée ou pièce source ; K | glossaire Détruire, 203.0.1 | codé (cible alliée, pièce source : c.5c) |
| Détruire — déclenché par une destruction | M destruction de cette pièce ou d'une autre | 210.3.2, 207.3.1 | codé (Dernier souffle ; autre pièce et destruction simultanée 207.3.15, c.5e) ; Gear : Q-161 |
| Détruire — synergie avec la position | M détruit son défenseur ; F adjacence à la source | 206.3.7, 207.3.14 | codé |
| Créer — simple | T case libre ciblée ; jeton Unit, Force | 202.4.8, 202.4.9, 202.4.12 | codé |
| Créer — conditionnelle | F rangées ; C | 202.4.12, 205.1.3, 205.1.4 ; 207.3.13 | codé (filtres de rangées c.5c ; condition « si » c.5d ; conditions par `GameValue` c.5e) |
| Créer — déclenchée par une destruction | M destruction | 210.3.2, 202.4.6, 207.3.1 | codé (Dernier souffle ; autre pièce, c.5e) |
| Créer — Buildings | jeton Building | 202.4.8, 202.4.11 | codé |
| Créer — par sacrifice | K créer puis détruire la source (Chantier) | 202.4.6, glossaire Détruire | codé (texte d'effets, ordre « puis » 207.7.4, « si vous le faites », c.5d, décision 0064) |
| Piocher — directe | T joueur à qui appartient l'effet | glossaire, 201.3.5, 209.5.2 | codé |
| Piocher — conditionnelle | C | 207.3.13 | codé (déclenché, main ; Spell et Ordre, c.5d) |
| Piocher — déclenchée | M | 207.3.1 | codé |
| Piocher — avec contrepartie | K piocher puis défausser (Étude) | 212.1.5, 203.0.1 | codé (suite d'effets ; « si vous le faites », c.5d) |
| Piocher — territoriale | C ou Z position de pièces | 207.3.13, 207.7.1 | codé (compte de pièces d'un `PieceFilter`, c.5e) |
| Consulter — simple | T joueur ; choix dessus ou dessous | 217.1.1 à 217.1.7 | codé |
| Consulter — avec réorganisation | plusieurs cartes, ordre choisi | 217.1.8 | non retenu (0247) |
| Consulter — avec sélection | prendre une carte en main | 217.1.8 | non retenu (0247) |
| Consulter — avec filtrage | chercher ou révéler selon un type | 201.4.1, 217.1.8 | non retenu (0247) |
| Consulter — conditionnelle | C | 217, 207.3.13, 207.7.1 | codé (condition « si » c.5d ; `GameValue` c.5e) |
| Contrecarrer — simple | T Spell de la pile | 207.6.2 | codé |
| Contrecarrer — conditionnel | F coût, vitesse du Spell ciblé | 207.5.6, 213.1.6, 207.1.2 | codé (`spell_max_cost`, `spell_speeds`, c.5c) |
| Contrecarrer — avec contrepartie | K suite d'effets | 207.5.5, 207.7.6 | codé (suite ; « si vous le faites », c.5d) |
| Contrecarrer — récompensé | K récompense après le contrecarrage | 207.5.5, 207.7.6a | codé (« si vous le faites » : pas de récompense si la cible est perdue, c.5d) |
| Contrecarrer — déclencheur | M « un Spell est contrecarré » | 207.3.1, 207.6.4 | codé (`SPELL_COUNTERED`, côté du Spell, c.5e) |
| Réveiller — simple | T Unit ou Hero ciblé | 205.5.1, 205.5.2 | codé |
| Réveiller — conditionnel | F adjacence au Hero, Force ; C | 207.5.6, 207.3.13 | codé (filtres, déclenché ; Spell, c.5d) |
| Réveiller — déclenché | M Arrivée ; T pièce source | 210.3.1 | codé |
| Réveiller — avec contrepartie | K Hero endormi par l'Ordre | 211.2.2, 211.2.3 | codé (Ordre ; carte, suite d'effets, c.5d) ; en attente (« si vous le faites » après réveiller, Q-159) |
| Endormir — simple | T Unit ou Hero ; jamais un Building | 205.5.7 à 205.5.7c | codé (`SLEEP`, c.5c) |
| Endormir — conditionnel | idem ; C | idem, 207.3.13, 207.7.1 | codé (effet, condition « si », c.5d) |
| Endormir — avec contrepartie | idem ; K | idem, 203.0.1, 207.7.6a | codé (effet, suite d'effets, c.5d) |
| Endormir — auto-endormissement | T pièce source ou Hero | 211.2.2, 205.5.7 | codé (Ordre ; carte, sujet pièce source, c.5c) |
| Défausser — simple | T joueur ; choix à la résolution | 212.1.1 à 212.1.7 | codé |
| Défausser — avec contrepartie | K jamais un coût | 212.1.5 | codé (suite d'effets) |
| Défausser — avec renouvellement | K défausser puis piocher ; X « autant » | 212.2.3, 213.2.1 | codé (nombre fixe ; X par `GameValue`, c.5e) |
| Défausser — déclencheur | M défausse, une par carte | 212.2.4, 212.2.5 | codé |
| Défausser — conditionnelle | C | 207.3.13, 207.7.1 | codé (déclenché ; Spell, c.5d) |
| Renvoyer — simple | T Unit | 216.1.1 à 216.2.2 | codé |
| Renvoyer — conditionnel | F Force, jeton exclu | 207.5.6, 216.1.3 | codé (Force, « non jeton », c.5c) |
| Renvoyer — déclenché | M | 207.3.1 | codé |
| Renvoyer — avec contrepartie | T Unit alliée ; K | 216.1.2 | codé (cible alliée ; « si vous le faites », c.5d) |
| Renvoyer — territorial | F rangée d'une pièce | 207.5.6 | codé (`PieceFilter.row`, c.5c) |
| Permuter — simple | T deux Units alliées distinctes | 214.1.3, 214.1.4, 214.2.1 | codé |
| Permuter — conditionnelle | F adjacence au Hero, Force | 207.5.6 | codé |
| Permuter — déclenchée | M Arrivée | 210.3.1 | codé |
| Permuter — avec contrepartie | K | 214.2.1 | codé (Ordre « endormez le Hero » ; carte, suite d'effets, c.5d) |
| Permuter — territoriale | F rangée d'une pièce | 207.5.6 | codé (`PieceFilter.row`, c.5c) |

## 3. Axes génériques

**T — Qui ou quoi est touché.**
- Existe : `EffectSubject` `TARGETS`, `OWNER_PLAYER`, `SOURCE_PIECE` ; `TargetWhat` `PIECE`, `CELL`, `SPELL_ON_STACK` ; pièces filtrées par `PieceFilter` (décision 0062). `SOURCE_PIECE` admis pour `WAKE`, `SLEEP`, `MODIFY_FORCE` et `DESTROY`, en effet déclenché ; pour un Gear, la pièce source est l'Unit qui le porte (207.2.8, 207.3.12) ; une pièce source partie du plateau ne subit rien (200.4.1). Codé en c.5c : Apprenti, Spectre des archives, Trophée, « détruisez ce Building ».
- Existe aussi (c.5d, décision 0064) : sujet `MATCHING_PIECES`, ensemble décrit par un `PieceFilter` et figé à la résolution (207.4.11 à 207.4.11c).
- Hero : refusé comme cible de `MODIFY_FORCE` et de `DESTROY`, comme sujet pièce source de ces deux kinds et comme porteur d'un passif de Force (`_check_passive`), tant que Q-097 est ouverte.

**F — Filtres de cible.**
- Existe (c.5c, décision 0062) : `PieceFilter` pour les pièces — `side`, `piece_kinds`, `relation` (`ANY`, `SELF`, `ADJACENT`, `SAME_ROW`) à une pièce de référence (`relative_to` : pièce source ou Hero du joueur), `include_reference` (« autres »), `tokens` (`NON_TOKEN`), `row` (`OWN_FIRST`, `OWN_NEAR`, `CENTRAL`, `NOT_CENTRAL`, 205.1) ; `max_force` (nombre ou « X ») dans `TargetSpec` ; cases : `row` aux mêmes zones, `adjacent_to` (`TARGET_PIECE`, `SOURCE_PIECE`, `OWN_HERO` rétabli à c.6 pour la Recruteuse, décision 0067), `distinct` ; Spell ciblé : `spell_max_cost` (X compris, 213.1.6) et `spell_speeds` (207.1.2) ; `count_min`, `count_max`.
- Règle : 207.5.6 juge une cible sur les conditions d'origine de la carte ; chaque filtre écrit par la carte est une pratique de rédaction.
- Manque : la règle générale de distinction (Q-098) ; `distinct` ne vaut qu'entre les cibles d'un même `TargetSpec`.

**P — Portées statiques.**
- Existe (c.5c, décision 0062) : la portée est un `PieceFilter` relatif au porteur (207.2.8), évalué par `ModifierRules` (206.5.5) : porteur, autres Units alliées adjacentes (Porte-enseigne), même rangée (Ancien du bosquet), Units ennemies adjacentes (Obélisque), Units alliées adjacentes au porteur d'un Gear (Bannière). Rien ne manque.

**M — Moments et déclencheurs.**
- Existe : `EffectTiming` `RESOLVE`, `STATIC`, `TRIGGERED` ; `TriggerEvent` `NONE`, `ARRIVAL`, `DESTROYED`, `END_OF_TURN`, `START_OF_OWN_TURN`, `OWN_SPELL_ANNOUNCED`, `OWN_CARD_DISCARDED`, `DESTROYS_DEFENDER`, `OTHER_PIECE_DESTROYED` (objet qualifié par un `PieceFilter`), `SPELL_COUNTERED` (côté du Spell) — décision 0065, c.5e ; `once_per_turn` ; Ordre (`HeroOrder` : vitesse, coût, effets `RESOLVE`) ; effets déclenchés du Hero et du Gear.
- Auteur : « vous » ou « cette pièce » seulement (décision 0060, réexamen au premier auteur adverse). Rien n'attend « adversaire » ni « quiconque » dans les variantes retenues ; 208.4.7 en règle déjà l'ordre.
- Existe aussi (c.5c) : décompte de « une fois par tour » par effet (207.3.7b, 207.3.7c).
- Existe aussi (c.5e) : destructions simultanées (207.3.15).
- En attente : Gear et « une autre pièce est détruite » (Q-161, refusé par le catalogue) ; Q-145 pour le Hero ; l'auteur d'une destruction ou d'un contrecarrage (« quand vous détruisez… ») n'est pas qualifié, aucune variante ne le demande.

**C — Conditions « si ».**
- Existe (décision 0065, c.5e) : une condition est une comparaison `{value: GameValue, comparison: AT_LEAST | AT_MOST, amount}` ; `GameValue` : taille de la main, nombre de pièces d'un `PieceFilter`, Force de la cible, cartes défaussées par l'effet précédent, X choisi, coût du Spell de l'événement ; lue à l'événement pour un texte déclenché (207.3.13 à 207.3.13b).
- Demandé : conditions de position (territorial), de pièces contrôlées, de Force, de coût, sur des Spells, des Ordres et des effets déclenchés.
- Existe aussi (c.5d, 0064) : condition « si » d'un effet d'un Spell ou d'un Ordre, lue dans l'ordre du texte (207.7.1 à 207.7.3, 211.1.5).
- En attente : une condition « si » sur un effet qui suit un autre effet dans un texte déclenché (Q-156) ; la Force de la pièce source (Q-162) ; refusées par le catalogue.
- Une condition qui borne une cible est un filtre (F, 207.5.6), pas une condition « si ».

**D — Durées.**
- Existe : `EffectDuration` `UNTIL_END_OF_TURN`, `WHILE_PIECE_IN_PLAY` ; statique sans durée (207.2.7) ; ponctuel sans durée (207.4.9).
- Règle : 207.4.2 n'admet que ces deux durées. « Jusqu'à la fin du combat » n'est pas validé. Rien ne manque pour les variantes retenues.

**X — Valeur X.**
- Existe : coût X d'un Spell (`has_x_cost`, 213.1) ; X d'un effet lu sur une `GameValue` (`x_from`, décision 0065) ; « X » admis dans `max_force` (X choisi seulement, 213.1.10) et dans `amount` de `MODIFY_FORCE`, `GRANT_KEYWORD`, `DRAW_CARDS` et `DISCARD_CARDS` (c.5e).
- Demandé : « piochez X cartes », « défaussez X », « autant que de cartes défaussées », X lu sur un compte du plateau.
- Règle : 213.1.8 (X choisi lu par l'effet) et 213.2.1 (X défini par une valeur du jeu) ; seule la Force a sa règle de lecture propre (213.2.3, 213.2.4).
- En attente : X lu sur la Force de la pièce source (Q-162, refusé par le catalogue). Une valeur nouvelle s'ajoute à `GameValue` par décision (0065).

**K — Contrepartie.**
- Ruleset : l'Essence est la seule ressource qui paie un coût (203.0.1) ; défausser n'est jamais un coût (212.1.5) ; endormir le Hero par son Ordre n'est pas un coût (211.2.3). Un sacrifice, une défausse ou un endormissement ne se paient donc jamais à l'annonce : une contrepartie est un **effet** du même texte.
- Existe : effets appliqués dans l'ordre de la définition (`resolve_all`) ; 207.5.5 jugé effet par effet ; Ordre « Endormez le Hero : » (211.2.2) avec coût en Essence (211.1.3).
- Pratique de rédaction : l'ordre écrit par « puis » (Étude, Chantier, Grimoire).
- Existe aussi (c.5d, décision 0064) : `EffectText`, ordre du texte (207.7.4), « puis » sans dépendance (207.7.5, 207.7.5a), « si vous le faites » (`if_you_do`, 207.7.6 à 207.7.6b), coût dépensé et carte en défausse si la condition est fausse (207.7.7, 207.7.8).
- En attente (Q-157 à Q-160, refusées par le catalogue) : « si vous le faites » avec une condition « si » sur le même effet ; plusieurs textes sur un Spell ou un Ordre ; « a eu lieu » pour réveiller une pièce éveillée et pour un ensemble vide.

**Z — Territorial.**
- Existe : aura (206.5.4, 206.5.5), adjacence (au Hero, à la source, à la cible), première rangée.
- Demandé : effet selon la rangée ou la zone d'une pièce ; filtre de rangée d'une pièce ; portée « même rangée ».
- Règle : 201.2.5, 205.1.2 à 205.1.4 (rangées et zones de déploiement nommées), 207.5.6 (filtres), 206.5.5 (statique).
- Existe aussi (c.5c) : filtres de rangée et portées « même rangée » (F, P). Manque : un effet ponctuel conditionné par la position (condition « si », c.5d).

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

1. Sujet pièce source pour `MODIFY_FORCE` et `DESTROY` : Apprenti, Spectre des archives, Trophée, Chantier (207.5.18, 207.3.12, 207.4.7, glossaire Détruire). Codé en c.5c, sauf l'ordre « puis » de Chantier (207.7.4, c.5d).
2. Portées statiques : autres Units alliées adjacentes, même rangée, Units ennemies adjacentes, adjacentes au porteur d'un Gear (206.5.4, 206.5.5, 207.2.8). Codé en c.5c (0062).
3. Filtres : hors rangée centrale (205.1.4), deux rangées les plus proches (205.1.3), rangée d'une pièce, « distinctes » écrit par la carte, « non jeton » (207.5.6, 202.4.1). Codé en c.5c (0062).
4. Filtres sur le Spell ciblé : coût, X compris, et vitesse (207.5.6, 213.1.6, 213.1.7, 207.1.2). Codé en c.5c.
5. Déclencheurs « une autre pièce est détruite » (207.3.1, 206.3.1) et « un Spell est contrecarré » (207.3.1, 207.6.4), auteur « vous » (0060). Codé en c.5e (0065).
6. Conditions pour les effets déclenchés (207.3.13). Codé en c.5e par `GameValue` (0065, qui modifie 0060).
7. X sur le nombre de cartes piochées ou défaussées, X lu sur une valeur du jeu (213.1.8, 213.2.1). Codé en c.5e (0065).

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
