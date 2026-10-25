# Catalogue de cartes de playtest — suivi des décisions

> Journal de conception mis à jour au **25 octobre 2026**. Source : conversation [« Catalogue cartes playtest »](https://chatgpt.com/c/6adb1614-aacc-83eb-a890-d8e3c5293c81), échanges des 23 et 24 octobre 2026.
>
> Référence officielle initiale : **ruleset 0.43**, sur `main` au commit [`e6edfb56b8ef2cfbfda7720603a03b3b38b56030`](https://github.com/grisbi95/tcg-game/commit/e6edfb56b8ef2cfbfda7720603a03b3b38b56030).
>
> Vérification du 25 octobre 2026 : **ruleset 0.44**, sur `main` au commit [`a120d8f83fe333a121a726e960a37de096bbe9b4`](https://github.com/grisbi95/tcg-game/commit/a120d8f83fe333a121a726e960a37de096bbe9b4). Cette édition ajoute le caractère public de l'état endormi ou éveillé (201.4.11). La branche conserve sa base initiale ; aucun changement de `main` n'y est fusionné.
>
> Ce fichier conserve les choix de conception et les sujets ouverts. Il ne modifie aucune règle, ne constitue pas le catalogue officiel et ne valide aucune implémentation. Il est volontairement placé hors de `docs/ruleset/`.

## 1. Comment lire ce suivi

- **Retenu pour le catalogue** : choix exprimé par le créateur dans la conversation. Pour les verbes, il s'agit d'expérimentations à concevoir et tester, pas de cartes finalisées.
- **Proposé / en attente** : idée de l'assistant sans validation correspondante du créateur. Une recommandation, un exemple ou une case précochée ne vaut pas validation.
- **Non sélectionné à ce stade** : proposition absente de la sélection explicite ; cela ne signifie pas rejet définitif.
- **Règle officielle** : disposition effectivement présente dans le ruleset consulté. Les statuts ACTÉ et PROVISOIRE restent ceux du ruleset.

**Le ruleset officiel reste prioritaire.** Une sélection de variantes n'approuve ni leurs exemples chiffrés, ni leurs coûts, ni leurs cibles, ni une nouvelle procédure de résolution. Les textes futurs doivent respecter les règles existantes ; un manque réel ou une contradiction nécessite un arbitrage ultérieur dans le workflow du ruleset.

Repères : [README du ruleset](ruleset/README.md), [règles complètes](ruleset/20-regles-completes/), [glossaire](ruleset/01-glossaire.md), [questions ouvertes](ruleset/02-questions-ouvertes.md). Le rapport entre texte d'une carte, règles et Invariants reste celui du [chapitre 200](ruleset/20-regles-completes/200-regles-d-or.md), notamment 200.2.1 et 200.2.1a.

## 2. Cadrage retenu

### Finalité et taille

Le créateur précise que le travail porte sur les **premiers catalogues de playtest**, et non sur le premier set de la version officielle. L'objectif est d'explorer des manières de jouer et des synergies suffisamment différentes.

Le « ok » donné après la proposition de format, puis sa récapitulation dans le fil, retiennent comme base de travail :

- **4 couleurs** : Rouge, Vert, Violet et Bleu.
- **4 Heroes**, un par couleur principale.
- **48 cartes distinctes de deck** : 9 par couleur, soit 36 colorées, et 12 neutres.
- **6 associations bicolores** : Rouge–Vert, Rouge–Violet, Rouge–Bleu, Vert–Violet, Vert–Bleu, Violet–Bleu.
- Des decks de **30 cartes**, avec **3 exemplaires maximum** d'une même carte. Ces deux valeurs sont PROVISOIRE dans les règles 201.6.1 et 201.6.2.

Les 4 Heroes sont comptés séparément des 48 cartes de deck : le Hero est hors deck selon 202.3.5. Avec cette répartition, deux couleurs et les neutres donnent accès à 30 références distinctes ; ce nombre ne désigne pas la liste des 30 exemplaires effectivement choisis pour un deck.

Les premières suggestions de 36 cartes / 3 Heroes et de 42 cartes / 3 couleurs sont remplacées comme base de travail par le format ci-dessus. Orange–Domination et Jaune–Cohésion ont été évoqués pour un développement ultérieur, sans intégration à ce premier périmètre.

### Les quatre couleurs

Les noms et directions initialement retenus comme base du playtest étaient :

- **Rouge — Conquête** : attaque, pression et progression vers le Hero adverse.
- **Vert — Résilience** : défense, protection, Rempart et maintien des positions.
- **Violet — Subversion** : déplacement, repositionnement et manipulation des positions.
- **Bleu — Anticipation** : pioche, sélection de cartes, manipulation de Force et réponses.

**Réouverture du 25 octobre 2026 :** le cadre des quatre couleurs est conservé, mais leurs fonctions et ces intitulés restent des hypothèses révisables. La répartition des effets entre couleurs est différée jusqu'à l'exploration des façons de jouer, des synergies et des premiers prototypes. Ces directions ne fixent pas d'exclusivités mécaniques. Les tableaux de spécialités, de rareté d'accès à un effet, de forces et de faiblesses présentés par l'assistant restent des propositions de design. Les premières associations « Bleu–Mobilité », « Vert–Développement/Puissance » et « Violet–Ruse/Perturbation » ne sont pas les intitulés retenus pour ces quatre catalogues.

### Système de Hero et choix des couleurs

Validation explicite du créateur :

> « Je valide A : chaque Hero possède une couleur principale et peut choisir librement n'importe quelle seconde couleur différente. Développons le système. »

Le principe demandé est donc :

1. Le Hero possède une couleur principale fixe.
2. Le joueur choisit librement une seconde couleur différente.
3. Il construit son deck dans les deux catalogues de couleurs et le catalogue neutre.

Avec quatre couleurs et un Hero par couleur, cela donne trois choix de seconde couleur par Hero, soit douze configurations Hero / seconde couleur. Les affinités limitées et les synergies exclusives des options B et C n'ont pas été retenues comme système de sélection.

**Écart à traiter ultérieurement avec le ruleset :** la règle officielle **201.6.3 dit toujours que le Hero ne limite pas les cartes d'un deck** ([chapitre 201](ruleset/20-regles-completes/201-concepts.md), décision [0098](ruleset/40-decisions/0098-le-hero-ne-limite-pas-le-deck.md)). La restriction aux deux couleurs et aux neutres est un choix de conception du catalogue, pas encore une règle officielle applicable. Ce suivi ne remplace pas 201.6.3.

Les détails proposés par l'assistant — visibilité de la seconde couleur, verrouillage pendant la partie, une seule couleur par carte et absence de cartes bicolores au départ — n'ont pas reçu d'arbitrage explicite distinct et restent à formaliser.

### Hero dans le ruleset actuel

Le [chapitre 202](ruleset/20-regles-completes/202-cartes.md) impose un Hero par joueur, présent sur le plateau dès le début, hors deck, avec un nom, des PV et un texte ; il ne porte pas de Force et n'attaque pas (202.3.1 à 202.3.10).

Son texte porte un **passif**, qui est un **effet statique** (202.3.11 et 202.3.18). La décision [0208 — Le Hero n'a pas de pouvoir](ruleset/40-decisions/0208-le-hero-n-a-pas-de-pouvoir.md), intégrée à l'édition 0.42, supprime le pouvoir actif. Les exemples antérieurs de Heroes avec un pouvoir dans la conversation sont donc périmés sur ce point.

Les noms, passifs précis et valeurs des quatre nouveaux Heroes ne sont pas validés. Un passif présenté comme déclenchant une récompense après une attaque ou une destruction ne doit pas être adopté sans vérifier sa compatibilité avec 202.3.18. Le **Capitaine**, ses **15 PV** et son aura de **+1 Force aux Units alliées adjacentes** appartiennent au [deck de test existant](ruleset/70-playtest/decks-de-test.md) ; ils ne fixent pas automatiquement les caractéristiques des futurs Heroes colorés.

### Méthode de création du catalogue retenue le 25 octobre 2026

1. Définir les façons de jouer à explorer, sans attribution de couleur.
2. Construire des synergies concrètes : comment elles aident à gagner et quelles réponses elles laissent à l'adversaire.
3. Créer un petit groupe de cartes prototypes pour éprouver ces synergies, en vérifiant les textes contre le ruleset et en identifiant les arbitrages nécessaires.
4. Faire des parties pour observer les différences entre stratégies, leur intérêt, leur lisibilité et les réponses disponibles.
5. Définir les fonctions des quatre couleurs à partir des synergies prometteuses : forces, limites et intérêt des associations.
6. Compléter le catalogue, répartir les cartes et les neutres, puis concevoir les passifs des Heroes autour des identités retenues.

Les variantes sélectionnées sont une réserve d'idées : il n'est pas nécessaire de toutes les utiliser. Le cadre de quatre couleurs, le système de Hero retenu et le format de travail de 48 cartes restent consignés ; aucune nouvelle répartition ni taille de prototype n'est validée. Le ruleset officiel reste prioritaire.

### Directions de jeu demandées le 25 octobre 2026

Le créateur demande les six directions suivantes, sans attribution de couleur :

- **Agressive**.
- **Contrôle**.
- **Snowball au fil de la partie**.
- **Invocation de jetons**.
- **Pioche et défausse**.
- **Spells et Réactions**.

Ces directions constituent les intentions à explorer pour le catalogue. Elles ne fixent pas six decks distincts : leurs combinaisons, leurs effets précis, leurs faiblesses et leurs moyens d'atteindre le Hero restent à concevoir. Les fonctions des quatre couleurs restent ouvertes.

Le sens concret du snowball reste à préciser : progression de la présence sur le plateau, avantages de cartes accumulés ou autre mécanisme compatible avec les variantes retenues. Cette intention ne valide ni création d'Essence, ni bonus permanents de Force, ni nouvelle condition de victoire. Produire reste écarté et Prévenir reste mis de côté.

La direction « pioche et défausse » ne valide pas la défausse adverse ni le jeu depuis la défausse, précédemment non retenus. « Spells et Réactions » n'ajoute aucune fenêtre de réponse aux règles officielles. Les caractéristiques des jetons restent soumises au ruleset.

## 3. Verbes examinés et sélections explicites

Ordre du travail dans la conversation : Déplacer, Renforcer et Affaiblir ensemble, Détruire, Créer, Piocher, Consulter, Contrecarrer, Réveiller, Endormir, Défausser, puis Renvoyer, Permuter, Prévenir et Produire dans la conversation de continuation. Prévenir a été mis de côté provisoirement ; Produire a été écarté pour des raisons d'équilibrage.

Les intitulés ci-dessous reprennent les sélections du créateur. Ils ne valent pas création de nouveaux mots-clés officiels : ceux-ci restent les cinq du [chapitre 210](ruleset/20-regles-completes/210-mots-cles.md), Avant-poste, Arrivée, Dernier souffle, Assaut X et Rempart X.

### 1 — Déplacer

**Retenu :** chaque effet précise si la destination doit être une case libre ou non.

Première validation : « je choisis C : chaque effet précise s'il autorise le combat ou uniquement une case libre ». Le créateur précise ensuite que le ruleset fait loi, que le texte doit indiquer « si c'est sur une case libre ou non » et que l'aspect combat est déjà traité par le ruleset.

Les dix règles parallèles DEP-01 à DEP-10 proposées par l'assistant ont été retirées après cette correction. Elles ne sont pas des décisions du catalogue. Les cibles, portées, directions et exemples de cartes de déplacement restent à écrire précisément. Références : [205 — Actions](ruleset/20-regles-completes/205-actions.md), [206 — Combat](ruleset/20-regles-completes/206-combat.md), [207 — Effets](ruleset/20-regles-completes/207-effets.md) et [208 — Pile et priorité](ruleset/20-regles-completes/208-pile-et-priorite.md). Ne pas étendre automatiquement une règle d'action normale à tout effet de déplacement.

### 2 et 3 — Renforcer et Affaiblir

**Expérimentations explicitement retenues ensemble :**

- Modifications temporaires de Force.
- Bonus et malus continus selon le positionnement.
- Modifications déclenchées par un événement.

Le créateur précise : « Ces propositions restent subordonnées au ruleset officiel. »

Les renforcements persistants avec suivi individuel n'ont pas été sélectionnés. Cela ne retire pas du ruleset les effets à durée « tant que la pièce est en jeu ».

Repères officiels : modificateurs additionnés et auras, 206.5 ; effets statiques et durées, 207.2 et 207.4. Une Force négative est ramenée à 0 et **une pièce à Force 0 reste en jeu** (209.1.2 et 209.1.3), sans destruction automatique. Les durées non statiques prévues par 207.4.2 sont « jusqu'à la fin du tour » et « tant que la pièce est en jeu » : l'exemple conversationnel « jusqu'à la fin du combat » n'est pas validé par cette sélection.

### 4 — Détruire

**Expérimentations explicitement retenues :**

- Destruction directe conditionnelle.
- Sacrifice volontaire.
- Effets déclenchés par une destruction.
- Synergies entre destruction et positionnement.

Repères officiels : Détruire dans le glossaire, destination d'une pièce détruite et cas des jetons (206.3.2, 206.3.2a, 202.4.3 et 202.4.4), Dernier souffle (210.3.2). La sélection du « sacrifice volontaire » ne fixe ni un nouveau mot-clé ni une procédure de coût. La question **Q-097** sur les effets de Force ou de destruction visant le Hero reste ouverte.

### 5 — Créer

**Variantes explicitement retenues :**

- Création simple.
- Création conditionnelle.
- Création déclenchée par une destruction.
- Création de Buildings.
- Création par sacrifice.

Repères officiels : un jeton est une Unit ou un Building, avec une Force donnée par l'effet ; sa création vient d'un Spell ou d'un effet déclenché et cible une case libre (202.4.6 à 202.4.12c). Un jeton ne porte initialement ni effet ni mot-clé (202.4.5 et 202.4.13) ; les exceptions pour des apports ultérieurs sont déjà définies. Une Unit jeton arrive endormie (205.5.4a). Les sélections ne fixent pas encore le nombre, la Force, les cases autorisées ou le coût des créations.

### 6 — Piocher

**Variantes explicitement retenues :**

- Pioche directe.
- Pioche conditionnelle.
- Pioche déclenchée.
- Pioche avec contrepartie.
- Pioche territoriale.

Repères officiels : définition Piocher du glossaire, limite de main et cartes qui n'y entrent pas (201.3.4 à 201.3.6), fatigue (209.5). Le rythme de base est désormais **1 carte au début de son tour**, valeur PROVISOIRE de 204.3.6 dans l'édition 0.43. La notion de « territoriale » reste à traduire par une condition de cases explicite.

### 7 — Consulter

**Variantes explicitement retenues :**

- Consultation simple.
- Consultation avec réorganisation.
- Consultation avec sélection.
- Consultation avec filtrage.
- Consultation conditionnelle.

Les choix ne fixent pas le nombre de cartes consultées, leur ordre, la destination des cartes non gardées ni les informations révélées à l'adversaire. Références à respecter : information du deck et de la main (201.4.1 et 201.4.2), interdiction de cibler les cartes de main, deck ou défausse (207.5.13). Consulter ou choisir une carte n'autorise pas implicitement à la cibler au sens des règles.

### 8 — Contrecarrer

**Variantes explicitement retenues :**

- Contrecarrage simple.
- Contrecarrage conditionnel.
- Contrecarrage avec contrepartie.
- Contrecarrage récompensé.
- Effets déclenchés par un contrecarrage.

Repères officiels : Contrecarrer vise seulement un **Spell sur la pile** ; ni déploiement, ni action normale, ni effet déclenché (207.6.2 et 207.6.3). Le Spell contrecarré n'a pas lieu, sa carte va à la défausse et son coût reste dépensé (207.6.4 à 207.6.6). Une entrée ne se cible pas elle-même (207.5.16).

Le contrecarrage avec alternative de paiement proposée à l'adversaire n'a pas été sélectionné. Les seuils de coût évoqués comme exemples de conditions ne sont pas chiffrés définitivement.

### 9 — Réveiller

**Variantes explicitement retenues :**

- Réveil simple.
- Réveil conditionnel.
- Réveil déclenché.
- Réveil avec contrepartie.

Le réveil territorial et le réveil différé n'ont pas été sélectionnés. Références : définition Réveiller du glossaire, réveil des Units et du Hero au début du tour (204.3.10 et 204.3.11), sommeil et réveil (205.5). Le texte d'une carte doit distinguer un changement d'état d'un effet qui ne ferait rien sur une pièce déjà éveillée.

### 10 — Endormir

**Variantes explicitement retenues :**

- Endormissement simple.
- Endormissement conditionnel.
- Endormissement avec contrepartie.
- Auto-endormissement.

L'endormissement déclenché et l'endormissement territorial n'ont pas été sélectionnés, malgré leur présence dans les propositions de l'assistant.

Repères officiels : Units et Heroes sont endormis ou éveillés ; une pièce endormie ne peut pas faire d'action normale et reste endormie jusqu'à son prochain réveil (205.5.1 à 205.5.5). Un **Building n'est ni endormi ni éveillé** (205.5.6). La sélection ne crée pas un état Étourdi et n'annule pas automatiquement une annonce déjà faite.

### 11 — Défausser

**Variantes explicitement retenues :**

- Défausse simple.
- Défausse avec contrepartie.
- Défausse avec renouvellement.
- Effets déclenchés par une défausse.
- Défausse conditionnelle.

La défausse adverse n'a pas été sélectionnée. La défausse aléatoire et le jeu de cartes depuis la défausse n'ont pas été validés.

Le sens de travail proposé est le passage de cartes de la main à la défausse, distinct de Détruire et d'un envoi depuis le deck. Les modalités de choix, le joueur qui choisit, les conditions et l'ordre « piocher puis défausser » ou inverse restent à spécifier carte par carte. La règle 207.5.13 interdit de cibler une carte de la main ; un effet qui atteint un joueur le fait en ciblant son Hero (207.5.12).

### 12 — Renvoyer

**Variantes explicitement retenues dans la conversation de continuation :**

- Renvoi simple.
- Renvoi conditionnel.
- Renvoi déclenché.
- Renvoi avec contrepartie.
- Renvoi territorial.

Le créateur rappelle : **« Le ruleset officiel reste prioritaire. »**

Sens de travail proposé : retirer une carte du plateau pour la remettre dans la main de son propriétaire. Le **renvoi à l'Arrivée** n'a pas été sélectionné à ce stade ; cela ne constitue pas un rejet définitif.

La sélection porte sur les familles de variantes. Les cibles alliées ou ennemies, la restriction aux Units non jetons, les seuils de Force, les rangées, les déclencheurs, les limitations par tour et les contreparties précises restent à définir. Les exemples « Gardien du refuge » et « Retrait stratégique », leurs valeurs et la répartition entre couleurs ne sont pas validés.

La relecture du ruleset fournit déjà les repères suivants, sans qu'il soit nécessaire de créer des règles parallèles :

- **Gear** : quand une Unit quitte le plateau, son Gear va à la défausse de son joueur (202.2.13) ; les effets du Gear s'arrêtent (207.2.9b et 207.4.8).
- **Jeton** : il cesse d'exister en quittant le plateau et ne va dans aucune zone hors plateau (202.4.3 et 202.4.4).
- **Arrivée** : l'effet se déclenche à chaque entrée sur le plateau, quel qu'en soit le moyen (210.3.1 et 210.3.1a). Une éventuelle mention « une fois par tour » conserve son décompte si la carte change de zone et revient dans ce même tour (207.3.10 et 207.3.10a).
- **Dernier souffle** : son événement est la destruction (210.3.2) ; un simple départ du plateau ne doit pas être assimilé à une destruction.
- **Effets de Force** : un effet à durée « tant que la pièce est en jeu » cesse pour la pièce qui quitte le plateau (207.4.7a), comme un effet statique porté par une pièce qui quitte le plateau (207.2.4). Ne pas généraliser cela à toutes les durées ou à tous les futurs textes.
- **Action ou combat en attente** : la pile et les fenêtres de réponse restent régies par 208 ; une action normale ou son combat en attente n'a pas lieu si l'Unit a quitté le plateau à sa résolution (205.4.3 et 205.6.10). Aucune nouvelle fenêtre de réponse n'est créée ici.
- **Main pleine** : la règle générale laisse une carte qui ne peut entrer en main dans sa zone d'origine (201.3.5 et 201.3.6). L'exception qui envoie à la défausse vise précisément les retours des déploiements et du Gear cités par 201.3.6a. Elle ne doit pas être étendue implicitement à un futur effet de renvoi depuis le plateau. Le texte concret devra être vérifié contre ces règles avant validation.

Restent à décider : les cibles autorisées, les conditions de position, les contreparties, les formulations exactes et les éventuels cas que les règles actuelles ne couvrent pas.

### 13 — Permuter

**Variantes retenues par accord du créateur avec la recommandation des cinq premières :**

- Permutation simple.
- Permutation conditionnelle.
- Permutation déclenchée.
- Permutation avec contrepartie.
- Permutation territoriale.

Principe de travail proposé : échanger les positions de deux Units alliées sur le plateau. La **permutation alliée–ennemie** reste en attente d'une expérimentation distincte ; elle n'est pas retenue à ce stade, sans rejet définitif.

Le ruleset officiel reste prioritaire. La sélection ne valide pas les exemples de cartes, les conditions précises de Force ou d'état, les déclencheurs, les contreparties, les rangées ou colonnes autorisées, ni les limitations par tour. Une contrepartie ne devient pas automatiquement un coût d'annonce.

Repères : aucune case ne contient plus d'une pièce (Invariant 201.0.1), aucune carte ne change de joueur (201.5.3), et les cibles relèvent de 207.5. La procédure exacte d'une permutation, notamment lorsqu'une cible devient invalide, reste à formaliser avant une carte jouable ; aucun comportement nouveau n'est acté implicitement par ce suivi.

### 14 — Prévenir : mis de côté pour le moment

**Décision du créateur : ne pas utiliser ce verbe pour le moment. Aucune variante retenue.**

Les six pistes présentées — prévention simple, conditionnelle, déclenchée, avec contrepartie, territoriale et par substitution — ne sont pas intégrées au périmètre actuel du catalogue. Elles sont conservées ici uniquement comme trace de la discussion, et non comme variantes à développer.

Ce report est provisoire, sans rejet définitif. Il ne modifie pas le ruleset et n'introduit aucun mécanisme de prévention.

### 15 — Produire : écarté du catalogue

**Décision du créateur : pas de création d'Essence par effet de carte, jugée trop forte pour le jeu. Aucune variante retenue.**

Les cinq pistes proposées — production simple, conditionnelle, déclenchée, avec contrepartie et territoriale — sont écartées du catalogue. La recommandation de les explorer avec des gains modestes n'est pas retenue.

Cette décision concerne les effets de cartes envisagés dans cette discussion. Le fonctionnement officiel de la production d'Essence par les Sources reste inchangé (chapitre 203). Ce suivi n'ajoute ni règle officielle ni mécanisme économique de remplacement.

## 4. Propositions en attente

Le renvoi à l'Arrivée reste non sélectionné. La permutation alliée–ennemie reste en attente ; les cinq autres variantes de Permuter sont retenues en section 3.

### Bilan de la liste initiale des verbes

Les quinze verbes de la liste initiale ont été examinés. Treize ont des orientations ou variantes retenues ; Prévenir est mis de côté pour le moment et Produire est écarté. La sélection des variantes ne finalise pas les textes de cartes ni les arbitrages de règles encore nécessaires.

Repousser, Attirer, Replier et Téléporter ont aussi été évoqués comme pistes autour du déplacement. Leurs noms ne constituent pas une liste supplémentaire de verbes validés. Les priorités 1, 2 et 3 assignées par l'assistant à la liste initiale restent des recommandations.

### Premières expériences proposées par l'assistant — historique

Les six premières propositions étaient : percée offensive, occupation large, formation resserrée, désorganisation, pertes rentabilisées et préparation d'un tour décisif. Elles n'ont pas été validées comme liste. Le créateur a formulé ses propres six directions, consignées en section 2, qui guident désormais l'exploration. Certains éléments de ces propositions peuvent servir d'exemples ultérieurs, sans acquérir de statut validé.

### Conception des directions retenues — en attente

Restent à choisir pour chaque direction : la manière de progresser vers la victoire, les synergies de cartes, les réponses laissées à l'adversaire, les faiblesses et les interactions avec les autres directions. L'étude ci-dessous propose notamment un snowball de formation et une alternative territoriale ; leur choix et leurs textes restent à valider.

### Étude des mécanismes — recommandations de l'assistant du 25 octobre 2026

**Statut : pistes recommandées, suivies d'un accord pour poursuivre la conception (« Très bien continuons »). Les textes et valeurs restent à examiner.** Étude fondée sur le ruleset 0.44, notamment les chapitres 202, 205, 206, 207, 208 et 210. Aucun test de partie n'a été réalisé pour ces propositions ; leur intérêt et leur équilibre restent des hypothèses.

Le créateur demande : « Je te laisse examiner les mécanismes fun qui pourrait intégrer le jeu ». Cette délégation autorise l'examen et les recommandations, pas la transformation des exemples en règles ou cartes approuvées.

Le critère de sélection est un choix tactique visible : choisir un moment, une case, une pièce à exposer ou une carte à conserver. Chaque mécanisme doit permettre une progression vers le Hero adverse et laisser un moyen concret de perturber sa mise en place. Les noms ci-dessous sont des intitulés de travail, pas de nouveaux mots-clés.

**M1 — Percée et second effort (agressif, Spells).** Une Unit profite d'Assaut ou d'un renforcement temporaire pour gagner un combat ; un Spell de réveil joué ensuite lui permet de reprendre une action normale si celle-ci est légale. L'intérêt vient du choix entre poursuivre, se repositionner ou conserver ses cartes. L'adversaire peut répondre à l'attaque ou au Spell dans les fenêtres officielles. Le réveil n'annule pas une annonce passée et le déplacement après combat suit 206.3, y compris le cas de l'égalité. Premier prototype recommandé : un seul effet de réveil ponctuel, sans déclenchement qui renouvelle automatiquement ce réveil. À mesurer : attaques successives de la même Unit et possibilités de réponse avant les pertes de PV décisives.

**M2 — Contrôle du passage (contrôle, Réactions).** Combiner affaiblissement temporaire, endormissement préventif et renvoi conditionnel pour préparer des échanges favorables et ouvrir une colonne. Le joueur doit conserver des Units capables de profiter de l'ouverture. L'endormissement empêche une future action normale, mais ne suffit pas à annuler une attaque déjà annoncée (205.4.7 et 205.5). Contrecarrer reste limité aux Spells (207.6). Premier prototype recommandé : réponses ciblées et conditions lisibles, sans renouvellement automatique d'un verrou. À mesurer : actions utiles encore disponibles pour l'adversaire et capacité du contrôle à terminer une partie.

**M3 — Formation qui se développe (snowball, jetons).** Une pièce de soutien accorde une aura locale aux Units alliées adjacentes ; chaque nouveau compagnon bien placé augmente la valeur totale de la formation. Le snowball vient des pièces conservées et de leur coopération, sans accumulation individuelle permanente de Force. Le joueur choisit entre rester groupé et avancer. L'adversaire peut déplacer ou renvoyer les bénéficiaires, isoler ou éliminer le soutien. Les auras se calculent avant l'entrée de l'attaquant sur la case du défenseur et suivent 206.5 ; les effets déjà déclenchés ne sont pas annulés par la disparition de leur source (207.3.3). Premier prototype recommandé : un soutien et quelques Units simples. À mesurer : facilité à reconstituer la formation et possibilité réelle de la démanteler. C'est l'option principale recommandée pour le snowball.

**M4 — Jetons à plusieurs usages (jetons, agressif, snowball).** Un Spell crée un jeton Unit simple sur une case libre précisément autorisée ; une autre carte de soutien peut ensuite le renforcer. Le choix est d'occuper une case, préparer une attaque ou accepter un échange. Les jetons arrivent endormis, ne portent initialement ni effet ni mot-clé et ne gagnent ces propriétés que par une source ultérieure autorisée (202.4, 205.5.4a). Les cases possibles doivent être limitées par le texte de prototype : la règle générale de création sur une case libre ne justifie pas une portée illimitée pour toutes les cartes. Variante secondaire à examiner : une carte non jeton récompense une destruction alliée par un renforcement temporaire, avec une limite par tour. Cela ne signifie pas défausser un jeton ni lui donner un Dernier souffle lors de sa création. À mesurer : occupation du plateau, cases bloquées et valeur des soutiens.

**M5 — Main renouvelée, défausse utile (pioche-défausse, agressif, Spells).** Un Spell fait piocher puis défausser ; une pièce distincte peut donner un avantage ponctuel après une défausse réellement effectuée, par exemple un renforcement jusqu'à la fin du tour. Le joueur améliore sa main et choisit ce qu'il abandonne pour préparer son attaque. Le moteur reste exposé aux interventions adverses ; aucun jeu depuis la défausse ni défausse adverse n'est introduit. Le traitement de la main pleine doit suivre 201.3 : ne pas promettre une pioche quand elle est impossible, et ne pas assimiler filtrage et gain net de cartes. Premier prototype recommandé : une seule récompense par tour pour chaque source, sans pioche déclenchée qui alimente sa propre chaîne. À mesurer : décisions réelles de défausse et écart entre qualité de main et avantage net.

**M6 — Spells qui soutiennent le plateau (Spells, Réactions, agressif ou contrôle).** Une Unit porte, une fois par tour, un effet déclenché par l'annonce d'un Spell de son joueur : renforcer temporairement une Unit alliée ciblée. Cela donne aux sorts une utilité liée au plateau et encourage le choix du moment où les jouer. Le déclencheur porte explicitement sur l'annonce : il existe même si le Spell est ensuite contrecarré ; la disparition de la source n'annule pas un effet déjà déclenché. Un déclencheur fondé sur la résolution serait une autre version, qui attendrait la fin de la résolution complète de la pile. Le choix entre ces versions n'est pas validé. Premier prototype recommandé : la version à l'annonce, une récompense modeste, pas de pioche ou de réveil en chaîne. À mesurer : intérêt des sorts en dehors du déclencheur, fréquence des Réactions et longueur des séquences.

**Alternative de snowball à tester ensuite — avantage territorial.** Une pièce fournit une petite récompense récurrente seulement si son joueur maintient une présence dans une zone explicitement définie, par exemple le centre. L'événement et le moment de vérification de la condition restent à écrire. Cette piste peut relier contrôle, jetons et pioche, mais risque de récompenser trop fortement le joueur déjà devant. Préférer une seule récompense par tour et une condition contestable ; ne pas cumuler d'emblée création de jeton et pioche sur le même moteur. Un déclencheur de début ou de fin de tour est sans réponse selon 208.7.15–16 : l'adversaire doit pouvoir intervenir auparavant.

**Limites communes.** Une mention « une fois par tour » est suivie par carte, sur chaque tour de joueur, et ne se réinitialise pas par un renvoi suivi d'un redéploiement (207.3.5–10a). Plusieurs exemplaires peuvent néanmoins multiplier les récompenses : vérifier leur cumul au prototype. Le Hero ne porte qu'un passif statique ; les moteurs déclenchés proposés appartiennent à des cartes du deck, pas à un nouveau pouvoir de Hero. Les effets à durée utilisent les durées officielles ; aucune durée « jusqu'à la fin du combat » n'est introduite. Aucune production d'Essence, prévention, résurrection, nouvelle fenêtre de réponse ou condition de victoire n'est proposée.

**Ordre conseillé des essais.** Commencer par formation et jetons pour établir la valeur des cases et la fragilité des soutiens ; éprouver ensuite percée et contrôle face à ce plateau ; ajouter enfin pioche-défausse et synergies de Spells. La recommandation couvre les six directions sans en faire six couleurs. Les coûts, Forces, quantités, textes définitifs, attribution aux couleurs et modalités exactes de test restent à décider. Le catalogue et le moteur du jeu ne sont pas modifiés par cette étude.

### Premier groupe de prototypes — formation et jetons, version 0.1

**Statut : base de prototype acceptée pour un premier essai après le « Go » du créateur le 25 octobre 2026 ; valeurs ajustables, cartes non implémentées et non testées en partie.** Le précédent « Très bien continuons » autorisait leur conception ; le « Go » suivant leur présentation permet de préparer l'essai de FJ-01 à FJ-04. Il ne constitue ni une validation définitive de l'équilibrage ni une modification du ruleset.

Objectif : vérifier qu'une formation devient intéressante en se développant, reste capable d'avancer et laisse à l'adversaire des moyens de la défaire. Quatre nouvelles références suffisent à explorer soutien, occupation, remplacement d'une perte et repositionnement. Les cartes n'ont pas encore de couleur attribuée ; cela ne signifie pas qu'elles sont neutres dans le futur catalogue.

**Repères de valeurs.** Dans le deck de test existant, Recrue coûte 1 pour Force 2, Soldat 2 pour Force 3, Vétéran 3 pour Force 4 ; Levée coûte 2 et crée un jeton Unit de Force 2 sur la première rangée ; Martyr coûte 3 pour Force 3 avec Dernier souffle ; Renfort coûte 1 et donne +2 Force jusqu'à la fin du tour. Ces repères figurent dans [les decks de test](ruleset/70-playtest/decks-de-test.md) et ont été recoupés avec `data/cards/test_deck.json` sur main. Ils ne prouvent pas l'équilibre des propositions.

#### FJ-01 — Porte-enseigne

- Type : Unit.
- Coût proposé : **3 Essence**.
- Force proposée : **2**.
- Texte proposé : **« Les autres Units alliées adjacentes au Porte-enseigne ont +1 Force. »**

Rôle : soutien mobile d'une formation ; il renforce aussi bien des Units issues de cartes que des jetons. Il est moins fort seul qu'un Vétéran du même coût. L'adjacence est orthogonale, jamais diagonale. Le bonus est une aura, sans accumulation permanente ni activation, appliquée selon 206.5 et 207.2. Il ne se donne pas lui-même de bonus.

Risque à tester : plusieurs Porte-enseignes peuvent se renforcer entre eux et leurs auras s'additionnent ; le passif du Capitaine peut également s'ajouter. Ne pas introduire implicitement une règle de non-cumul. Frappe, les combats et les déplacements adverses sont des réponses à étudier selon la Force et la position réelles du soutien.

#### FJ-02 — Rassemblement

- Type : Spell, vitesse **Action**.
- Coût proposé : **3 Essence**.
- Texte proposé : **« Choisissez deux cases libres ciblées distinctes parmi les deux rangées les plus proches de vous. Créez un jeton Unit de Force 1 sur chacune de ces cases. »**

Rôle : deux corps faibles pour préparer une formation, occuper deux voies ou accepter un échange. La seconde rangée donne une souplesse de placement supérieure à Levée, mais chaque jeton est plus faible et le coût total est plus élevé. Cette portée est une proposition de texte de création, pas une nouvelle règle de déploiement.

Les jetons arrivent endormis, sans effet ni mot-clé provenant de leur création. Le Porte-enseigne peut ensuite les affecter par son aura, conformément à 202.4.5a. Les deux cibles sont explicitement distinctes pour ce texte, sans arbitrer le cas général Q-098. Deux cases légales sont nécessaires à l'annonce (207.5.10) ; à la résolution, seul le jeton dont la case est restée valide est créé si l'autre cible est devenue invalide (202.4.12b–c et 207.5.3–4).

Risque à tester : nombre de pièces obtenu pour une seule carte, cumul des auras et encombrement du plateau. Ne pas augmenter simultanément Force, portée et nombre de jetons pendant un ajustement.

#### FJ-03 — Compagnon tenace

- Type : Unit.
- Coût proposé : **3 Essence**.
- Force proposée : **3**.
- Texte proposé : **« Dernier souffle : créez un jeton Unit de Force 1 sur une case libre ciblée de votre première rangée. »**

Rôle : accepter un échange tout en préparant un remplacement en retrait. Le jeton n'apparaît pas automatiquement sur la case du Compagnon ; la première rangée constitue une limite explicite et permet d'éviter une mémoire de l'ancienne position.

Le choix de case se fait à l'ajout du déclencheur à la pile ; l'effet peut ne pas s'ajouter s'il n'existe aucune cible légale, et la création peut échouer si la case n'est plus libre à la résolution. Un effet déclenché pendant une résolution attend sa fin (208.4). Le jeton est endormi et n'hérite ni du nom, ni du texte, ni du Dernier souffle du Compagnon. Il n'existe donc pas de chaîne de remplacements portée par ce seul texte.

Risque à tester : avantage matériel face à Martyr ou Vétéran et temps nécessaire pour ramener le jeton vers la formation. Il ne s'agit ni de prévention ni de résurrection.

#### FJ-04 — Pas de côté

- Type : Spell, vitesse **Action**.
- Coût proposé : **1 Essence**.
- Texte proposé : **« Déplacez une Unit alliée ciblée sur une case libre ciblée adjacente à cette Unit. »**

Rôle : déplacer un soutien ou un bénéficiaire pour former une nouvelle adjacence, libérer un passage ou quitter une zone dangereuse. Le texte est limité aux Units et aux cases libres ; il n'autorise pas de combat sur une case occupée.

La pièce et la case sont choisies à l'annonce ; liberté et adjacence font partie des conditions à vérifier à la résolution (207.5). Ce Spell ne contient aucun effet Réveiller ou Endormir ; une Unit endormie n'est pas exclue de ses cibles par le texte. Ce déplacement par effet ne reçoit pas implicitement les coûts ou les changements d'état d'une action normale. La version initiale est Action ; passer à Réaction changerait fortement les possibilités d'intervention pendant un combat et doit constituer un essai distinct.

Risque à tester : intérêt réel d'une carte et d'une Essence pour ce repositionnement, possibilité de déplacer une Unit déjà endormie et de conserver l'action normale d'une Unit éveillée.

#### Lecture tactique et vérification sur papier

Exemple sans Hero adjacent ni autre modificateur : Porte-enseigne en C3, jetons de Force imprimée 1 en B3 et D3. Chaque jeton a Force 2 grâce à l'aura. Ces pièces sont supposées déjà installées ; Rassemblement ne les crée pas directement sur la rangée centrale.

- Face à un défenseur de Force 2, un jeton sans soutien perd ; avec le soutien, il atteint l'égalité et les deux pièces sont détruites selon la règle provisoire 206.3.6.
- Renfort fait passer ce jeton soutenu à Force 4 jusqu'à la fin du tour. Si les conditions restent identiques et sans réponse adverse, il bat un défenseur de Force 2.
- La comparaison et les auras suivent 206.5.2–3 avant l'entrée de l'attaquant sur la case du défenseur ; on ne retire pas rétroactivement le bonus parce qu'il avance après le combat.
- Si le soutien a quitté le plateau avant ce combat et qu'aucun autre modificateur n'intervient, le jeton revient à Force 1. Les auras additionnelles changent naturellement ces chiffres.

Cette vérification illustre les seuils de Force ; elle n'est pas un résultat de simulation ou de playtest.

#### Essais proposés et points de décision

1. Isoler d'abord Porte-enseigne avec des Units simples et Levée, déjà disponibles dans le deck de référence, pour voir si les déplacements de formation ont un intérêt.
2. Comparer ensuite Rassemblement à Levée, sans changer les autres variables : deux corps faibles et une portée plus large compensent-ils le coût supplémentaire ?
3. Ajouter Compagnon tenace puis Pas de côté séparément pour observer leurs effets sur les pertes, le rythme et les ouvertures.
4. Examiner le cumul de deux puis trois Porte-enseignes, notamment avec l'aura du Capitaine ; les limites du nombre d'exemplaires restent celles du ruleset.

À relever : positions et déplacements réellement choisis, combats dont l'issue change grâce au soutien, tours passés à camper près du Hero, cases bloquées par ses propres jetons, durée de survie du soutien et possibilité de revenir après sa perte. La formation doit être utile à l'offensive ; un simple renforcement du campement défensif ne suffirait pas à valider l'objectif.

Les quatre cartes ne forment pas à elles seules un deck complet ; la composition expérimentale et le protocole proposés ci-dessous les intègrent à une base de comparaison. Le premier playtest officiel reste inchangé. Aucun coût, texte ou résultat n'est présenté comme équilibré ou définitivement adopté.

### Premier essai formation et jetons — listes et protocole proposés

**État : préparation documentaire terminée ; aucune partie jouée, aucun résultat d'équilibrage.** Les prototypes ne sont pas intégrés au logiciel. Les listes ci-dessous sont utilisables pour un essai manuel avec représentations provisoires des nouvelles cartes ; elles ne sont pas des fichiers de deck importables dans le moteur actuel. Le protocole et les compositions sont proposés après l'accord pour continuer.

#### Deck de référence — 30 cartes

Reprise de `data/decks/deck_de_test.json` sur main, édition 0.44. Hero hors deck : **Capitaine**, 15 PV, passif « Les Units alliées adjacentes au Hero ont +1 Force. »

- 2 × **Recrue**.
- 3 × **Soldat**.
- 3 × **Vétéran**.
- 2 × **Champion**.
- 2 × **Colosse**.
- 2 × **Pillard**.
- 2 × **Gardien**.
- 1 × **Héraut**.
- 1 × **Martyr**.
- 1 × **Palissade**.
- 1 × **Bastion**.
- 2 × **Campement**.
- 2 × **Renfort**.
- 2 × **Frappe**.
- 1 × **Contre**.
- 1 × **Levée**.
- 2 × **Lame**.

#### Deck formation et jetons — 30 cartes

Même Hero et mêmes règles. Les couleurs restent non attribuées pour cette expérience ; aucune règle de construction bicolore supplémentaire n'est appliquée.

- 2 × **Recrue**.
- 3 × **Soldat**.
- 1 × **Vétéran**.
- 2 × **Champion**.
- 2 × **Colosse**.
- 2 × **Pillard**.
- 2 × **Gardien**.
- 1 × **Palissade**.
- 1 × **Bastion**.
- 2 × **Renfort**.
- 2 × **Frappe**.
- 1 × **Contre**.
- 1 × **Levée**.
- 2 × **Porte-enseigne**.
- 2 × **Rassemblement**.
- 2 × **Compagnon tenace**.
- 2 × **Pas de côté**.

Les huit substitutions sont : 2 Vétérans deviennent 2 Porte-enseignes ; 2 Campements deviennent 2 Rassemblements ; Héraut et Martyr deviennent les 2 Compagnons tenaces ; 2 Lames deviennent 2 Pas de côté. Recrue, Soldat, les grosses Units, Pillard, Gardien, Renfort, Frappe, Contre et Levée sont conservés dans leurs quantités initiales.

**Contrôles de liste effectués.** Chaque deck contient 30 cartes et au plus 3 exemplaires d'une même référence. Les deux courbes sont identiques : 6 cartes à coût 1, 10 à coût 2, 10 à coût 3, 2 à coût 4 et 2 à coût 5. Le deck expérimental a 18 Units, 2 Buildings et 10 Spells ; la référence a 18 Units, 4 Buildings, 6 Spells et 2 Gear. La comparaison examine donc un ensemble de huit substitutions, pas l'effet causal isolé d'une seule carte. Les contrôles de nombre, exemplaires, références et coûts ont été calculés à partir des données du dépôt et des quatre propositions ; ils ne sont pas des tests du moteur.

#### Vérifications manuelles avant les parties

- **Aura et échange.** Sans autre modificateur, Porte-enseigne en C3, jeton Unit de Force imprimée 1 en B3, Recrue ennemie de Force 2 en B4. Les Heroes restent éloignés. Le jeton soutenu atteint 2 ; s'il attaque et qu'aucune Réaction ne change l'état, l'égalité détruit les deux pièces. Sans le soutien au moment de la comparaison, le jeton de Force 1 perd seul. Vérifier l'aura avant l'entrée sur la case du défenseur, selon 206.5.
- **Cumul avec le Hero.** Capitaine allié en C1, Porte-enseignes alliés en C2 et D2, sans autre modificateur : celui de C2 atteint Force 4 (base 2, +1 du Hero, +1 de l'autre soutien), celui de D2 atteint Force 3. Frappe, qui exige Force 3 ou moins, ne peut initialement viser que celui de D2. Les auras se recalculent si la formation change. Cette situation explore le cumul réellement permis, sans règle de non-cumul ajoutée.
- **Création et place disponible.** Rassemblement exige deux cases libres légales distinctes lors de son annonce. Avec une seule case libre parmi les deux premières rangées, il ne peut pas être annoncé. Les jetons créés sont endormis. Avec Compagnon tenace, une première rangée encore pleine au moment d'ajouter Dernier souffle ne fournit aucune cible légale : aucun jeton n'est créé.
- **Repositionnement.** Pendant sa phase principale, pile vide, Pas de côté peut viser une Unit alliée endormie et une case libre adjacente. Si les cibles restent valides, elle change de case et reste endormie. Une case occupée ou non adjacente n'est pas une destination légale. Le Spell reste de vitesse Action.

Ces positions sont des exercices de compréhension préparés, pas des situations observées ni des parties depuis la préparation normale. Toute ambiguïté réelle constatée doit être relevée pour le ruleset, sans arbitrage implicite.

#### Quatre parties exploratoires

Utiliser deux joueurs A et B, avec les decks et valeurs de cette version inchangés pendant la série. Pour maîtriser l'ordre de départ, l'essai propose une alternance de premier joueur comme le protocole de test existant (décision 0158) ; cette modalité expérimentale ne remplace pas la règle générale de désignation du premier joueur.

1. A joue formation/jetons et commence ; B joue référence.
2. A joue formation/jetons ; B joue référence et commence.
3. A joue référence et commence ; B joue formation/jetons.
4. A joue référence ; B joue formation/jetons et commence.

Chaque joueur utilise ainsi chaque deck une fois en commençant et une fois en second. Préparation, mélange, mulligan, pioche et autres règles sont conservés ; pas de main arrangée pendant ces parties. Quatre parties servent à détecter des problèmes et des choix intéressants, sans établir un taux de victoire fiable.

#### Relevé de chaque partie

Noter : numéro de partie, joueurs et decks, premier joueur, vainqueur, tour de fin et cause de fin. Pour chaque prototype, relever les exemplaires vus et joués, puis un fait concret :

- **Porte-enseigne** : un combat dont il a changé l'issue ; une décision d'avancer ou de rester près du Hero ; la réponse adverse à la formation.
- **Rassemblement** : jetons effectivement créés ; jetons devenus utiles ; blocages dus aux cases ou impossibilité de jouer la carte.
- **Compagnon tenace** : destruction et création effective ; utilité ultérieure du jeton ou absence de case disponible.
- **Pas de côté** : déplacement qui change une possibilité d'attaque, de soutien ou de défense ; carte conservée faute d'usage utile.

À la fin, chaque joueur donne un moment où il a eu un choix intéressant, un moment où il s'est senti bloqué, et la carte qu'il changerait en premier avec la raison. Noter également si l'adversaire disposait d'une réponse au soutien et s'il a pu l'utiliser. Ne pas interpréter l'absence d'une carte dans les mains comme la preuve de sa faiblesse.

#### Décider de l'itération suivante

- Si la formation crée des choix d'avancée et reste perturbable, poursuivre les tests sans modifier immédiatement les chiffres.
- Si elle reste systématiquement près du Hero, examiner d'abord les positions et l'aura du Capitaine dans les relevés. Ne pas augmenter automatiquement les bonus.
- Si Rassemblement est trop fort ou trop faible, modifier un seul paramètre à la fois : coût, Force, nombre ou portée, puis refaire une comparaison.
- Si le résultat reste difficile à expliquer, reprendre les variantes isolées décrites précédemment : soutien seul, puis ajout d'une seule famille de cartes. Le deck complet ne permet pas d'imputer un problème à une carte sans examen.
- Les changements de texte, de coût et de Force restent à décider à partir des observations. Aucun résultat fictif n'est rempli.


### Autres propositions non finalisées

- **Répartition par type** : 4 Units, 3 Spells, 1 Building et 1 Gear par couleur ; pour les neutres, 7 Units, 2 Spells, 2 Buildings et 1 Gear. Proposition de structure, sans validation explicite distincte.
- **Moteurs de synergie** : attaques / destructions pour le Rouge ; formations / survie pour le Vert ; déplacements / changements de position pour le Violet ; préparation de main / Spells et réactions pour le Bleu. Pistes de travail, sans répartition définitive des effets entre couleurs.
- **Prototype intermédiaire de 16 cartes** : quatre par couleur avant l'extension à 48 ; méthode suggérée, pas un remplacement du format retenu.
- **Déclencheurs et conditions** : familles, événements exacts, limitations et interactions à définir après les verbes. Les études de Riftbound servent d'inspiration, sans importer ses règles, mots-clés ou chiffres.
- **Cartes et Heroes nommés dans les exemples** : les exemples antérieurs restent non validés. FJ-01 à FJ-04 font exception comme base acceptée pour un premier essai, avec valeurs ajustables ; les listes proposées ci-dessus et les caractéristiques finales ne sont pas approuvées par anticipation.
- **Contreparties** : distinguer une instruction résolue d'un coût supplémentaire. L'Essence reste la seule ressource qui paie un coût (Invariant 203.0.1) et les coûts d'annonce se paient à l'annonce (203.3.2). Les variantes « avec contrepartie » ne valident pas implicitement un nouveau système de coûts de sacrifice, de défausse ou d'endormissement.
- **Mots-clés supplémentaires, marqueurs et effets persistants complexes** : aucune liste nouvelle n'est validée par les sélections de verbes.

## 5. Traçabilité et poursuite

### Preuves de sélection dans le fil

Les validations des variantes sont les messages du créateur commençant par :

- « Pour les verbes Renforcer et Affaiblir de mon TCG, je retiens les expérimentations suivantes… »
- « Pour le verbe Détruire, je retiens ces expérimentations… »
- « Pour le verbe Créer de mon TCG, je retiens… »
- « Pour le verbe Piocher, je retiens… »
- « Pour le verbe Consulter, je retiens… »
- « Pour le verbe Contrecarrer, je retiens… »
- « Pour le verbe Réveiller, je retiens… »
- « Pour le verbe Endormir, je retiens… »
- « Pour le verbe Défausser, je retiens… »

Les listes de la section 3 transcrivent ces messages, et non les recommandations ou les sélections par défaut des réponses précédentes. Pour Déplacer, la correction du créateur sur la priorité du ruleset borne la première validation de l'option C.

L'historique a été consulté depuis le premier message jusqu'à la demande de consignation : la lecture initiale limitée aux cinq derniers échanges a été complétée dans la conversation affichée dans Chrome.

### Validation de Renvoyer dans la continuation

Message explicite du créateur, consigné le 25 octobre 2026 :

> « Pour Renvoyer, je retiens : renvoi simple, conditionnel, déclenché, avec contrepartie et territorial. Le ruleset officiel reste prioritaire. Mets à jour le suivi sur la branche, puis continuons avec Permuter. »

Cette validation complète l'historique source ; elle remplace le statut antérieur « aucune variante validée » pour Renvoyer.

### Validation de Permuter dans la continuation

Le 25 octobre 2026, après la présentation de six variantes et la recommandation de retenir les cinq premières tout en gardant la permutation alliée–ennemie pour une expérimentation distincte, le créateur répond :

> « Parfait ça me va »

Cet accord est consigné comme validation de cette recommandation : permutation simple, conditionnelle, déclenchée, avec contrepartie et territoriale. Il ne constitue pas une validation des six variantes ni de leurs exemples détaillés.

### Report de Prévenir dans la continuation

Le 25 octobre 2026, après la présentation des six pistes, le créateur répond :

> « Je n’aime pas ce verbe ne l’utilisons pas pour le moment »

Cette instruction écarte provisoirement le verbe et toutes ses variantes du catalogue en cours ; la recommandation précédente de l'assistant n'est pas retenue.

### Refus de Produire dans la continuation

Le 25 octobre 2026, après la présentation des cinq variantes, le créateur répond :

> « Pas de création d’essence trop fort pour le jeu »

Ce refus écarte la production d'Essence par effet de carte du catalogue, pour un motif d'équilibrage. Il ne remet pas en cause la production officielle par les Sources.

### Validation de la méthode de création et réouverture des fonctions des couleurs

Le 25 octobre 2026, le créateur demande si le pipeline proposé convient, car il ne sait pas si les fonctions actuelles des couleurs seront conservées. Après la proposition de travailler dans l'ordre expériences de jeu, synergies, prototypes, parties, fonctions des couleurs puis catalogue et Heroes, il répond :

> « Go »

Cet accord valide la méthode et le démarrage de l'exploration des expériences de jeu. Il ne valide pas encore les expériences proposées ensuite, une nouvelle fonction de couleur ou des cartes.

### Choix des directions de jeu par le créateur

Le 25 octobre 2026, le créateur précise :

> « Je souhaite ces différentes vision de jeu une agressive, une plus control, une qui souhaite snowball dans la partie, une qui joue sur l’invocation de jeton, joueur avec la pioche la défausse, jouer sur les spells et réaction »

Ce message retient six directions de conception. Les explications et mécanismes proposés ensuite par l'assistant restent à discuter ; ils ne sont pas validés par anticipation.

### Accord pour le premier essai

Le 25 octobre 2026, après la présentation de Porte-enseigne, Rassemblement, Compagnon tenace et Pas de côté, le créateur répond « Go ». Ce choix est consigné comme accord pour utiliser ces quatre propositions comme base du premier essai, sans figer leur équilibrage. Les compositions et le protocole préparés ensuite restent des propositions de l'assistant.

### État conservé et prochaine discussion

- Le fichier est ajouté seul sur la branche dédiée `codex/catalogue-cartes-playtest`, issue du commit initial `e6edfb56b8ef2cfbfda7720603a03b3b38b56030`.
- Les règles officielles, leur changelog, les decks de test existants et les fichiers du jeu restent inchangés.
- Le [premier playtest symétrique existant](ruleset/70-playtest/decks-de-test.md) est distinct de ce catalogue expérimental ; sa présence ne valide pas les nouvelles cartes.
- L'examen de la liste initiale des quinze verbes est terminé. Prévenir est mis de côté pour le moment ; Produire est écarté. Les six directions de jeu sont choisies. Une étude propose six mécanismes à prototyper et une alternative de snowball territorial. L'accord pour poursuivre a conduit à quatre propositions de cartes formation/jetons (FJ-01 à FJ-04), acceptées comme base d'essai après le « Go » du créateur. Deux listes de 30 cartes et un protocole exploratoire sont préparés ; les parties restent à réaliser avant toute conclusion d'équilibrage ou répartition par couleur.
- Toute mise à jour du suivi devra distinguer le choix exact du créateur, sa source, les propositions restantes et les vérifications de règles. La formalisation de la restriction de couleurs dans le ruleset relève d'un travail ultérieur autorisé séparément.
