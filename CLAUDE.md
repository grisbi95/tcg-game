# Consignes du dossier tcg-ruleset

- Ce dossier est un ensemble de documents de règles, sans code. Il est indépendant du projet Godot `tactical_tcg`.
- Lire `CHARTE.md` avant toute modification. Elle fait foi sur la forme ; `20-regles-completes/` fait foi sur le fond.
- Toute création ou modification de fichier ici est déléguée à l'agent `ruleset-editor` (défini dans `~/.claude/agents/ruleset-editor.md`). La conversation principale tranche les questions de design ; l'agent consigne et rédige.
- Ne jamais écrire dans `20-regles-completes/` un point qui n'a pas été tranché : il va dans `02-questions-ouvertes.md`.
- Ne jamais renuméroter une règle ni modifier une décision consignée.
- Regrouper les consignations : lancer l'agent `ruleset-editor` une fois par chapitre terminé, ou toutes les cinq décisions au plus, jamais une fois par réponse. Les décisions en attente sont listées dans la conversation jusqu'à leur consignation.
