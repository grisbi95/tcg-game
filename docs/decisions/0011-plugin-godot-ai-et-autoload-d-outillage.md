# 0011 — Plugin Godot AI et son autoload d'outillage

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : outillage de l'éditeur (MCP `godot-ai`) et exception à la décision 0006

## Contexte

Le MCP `godot-ai` permet à Claude de piloter l'éditeur ouvert : ouvrir et lancer une scène, en faire une capture, lire les logs, inspecter la hiérarchie. Il sert surtout à la vérification des vues exigée par la définition de terminé (« scène lancée et comportement vérifié »). Le plugin `addons/godot_ai/` (4.3.0, qui inscrit lui-même le serveur de même version dans Claude Code, en scope local) enregistre l'autoload `_mcp_game_helper` à chaque activation, pour capturer l'image du jeu lancé depuis l'éditeur. La décision 0006 interdit tout autoload autre qu'`AppEvents` sans décision.

## Options envisagées

- Option A : accepter `_mcp_game_helper` comme exception d'outillage. Le MCP reste disponible pour l'interface. Coût : un second autoload dans `project.godot`, qui n'est pas du code du jeu. Limite : retiré des exports par le plugin, inactif dans l'éditeur et sans canal de débogage, il ne fait rien dans le build Web.
- Option B : retirer le plugin et le MCP. Respect littéral de 0006, mais la vérification visuelle des vues redevient manuelle. L'autoload ne peut pas être retiré seul : le plugin le réécrit à chaque activation.

## Décision

Option A, validée le 16 octobre 2026. `_mcp_game_helper` est le seul autoload admis en plus d'`AppEvents`. Ce n'est pas un précédent : tout autre autoload, d'outillage compris, demande sa propre décision.

## Conséquences et vérification

- Aucun script de `data/`, `rules/`, `ai/`, `app/` ou `ui/` ne référence `_mcp_game_helper` ni `addons/godot_ai/` ; la relecture le traite comme bloquant.
- `addons/godot_ai/` ne s'édite pas ; le plugin et le serveur `godot-ai==4.3.0` changent de version ensemble ; l'inscription du serveur reste au plugin, rien n'est versionné.
- Le MCP vérifie et construit les scènes ; les `.gd` s'éditent toujours avec `Edit` ou `Write` pour passer par le hook ; `project.godot` et les autoloads ne se modifient jamais par le MCP.
- Vérification : au premier export Web (J2), l'autoload est absent du pack ; `tools/run_tests.sh` reste vert avec le plugin activé (155 tests le 16 octobre 2026).
- À réexaminer si l'export embarque l'autoload, si une mise à jour du plugin ajoute un autre autoload, ou si le MCP n'est pas employé au J2.

## Références

Décision 0006 ; `.claude/README.md` (MCP) ; `addons/godot_ai/runtime/game_helper.gd` et `export/mcp_export_plugin.gd` ; `ui/CLAUDE.md` ; proposition §4.6.
