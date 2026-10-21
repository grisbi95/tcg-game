---
name: check
description: Vérifie le code sans lancer les tests : hook Godot sur les .gd modifiés, gdformat et gdlint, typage de tous les .gd, par l'agent verifier. Usage : /check
---

# Vérifier le code

Lance l'agent `verifier` avec la portée « code » ; les commandes font foi dans `CLAUDE.md` §6 et §7. Ne relis pas les sorties brutes ici.

Corrige chaque diagnostic à sa source ; ne désactive pas une règle de `.gdlintrc` sans décision. Pour reformater, `tools/lint.sh --fix`.
