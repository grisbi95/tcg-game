# Relais du duel à distance

Décisions 0043 et 0049. Petit serveur Node.js qui apparie deux navigateurs par un code de partie et
transmet leurs messages tels quels : aucune règle, rien d'enregistré. Hors export du jeu
(`.gdignore`, filtre `tools/*`). Protocole de contrôle décrit dans `app/relay_connection.gd`.

```bash
cd tools/relay && npm install     # une fois
cd tools/relay && npm start       # ws://localhost:8080 ; port par la variable PORT
cd tools/relay && npm test        # appariement, transmission, départ, erreurs
```

Hébergement : tout service Node gratuit (Render ou équivalent) ; commande de démarrage `npm start`,
le port vient de `PORT`. L'offre gratuite met le serveur en veille sans usage : la première
connexion d'une séance attend 30 s à 1 min.
