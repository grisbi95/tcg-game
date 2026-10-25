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

Les noms et directions retenus comme base du playtest sont :

- **Rouge — Conquête** : attaque, pression et progression vers le Hero adverse.
- **Vert — Résilience** : défense, protection, Rempart et maintien des positions.
- **Violet — Subversion** : déplacement, repositionnement et manipulation des positions.
- **Bleu — Anticipation** : pioche, sélection de cartes, manipulation de Force et réponses.

Ces directions ne fixent pas encore des exclusivités mécaniques. Les tableaux de spécialités, de rareté d'accès à un effet, de forces et de faiblesses présentés par l'assistant restent des propositions de design. Les premières associations « Bleu–Mobilité », « Vert–Développement/Puissance » et « Violet–Ruse/Perturbation » ne sont pas les intitulés retenus pour ces quatre catalogues.

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

## 3. Verbes examinés et sélections explicites

Ordre du travail dans la conversation : Déplacer, Renforcer et Affaiblir ensemble, Détruire, Créer, Piocher, Consulter, Contrecarrer, Réveiller, Endormir, Défausser, puis Renvoyer dans la conversation de continuation.

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

## 4. Propositions en attente

Le renvoi à l'Arrivée reste non sélectionné. Aucune variante de Permuter n'est encore validée.

### Verbes candidats encore à examiner

Dans la sélection initiale de quinze verbes, les suivants n'ont pas encore reçu d'examen individuel suivi d'une validation :

- **13 — Permuter** : échanger les positions de deux Units ; prochaine discussion demandée après la sélection de Renvoyer. Le sens précis et les variantes restent proposés.
- **14 — Prévenir** : empêcher une destruction ; proposition à examiner.
- **15 — Produire** : produire de l'Essence par effet ; proposition à examiner.

Repousser, Attirer, Replier et Téléporter ont aussi été évoqués comme pistes autour du déplacement. Leurs noms ne constituent pas une liste supplémentaire de verbes validés. Les priorités 1, 2 et 3 assignées par l'assistant à la liste initiale restent des recommandations.

### Autres propositions non finalisées

- **Répartition par type** : 4 Units, 3 Spells, 1 Building et 1 Gear par couleur ; pour les neutres, 7 Units, 2 Spells, 2 Buildings et 1 Gear. Proposition de structure, sans validation explicite distincte.
- **Moteurs de synergie** : attaques / destructions pour le Rouge ; formations / survie pour le Vert ; déplacements / changements de position pour le Violet ; préparation de main / Spells et réactions pour le Bleu. Pistes de travail, sans répartition définitive des effets entre couleurs.
- **Prototype intermédiaire de 16 cartes** : quatre par couleur avant l'extension à 48 ; méthode suggérée, pas un remplacement du format retenu.
- **Déclencheurs et conditions** : familles, événements exacts, limitations et interactions à définir après les verbes. Les études de Riftbound servent d'inspiration, sans importer ses règles, mots-clés ou chiffres.
- **Cartes et Heroes nommés dans les exemples** : coûts, Forces, PV, textes, noms et listes finales non validés. Les exemples illustrent les variantes ; ils ne constituent pas des fiches de cartes approuvées.
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

### État conservé et prochaine discussion

- Le fichier est ajouté seul sur la branche dédiée `codex/catalogue-cartes-playtest`, issue du commit initial `e6edfb56b8ef2cfbfda7720603a03b3b38b56030`.
- Les règles officielles, leur changelog, les decks de test existants et les fichiers du jeu restent inchangés.
- Le [premier playtest symétrique existant](ruleset/70-playtest/decks-de-test.md) est distinct de ce catalogue expérimental ; sa présence ne valide pas les nouvelles cartes.
- La prochaine discussion porte sur **Permuter**, puis sur Prévenir et Produire.
- Toute mise à jour du suivi devra distinguer le choix exact du créateur, sa source, les propositions restantes et les vérifications de règles. La formalisation de la restriction de couleurs dans le ruleset relève d'un travail ultérieur autorisé séparément.
