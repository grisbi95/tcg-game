// Relais du duel à distance (décision 0049) : appariement par code, transmission, départ d'un
// joueur, erreurs. Lancé par `npm test` ; client WebSocket intégré à Node 22.

import { test, before, after } from "node:test";
import assert from "node:assert/strict";
import { startRelay } from "./server.js";

let relay;
let url;

before(async () => {
  relay = startRelay(0);
  await new Promise((resolve) => relay.http.once("listening", resolve));
  url = `ws://127.0.0.1:${relay.http.address().port}`;
});

after(() => relay.close());

// Client qui garde ses messages reçus et les rend un à un, dans l'ordre.
async function connect() {
  const socket = new WebSocket(url);
  const inbox = [];
  const waiters = [];
  socket.addEventListener("message", (event) => {
    const waiter = waiters.shift();
    if (waiter) waiter(event.data);
    else inbox.push(event.data);
  });
  await new Promise((resolve) => socket.addEventListener("open", resolve, { once: true }));
  const next = () =>
    inbox.length > 0
      ? Promise.resolve(inbox.shift())
      : new Promise((resolve) => waiters.push(resolve));
  const nextJson = async () => JSON.parse(await next());
  return { socket, next, nextJson, sendJson: (data) => socket.send(JSON.stringify(data)) };
}

async function pairedClients() {
  const host = await connect();
  host.sendJson({ relay: "create" });
  const created = await host.nextJson();
  const guest = await connect();
  guest.sendJson({ relay: "join", code: created.code.toLowerCase() });
  assert.deepEqual(await host.nextJson(), { relay: "paired" });
  assert.deepEqual(await guest.nextJson(), { relay: "paired" });
  return { host, guest, code: created.code };
}

test("une partie créée reçoit un code de quatre caractères sans ambiguïté", async () => {
  const host = await connect();
  host.sendJson({ relay: "create" });
  const created = await host.nextJson();
  assert.equal(created.relay, "created");
  assert.match(created.code, /^[A-HJKMNP-Z2-9]{4}$/);
  host.socket.close();
});

test("les messages passent tels quels entre les deux joueurs appariés", async () => {
  const { host, guest } = await pairedClients();
  const text = '{"kind":"HELLO","protocol_version":1,"ruleset_edition":"0.43"}';
  host.socket.send(text);
  assert.equal(await guest.next(), text);
  guest.socket.send("retour");
  assert.equal(await host.next(), "retour");
  host.socket.close();
});

test("le départ d'un joueur prévient l'autre et ferme la partie", async () => {
  const { host, guest, code } = await pairedClients();
  guest.socket.close();
  assert.deepEqual(await host.nextJson(), { relay: "peer_left" });
  const late = await connect();
  late.sendJson({ relay: "join", code });
  assert.deepEqual(await late.nextJson(), { relay: "error", reason: "unknown_code" });
});

test("un code inconnu, une partie pleine et une demande illisible sont refusés", async () => {
  const unknown = await connect();
  unknown.sendJson({ relay: "join", code: "ZZZZ" });
  assert.deepEqual(await unknown.nextJson(), { relay: "error", reason: "unknown_code" });
  const { host, code } = await pairedClients();
  const third = await connect();
  third.sendJson({ relay: "join", code });
  assert.deepEqual(await third.nextJson(), { relay: "error", reason: "room_full" });
  const garbled = await connect();
  garbled.socket.send("pas du JSON");
  assert.deepEqual(await garbled.nextJson(), { relay: "error", reason: "bad_request" });
  host.socket.close();
});
