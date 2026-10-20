# 0006 — Un autoload AppEvents de signals seuls

- Statut : acceptée ; exception par 0011
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : communication entre objets éloignés (bus d'événements)

## Contexte

The Shaggy Dev recommande un bus d'événements en autoload pour les objets éloignés, et met en garde contre l'autoload fourre-tout. Le prototype refusait tout autoload. Le flux `Array[DuelEvent]` du moteur est déjà le canal des faits de jeu.

## Options envisagées

- Option A : aucun autoload. Cohérent, mais le flux d'écrans et l'audio obligent à transporter des références sur plusieurs niveaux, ce que l'article déconseille.
- Option B : un seul autoload `AppEvents` qui ne contient que des signals d'application (`scene_requested`, `audio_requested`, `settings_changed`), ni variable, ni fonction, ni référence. Les faits de jeu restent dans `Array[DuelEvent]`.
- Option C : un bus pour tout, faits de jeu compris. Deux canaux pour une même vérité, dérive possible entre vue et état.

## Décision

Option B, validée le 16 octobre 2026. `app/app_events.gd`, créé au J2. Aucun autre autoload sans décision.

## Conséquences et vérification

- Relecture : tout ajout à `AppEvents` autre qu'un signal est un bloquant (`code-guidelines.md` §3, §8).
- Les vues du duel n'écoutent jamais `AppEvents` pour un fait de jeu.
- À réexaminer si un second domaine d'application (réseau, comptes) justifie un bus thématique séparé.

## Références

`docs/code-guidelines.md` §3 ; proposition §7.2 ; article « observer pattern » de The Shaggy Dev.
