# Charte éditoriale du ruleset

> Cahier des charges de tous les documents du dossier. Toute modification doit la respecter. Version 2, 15 octobre 2026.

## 1 Principes

- **Une seule source de vérité.** `20-regles-completes/` fait foi. Le livret, les guides et les rulings en dérivent et ne le contredisent jamais. En cas d'écart, c'est le document dérivé qui est faux.
- **Séparer le quoi, le comment apprendre et le pourquoi.** Le quoi est dans les règles complètes. Le comment apprendre est dans le livret. Le pourquoi est dans la vision, les guides et les décisions. Une justification n'a pas sa place dans une règle.
- **Rien d'implicite.** Un point non tranché n'entre pas dans les règles complètes, même en commentaire. Il va dans `02-questions-ouvertes.md`.
- **Tout est daté en absolu.** Jamais « hier » ou « la semaine prochaine » : toujours une date complète.

## 2 Langue et vocabulaire

- Les documents sont écrits en français.
- Les termes `Hero`, `Unit`, `Building`, `Spell` et `Gear` restent en anglais, avec majuscule, au singulier comme au pluriel (« deux Units »).
- Tout terme technique est défini dans `01-glossaire.md` avant d'être employé ailleurs. Un document n'introduit jamais un terme que le glossaire ignore.
- Un même concept a un seul nom. Pas de synonymes : on écrit « Source », jamais « Filon » ni « rune » pour le désigner.
- Les nombres s'écrivent en chiffres. Les PV, l'Essence et la Force s'écrivent avec leur unité : « 3 Essence », « Force 4 », « 15 PV ».
- Pas d'abréviation maison, pas de « etc. », pas de « … » dans une règle.

## 3 Règles complètes : forme

- Un chapitre par fichier, numéroté de 200 à 299. Les numéros de chapitre libres servent aux chapitres futurs ; on n'intercale pas.
- Un chapitre s'ouvre sur un en-tête de statut, puis une section **Invariants** : les faits qui restent vrais quel que soit l'état de la partie.
- Un chapitre est découpé en sections numérotées `205.1`, `205.2`, titrées en H2.
- Une règle porte un identifiant à trois niveaux : `205.1.3`. Une sous-règle ajoute une lettre : `205.1.3a`.
- Une règle est **une phrase, au présent, vérifiable**. Si une règle a besoin de « et » pour être complète, c'est deux règles. Si elle a besoin de « sauf », l'exception est une sous-règle.
- Une règle ne contient ni exemple, ni justification, ni renvoi à un jeu de référence. Les exemples vivent dans le livret et les guides.
- Une règle porte son statut entre crochets : `[ACTÉ]` ou `[PROVISOIRE]`. Une règle PROVISOIRE porte sa valeur et ce que le playtest doit mesurer pour la fixer.
- Une règle qui renvoie à une autre cite son identifiant complet : « voir 208.2.4 ».
- Un Invariant porte un identifiant de la forme `201.0.1` (chapitre, section 0, numéro), avec son statut entre crochets et la décision qui le fonde, comme toute règle. La section 0 est réservée aux Invariants.

## 4 Numérotation : stabilité

- Un identifiant est définitif. Il n'est **jamais renuméroté**, même si l'ordre de lecture en souffre.
- Une règle nouvelle prend le numéro suivant disponible dans sa section. Si sa place logique est ailleurs, on la place sous le bon titre avec son numéro, sans décaler les autres.
- Une règle supprimée garde son identifiant dans le fichier, avec la seule mention : « Supprimée en édition X.Y, voir décision NNNN. »
- La section 0 de chaque chapitre, titrée **Invariants**, est réservée aux Invariants. Leurs identifiants (`201.0.1`) suivent les mêmes règles de stabilité que les autres : jamais renumérotés, jamais réutilisés, suppression avec identifiant conservé.
- Une section nouvelle prend le numéro suivant du chapitre, la section 0 exceptée. Un chapitre nouveau prend un numéro libre entre 200 et 299.
- Un chapitre qui dépasse 60 règles est un signal : proposer une scission en question ouverte, sans l'exécuter seul.

## 5 Statuts

