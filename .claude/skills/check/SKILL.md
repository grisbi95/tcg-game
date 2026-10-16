---
name: check
description: Vérifie les .gd modifiés (analyse Godot --check-only) puis gdformat et gdlint. Usage : /check
---

# Vérifier le code

```bash
bash .claude/hooks/check_changed_gdscript.sh
tools/lint.sh            # --fix pour reformater
```

Corrige chaque diagnostic à sa source ; ne désactive pas une règle de `.gdlintrc` sans décision. `--check-only` ne remonte pas tous les warnings de typage : pour un fichier sensible, ouvre-le dans l'éditeur ou écris un test qui l'exerce.
