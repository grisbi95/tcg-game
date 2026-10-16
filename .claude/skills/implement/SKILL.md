---
name: implement
description: Brief type pour faire implémenter une liste d'identifiants du ruleset par l'agent rules-implementer, puis vérifier. Usage : /implement 206.3 ou /implement 205.1.6 205.1.7 205.1.8
---

# Implémenter des règles

Arguments : une section (`206.3`) ou une liste d'identifiants.

1. Lis les règles visées dans `docs/ruleset/20-regles-completes/<chapitre>.md` et vérifie qu'aucune n'est À ARBITRER ni supprimée. Si une règle manque ou est ambiguë, arrête-toi : propose la question ouverte du ruleset au lieu de coder.
2. Si les règles exigent un système nouveau (nouvelle sorte d'entrée de pile, nouveau `kind`, nouveau champ d'état structurant), présente 2 ou 3 options et attends le choix avant toute implémentation ; consigne ensuite avec `adr-writer`.
3. Lance **un seul** agent `rules-implementer` avec ce brief :
   - identifiants exacts et chapitre ; module cible selon `rules/CLAUDE.md` ; suite de tests cible ;
   - intentions et événements concernés, raisons de refus à ajouter en fin d'enum ;
   - « terminé = » : tests nommés par identifiant verts, `tools/lint.sh` propre, rapport court.
4. À son retour, lance `verifier` si l'agent n'a pas donné le résumé des tests. Ne relis pas la sortie brute des tests dans la conversation.
5. Mets à jour `docs/roadmap.md` si l'étape avance.
