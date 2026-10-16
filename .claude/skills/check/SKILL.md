---
name: check
description: Vérifie les .gd modifiés (analyse Godot --check-only), gdformat et gdlint, puis le typage de tous les .gd. Usage : /check
---

# Vérifier le code

```bash
bash .claude/hooks/check_changed_gdscript.sh
tools/lint.sh            # --fix pour reformater
tools/check_typing.sh    # warnings de typage traités en erreurs
```

Corrige chaque diagnostic à sa source ; ne désactive pas une règle de `.gdlintrc` sans décision. Seul `tools/check_typing.sh` remonte les warnings de typage : l'analyse du hook les laisse passer.
