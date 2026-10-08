#!/usr/bin/env node
/*
 * Cycle or preview ascii.rest full-colour scenes in a terminal.
 * Uses the vendored copy of ascii.rest (MIT, by @bas3line) — offline, no npx.
 */
import process from "node:process";
import { fileURLToPath } from "node:url";
import path from "node:path";
import fs from "node:fs";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const { play } = await import(path.join(root, "vendor", "ascii.rest", "dist", "terminal.js"));

const SCENES = fs
  .readFileSync(path.join(root, "scenes.txt"), "utf8")
  .split(/\r?\n/)
  .map((s) => s.trim())
  .filter((s) => s && !s.startsWith("#"));

const MOUSE_ON = "\x1b[?1003h\x1b[?1006h"; // report any motion, SGR encoding
const MOUSE_OFF = "\x1b[?1003l\x1b[?1006l";

function usage() {
  process.stdout.write(`Usage:
  play-scenes.mjs --list
  play-scenes.mjs --preview <scene> [--seconds N] [--light]
  play-scenes.mjs --cycle [--seconds N] [--light] [--order shuffle|sequential|random]
                  [--only a,b,c] [--mouse] [--grace S]
`);
}

function parseArgs(argv) {
  const opts = { mode: "cycle", scene: null, seconds: 45, light: false, order: "shuffle", only: null, mouse: false, grace: 1.5 };
  const num = (flag, v) => {
    const n = Number(v);
    if (!(n >= 0) || Number.isNaN(n)) throw new Error(`${flag} needs a number`);
    return n;
  };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    switch (a) {
      case "--list": opts.mode = "list"; break;
      case "--cycle": opts.mode = "cycle"; break;
      case "--preview":
        opts.mode = "preview";
        opts.scene = argv[++i];
        if (!opts.scene) throw new Error("--preview needs a scene name");
        break;
      case "--seconds":
        opts.seconds = num(a, argv[++i]);
        if (opts.seconds <= 0) throw new Error("--seconds must be > 0");
        break;
      case "--light": opts.light = true; break;
      case "--order":
        opts.order = argv[++i];
        if (!["shuffle", "sequential", "random"].includes(opts.order)) throw new Error("--order must be shuffle, sequential or random");
        break;
      case "--only":
        opts.only = String(argv[++i] || "").split(/[,\s]+/).filter(Boolean);
        break;
      case "--mouse": opts.mouse = true; break;
      case "--grace": opts.grace = num(a, argv[++i]); break;
      case "-h": case "--help": usage(); process.exit(0);
      default: throw new Error(`unknown argument: ${a}`);
    }
  }
  return opts;
}

const shuffle = (arr) => {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
};

function checkScene(name) {
  if (!SCENES.includes(name)) throw new Error(`unknown scene "${name}". Known scenes:\n  ${SCENES.join("\n  ")}`);
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));

  if (opts.mode === "list") {
    process.stdout.write(SCENES.join("\n") + "\n");
    return 0;
  }

  if (opts.mode === "preview") {
    checkScene(opts.scene);
    const r = await play(opts.scene, { seconds: opts.seconds, light: opts.light });
    return r.interrupted ? 130 : 0;
  }

  // --cycle
  let pool = SCENES;
  if (opts.only?.length) {
    opts.only.forEach(checkScene);
    pool = opts.only;
  }

  // Our own input listener, attached before play() so it sees every key /
  // mouse report too. play() stops on any input but only flags Ctrl+C, so this
  // is how we tell "user woke up" from "scene time is over".
  const stdin = process.stdin;
  const tty = stdin.isTTY === true && typeof stdin.setRawMode === "function";
  const startedAt = Date.now();
  let dismissed = false;
  const onInput = () => {
    if ((Date.now() - startedAt) / 1000 >= opts.grace) dismissed = true;
  };
  const cleanup = () => {
    if (opts.mouse && process.stdout.isTTY) process.stdout.write(MOUSE_OFF);
  };
  process.on("exit", cleanup);
  if (tty) {
    stdin.setRawMode(true);
    stdin.on("data", onInput);
    stdin.resume();
  }
  if (opts.mouse && process.stdout.isTTY) process.stdout.write(MOUSE_ON);

  let deck = [];
  for (;;) {
    let scene;
    if (opts.order === "random") scene = pool[Math.floor(Math.random() * pool.length)];
    else {
      if (!deck.length) deck = opts.order === "sequential" ? [...pool] : shuffle(pool);
      scene = deck.shift();
    }
    const r = await play(scene, { seconds: opts.seconds, light: opts.light });
    if (r.interrupted) return 130;
    if (dismissed) return 0;
    if (!process.stdout.isTTY) return 0; // nothing to draw on
  }
}

main().then(
  (code) => process.exit(code ?? 0),
  (err) => {
    process.stderr.write(`ascii-screensaver: ${err?.message || err}\n`);
    process.exit(1);
  },
);
