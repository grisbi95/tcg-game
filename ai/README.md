# ai/

Agents de jeu (`RefCounted`), qui héritent de `DuelAgent` (décision 0020) : `choose_intent(engine)` rend une intention que `DuelEngine.validate()` accepte, et `DuelHost` la soumet. Aucune lecture d'information cachée. `RandomLegalAgent` au J1 (étape 1.10), `GreedyAgent` au J4.
