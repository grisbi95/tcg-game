// Relais du duel à distance (décisions 0043 et 0049) : apparie deux navigateurs par un code de
// partie et transmet leurs messages tels quels. Aucune règle, rien d'enregistré : une partie
// disparaît quand un de ses joueurs part. Protocole de contrôle décrit dans
// app/relay_connection.gd.

import { createServer } from "node:http";
import { randomInt } from "node:crypto";
import { WebSocketServer } from "ws";

const DEFAULT_PORT = 8080;
// Sans I, L, O, 0 ni 1 : un code se dicte sans confusion.
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
const CODE_LENGTH = 4;
const MAX_MESSAGE_BYTES = 64 * 1024;
// Un ping régulier garde la connexion ouverte à travers les proxies de l'hébergeur.
const HEARTBEAT_MSEC = 30_000;
// Une partie créée que personne ne rejoint est fermée.
const WAITING_ROOM_MSEC = 60 * 60 * 1000;
// Godot perd un message arrivé avec la fermeture : après son dernier message, le relais laisse
// le client fermer lui-même, et ne ferme qu'au-delà de ce délai.
const CLOSE_DELAY_MSEC = 5_000;

export function startRelay(port = DEFAULT_PORT) {
  const rooms = new Map();
  const http = createServer((request, response) => {
    response.writeHead(200, { "content-type": "text/plain; charset=utf-8" });
    response.end("relais tcg-game\n");
  });
  const wss = new WebSocketServer({ server: http, maxPayload: MAX_MESSAGE_BYTES });

  wss.on("connection", (socket) => {
    socket.isAlive = true;
    socket.on("pong", () => {
      socket.isAlive = true;
    });
    socket.on("message", (data, isBinary) => {
      if (socket.room) {
        forward(socket, data, isBinary);
      } else {
        openRoom(rooms, socket, data.toString());
      }
    });
    socket.on("close", () => leaveRoom(rooms, socket));
  });

  const heartbeat = setInterval(() => {
    for (const socket of wss.clients) {
      if (!socket.isAlive) {
        socket.terminate();
        continue;
      }
      socket.isAlive = false;
      socket.ping();
    }
  }, HEARTBEAT_MSEC);
  wss.on("close", () => clearInterval(heartbeat));

  http.listen(port);
  return {
    http,
    close: () =>
      new Promise((resolve) => {
        for (const socket of wss.clients) socket.terminate();
        wss.close(() => http.close(() => resolve()));
      }),
  };
}

function openRoom(rooms, socket, text) {
  const request = parseRequest(text);
  if (request?.relay === "create") {
    createRoom(rooms, socket);
  } else if (request?.relay === "join" && typeof request.code === "string") {
    joinRoom(rooms, socket, request.code.toUpperCase());
  } else {
    refuse(socket, "bad_request");
  }
}

function createRoom(rooms, socket) {
  const code = newCode(rooms);
  const room = { code, players: [socket] };
  room.expiry = setTimeout(() => closeRoom(rooms, room), WAITING_ROOM_MSEC);
  rooms.set(code, room);
  socket.room = room;
  send(socket, { relay: "created", code });
}

function joinRoom(rooms, socket, code) {
  const room = rooms.get(code);
  if (!room) {
    refuse(socket, "unknown_code");
    return;
  }
  if (room.players.length >= 2) {
    refuse(socket, "room_full");
    return;
  }
  clearTimeout(room.expiry);
  room.players.push(socket);
  socket.room = room;
  for (const player of room.players) send(player, { relay: "paired" });
}

// Avant l'appariement, un message de jeu n'a pas de destinataire : il est perdu.
function forward(socket, data, isBinary) {
  for (const player of socket.room.players) {
    if (player !== socket) player.send(data, { binary: isBinary });
  }
}

function leaveRoom(rooms, socket) {
  const room = socket.room;
  if (!room) return;
  for (const player of room.players) {
    if (player !== socket) sendThenClose(player, { relay: "peer_left" });
  }
  closeRoom(rooms, room);
}

function closeRoom(rooms, room) {
  clearTimeout(room.expiry);
  rooms.delete(room.code);
  for (const player of room.players) {
    player.room = null;
    closeLater(player);
  }
}

function newCode(rooms) {
  let code;
  do {
    code = Array.from(
      { length: CODE_LENGTH },
      () => CODE_ALPHABET[randomInt(CODE_ALPHABET.length)],
    ).join("");
  } while (rooms.has(code));
  return code;
}

function parseRequest(text) {
  try {
    return JSON.parse(text);
  } catch {
    return null;
  }
}

function refuse(socket, reason) {
  sendThenClose(socket, { relay: "error", reason });
}

function sendThenClose(socket, control) {
  send(socket, control);
  closeLater(socket);
}

function closeLater(socket) {
  setTimeout(() => socket.close(), CLOSE_DELAY_MSEC).unref();
}

function send(socket, control) {
  socket.send(JSON.stringify(control));
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const port = Number(process.env.PORT) || DEFAULT_PORT;
  startRelay(port);
  console.log(`Relais à l'écoute sur le port ${port}`);
}
