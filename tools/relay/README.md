# Relais du duel à distance

Décisions 0043 et 0049. Petit serveur Node.js qui apparie deux navigateurs par un code de partie et
transmet leurs messages tels quels : aucune règle, rien d'enregistré. Hors export du jeu
(`.gdignore`, filtre `tools/*`). Protocole de contrôle décrit dans `app/relay_connection.gd`.

```bash
cd tools/relay && npm install     # une fois
cd tools/relay && npm start       # ws://localhost:8080 ; port par la variable PORT
cd tools/relay && npm test        # appariement, transmission, départ, erreurs
```

Hébergement : Render, offre gratuite, service `tcg-relais` (`wss://tcg-relais.onrender.com`, que le
jeu Web utilise par défaut, `app/relay_address.gd`), déployé depuis `main` à chaque commit qui touche
`tools/relay/` ; racine `tools/relay`, `npm install` puis `npm start`, le port vient de `PORT`.
L'offre gratuite met le serveur en veille sans usage : la première connexion d'une séance attend
30 s à 1 min.
