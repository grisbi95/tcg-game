# 0200 · Action normale par pièce et réveil

> Décision consignée le 22 octobre 2026. Statut : ACTÉ. Une décision ne se modifie jamais ; pour revenir dessus, une nouvelle décision la remplace et cette ligne reçoit « Remplacée par NNNN ».

## Contexte

Une série de 1000 parties simulées sous le ruleset 0.37 (moteur seul, decks de test en miroir, Capitaine des deux côtés, même agent heuristique des deux côtés) a montré une congestion du plateau : dès le tour 8, la première rangée est pleine (Hero et 4 cases) et une seule pièce peut en sortir par tour (204.4.6). L'Essence inutilisée vaut 2,92 (seuil 3), un joueur passe 2 tours sans rien jouer dans 46 % des parties (seuil 20 %), 16 % des parties finissent par la fatigue et 62 % des vainqueurs finissent à 15 PV. Une seconde campagne du 22 octobre 2026 (1000 parties par variante, mêmes graines, premier joueur alterné, six profils d'agent pour la sensibilité) a comparé la règle actuelle, la pioche à 1, l'action par Unit avec réveil, les deux, 2 actions normales par tour et 3 actions normales par tour. Aucune question ouverte d'origine.

Résultats de la campagne, robustes à tous les profils d'agent :

- L'action par Unit supprime les parties bloquées (règle actuelle 17 à 29 %, action par Unit 0 à 2 %).
- Elle ramène le tour de fin de 12,6 à 11,3 (agent de base ; 10,7 à 12,3 selon le profil).
- Elle ramène « 2 tours sans rien jouer » de 73 % à 14 % (agent de base ; 10 à 46 % selon le profil).
- Elle ramène l'Essence inutilisée de 3,61 à 1,77 (agent de base ; 0,45 à 2,36 selon le profil).
- Avec elle, aucun Hero ne perd 15 PV en un tour ; 12 à 19 % des parties ont un tour où un Hero perd 10 PV ou plus.

Limites : temps et pendule non mesurés (pas d'horloge en simulation), agent sans anticipation, qui ne recycle pas et garde sa main. Les valeurs absolues restent à mesurer en playtest humain ; le classement des options est robuste.

## Options envisagées

| Option | Pour | Contre |
| --- | --- | --- |
| A · Action normale par Unit, avec réveil : chaque Unit et le Hero font une action normale par tour de leur joueur, une pièce qui arrive sur le plateau est endormie | Supprime les parties bloquées et réduit l'Essence inutilisée et les tours sans rien jouer, dans tous les profils d'agent. | Corrige le pilier de la décision 0001 ; 12 à 19 % des parties ont un tour où un Hero perd 10 PV ou plus ; temps et pendule non mesurés. |
| B · Pioche à 1 seule | Supprime la fatigue et les pioches bloquées. | Garde la limite d'une action normale par tour, source de la congestion constatée. |
| C · Action par Unit et pioche à 1 | Supprime la fatigue et les pioches bloquées en plus de l'effet de A. | Augmente l'Essence inutilisée de 1,2 à 1,7 dans tous les profils : la main se vide. |
| D · 2 ou 3 actions normales par tour, une par pièce, sans réveil | Garde un nombre fixe d'actions par tour, sans état par pièce. | Non détaillé en discussion. |

## Choix

Le créateur a retenu l'option A le 22 octobre 2026. Les options B, C et D sont écartées : pioche à 1 seule ; action par Unit et pioche à 1 ; 2 ou 3 actions normales par tour, une par pièce, sans réveil. La limite « une action normale par tour » des décisions 0001 et 0035 (204.4.6) est remplacée par une action normale par pièce éveillée, et le pilier « Une décision de plateau engage » de la décision 0001 est corrigé.

Le contenu du choix :

- Une Unit qui arrive sur le plateau est endormie, sans exception : un jeton Unit et une Unit qui entre en jeu en attaquant (205.1.6) sont endormis eux aussi.
- Au début de son tour, un joueur réveille ses Units et son Hero.
- Le réveil est la première étape du début du tour : réveil, puis 204.3.2, puis 204.3.1, puis 204.3.6. 204.3.9 est inchangée.
- Chaque Unit éveillée peut faire une action normale (chapitre 205 : déplacement ou attaque). Une pièce endormie ne peut pas faire d'action normale.
- Après son action normale, la pièce reste endormie jusqu'à son prochain réveil. Elle s'endort dès l'annonce de son action normale, même si cette action échoue.
- Le Hero suit la même règle que les Units : réveillé au début du tour de son joueur, une action normale (déplacement, 205.3.1, inchangé), puis endormi. Le Hero placé pendant la préparation est endormi, comme toute pièce qui arrive sur le plateau, et il est réveillé au début du premier tour de son joueur.
- Les Buildings n'ont toujours pas d'action normale (202.2.17) et n'ont aucun état endormi ou éveillé.
- Pilier de 00-vision.md : « Chaque pièce agit au plus une fois par tour, et une pièce qui arrive sur le plateau attend le tour suivant pour agir : déployer, avancer ou attaquer engage. »

## Conséquences sur les règles

- Chapitre 204 : 204.3.10 et 204.3.11 (réveil) et 204.1.18 (Hero placé pendant la préparation) créés ; 204.3.8 (ordre du début du tour) et 204.4.5 (pièces éveillées) modifiées ; 204.4.6 supprimée, identifiant conservé ; 204.3.9 inchangée.
- Chapitre 205 : section 205.5 Sommeil et réveil créée, avec 205.5.1, 205.5.2, 205.5.3, 205.5.4, 205.5.4a, 205.5.4b, 205.5.5 et 205.5.6 ; 205.4.7 réécrite (la pièce s'endort dès l'annonce de son action normale, même si elle échoue).
- Une pièce qui quitte le plateau puis y revient y arrive de nouveau (210.3.1a, décision 0081) et arrive donc endormie selon 205.5.4 ; aucune règle nouvelle.
- Pilier de 00-vision.md corrigé ; la ligne « Échecs » du tableau des références n'est pas modifiée.
- Glossaire : Endormie, Éveillée et Réveiller ajoutés ; Action normale mise à jour.
- Décisions 0001 (pilier « Une décision de plateau engage »), 0034 (ordre du début du tour), 0035 (limite d'une action normale par tour) et 0047 (comptage de l'action normale dès son annonce) remplacées en partie ; leur texte n'est pas modifié.
- Le livret 10-regles-de-base.md n'a pas encore de texte et n'est pas modifié.

## Questions ouvertes créées

- Q-104 · L'état endormi ou éveillé d'une Unit ou d'un Hero est-il visible des deux joueurs, alors que 201.4 ne le dit pas ?
- Q-105 · Vainqueur intact : dans 54 à 76 % des parties simulées, quelle que soit la règle d'action, le vainqueur finit sans avoir perdu de PV, et 2,5 à 3,5 tours séparent le premier coup au Hero de la fin de la partie.