| Statut | Sens | Où il vit |
| --- | --- | --- |
| ACTÉ | Décision retenue, consignée dans `40-decisions/`. | Règles complètes, glossaire |
| PROVISOIRE | Valeur de test, à mesurer. La règle existe, sa valeur peut bouger. | Règles complètes |
| À ARBITRER | Point non tranché. | `02-questions-ouvertes.md` uniquement |

Un point À ARBITRER n'apparaît jamais dans `20-regles-completes/`, ni dans le livret.

## 6 Décisions

- Une décision par fichier dans `40-decisions/`, nommé `NNNN-titre-court.md`, numéroté dans l'ordre de prise.
- Une décision suit `0000-modele.md` : contexte, options envisagées avec leurs compromis, choix, conséquences sur les règles, questions ouvertes créées.
- Une décision consignée n'est **jamais modifiée**. Pour revenir dessus, une nouvelle décision la cite et la remplace ; l'ancienne reçoit une seule ligne en tête : « Remplacée par NNNN. »
- Toute règle ACTÉ cite la décision qui la fonde, en fin de phrase : « (décision 0002) ».

## 7 Questions ouvertes

- Une entrée par point, identifiée `Q-NNN`, numérotée dans l'ordre de création. Un numéro n'est jamais réutilisé.
- Chaque entrée tient : la question en une phrase, la règle ou le chapitre concerné, les options avec un compromis chacune, ce qui manque pour trancher, et la date d'ouverture.
- Une question tranchée est déplacée en fin de fichier, dans la section **Tranchées**, avec le numéro de la décision. Elle n'est pas supprimée.

## 8 Glossaire

- Une entrée par ligne, dans un tableau, par ordre alphabétique.
- Une définition tient en une phrase et ne contient pas d'exemple.
- Une entrée porte son statut si le terme désigne une mécanique non actée.
- Un terme retiré du jeu reste dans le glossaire avec la mention « Retiré en édition X.Y ».

## 9 Éditions et changelog

- Avant la première partie complète jouée avec ce ruleset, les éditions sont numérotées `0.x`. La première édition jouée complète devient `1.0`.
- Une édition **mineure** clarifie ou reformule sans changer le comportement d'aucune carte ni d'aucune situation. Une édition **majeure** change un comportement. Pendant la phase `0.x`, chaque session qui modifie une règle incrémente le second chiffre.
- Le changelog reçoit une entrée par édition : date, type, liste des identifiants ajoutés, modifiés ou supprimés, décisions associées.
- Chaque carte du futur catalogue porte l'édition sous laquelle elle a été écrite.

## 10 Cohérence à chaque modification

Après toute modification d'une règle, vérifier dans cet ordre :

1. Le glossaire définit chaque terme employé.
2. Le chapitre 210 est à jour si un mot-clé est touché.
3. Les renvois vers l'identifiant modifié sont encore justes (`grep` sur l'identifiant).
4. `02-questions-ouvertes.md` ne contient plus un point que la modification tranche.
5. Le changelog porte la ligne de l'édition.
6. Le livret n'est modifié que si le chapitre concerné est stable, et alors il est relu en entier.

## 11 Format Markdown

- Un seul titre H1 par fichier, qui est le nom du document. Un bloc de citation sous le H1 porte le rôle du document, son statut et sa date.
- Les sections sont en H2, les sous-sections en H3. Pas de niveau plus profond.
- Les listes de valeurs et de correspondances sont en tableau. Les énumérations courtes sont en liste à puces.
- Les liens internes sont relatifs au dossier. Aucun lien vers un fichier de `tactical_tcg`.
- Pas d'emoji, pas de texte en majuscules hors des statuts et des identifiants.

## 12 Rôle de l'agent `ruleset-editor`

- La conversation principale tranche. L'agent rédige, consigne et vérifie la cohérence. Il ne prend aucune décision de design.
- Quand il reçoit une consigne ambiguë ou un point non tranché, il crée une question ouverte au lieu d'écrire une règle.
- Il termine chaque intervention par un rapport : fichiers touchés, identifiants ajoutés ou modifiés, termes ajoutés au glossaire, questions ouvertes créées ou tranchées, ligne de changelog.
