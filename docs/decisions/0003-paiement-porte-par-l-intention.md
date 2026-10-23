# 0003 — Paiement porté par l'intention

- Statut : acceptée ; complétée par 0026 ; modifiée par 0047
- Date : 2026-10-16
- Décideur : créateur du projet
- Périmètre : paiement des coûts en Essence (203)

## Contexte

Le ruleset fait payer à l'annonce (203.3.2) et laisse au joueur le choix d'incliner une Source redressée ou de recycler une Source inclinée (203.2.1, 203.2.2), le recyclage étant définitif (203.2.3). Le moteur doit savoir comment le joueur paie.

## Options envisagées

- Option A : `EssencePayment {incline: n, recycle: m}` porté par chaque intention qui paie (`Deploy`, `CastSpell`, `UseHeroPower`, `AttachGear`). Les Sources étant fongibles, deux entiers suffisent ; `validate()` vérifie `n + m = coût`, `n ≤` redressées, `m ≤` inclinées.
- Option B : le moteur incline d'abord et ne recycle que si nécessaire. Simple, mais retire au joueur un choix que le ruleset lui donne (recycler pour garder des Sources redressées pour répondre).
- Option C : paiement en deux intentions séparées (produire, puis annoncer). Casse 203.2.4 (produire seulement au moment de payer).

## Décision

Option A, validée le 16 octobre 2026. La vue propose le paiement par défaut « incliner d'abord » et laisse le joueur ajuster.

## Conséquences et vérification

- Événements `SourceInclined`, `SourceRecycled` par Source ; `Fonte` incrémentée.
- Tests 203.2.1 à 203.3.3 : paiement exact, refus si insuffisant, Essence perdue si l'annonce n'a pas lieu (203.3.3).
- À réexaminer si le ruleset introduit des Sources non fongibles.

## Références

Ruleset 203 ; proposition §2.5.
