# 0005 — Export Web et hébergement par GitHub Pages

- Statut : acceptée
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : export, intégration continue, hébergement des builds de playtest

## Contexte

Le jeu vise le navigateur et les playtests ont besoin d'un lien stable. Godot 4 exporte en Web avec ou sans support des threads ; avec, l'hébergeur doit servir des en-têtes COOP et COEP.

## Options envisagées

- Option A : GitHub Pages, build par GitHub Actions à chaque fusion sur `main`, export sans threads (aucun en-tête spécial). Gratuit, automatique, lien permanent.
- Option B : itch.io, dépôt manuel du zip. Simple, mais manuel à chaque version.
- Option C : hébergeur propre avec en-têtes COOP et COEP et threads activés. Inutile pour un jeu sans thread.

## Décision

Option A, validée le 16 octobre 2026. Rendu GL Compatibility, « Thread support » désactivé, preset versionné (`export_presets.cfg`, J2), modèles d'export téléchargés par la CI. La CI exécute aussi les tests GdUnit4 et gdlint à chaque push.

## Conséquences et vérification

- `.github/workflows/ci.yml` : jobs tests et lint dès J0 ; job export et déploiement au J2.
- Vérification : première CI verte après la création du remote ; build Web ouverte dans deux navigateurs.
- À réexaminer si le réseau entre dans le périmètre ou si les performances exigent des threads.

## Références

Proposition §2.9 et §4.7.
