# ASCII Screensaver for Omarchy

Idle screensaver for [Omarchy](https://omarchy.org) that plays **all 15 full-colour scenes** from [ascii.rest](https://ascii.rest) instead of the stock TTE logo animation.

When your laptop sits untouched, Omarchy’s idle service (Quattro) or hypridle (3.x) launches the screensaver. This package hooks that path so you get animated ASCII coastlines, rain, fjords, reefs, and more — offline, vendored, no `npx` at runtime.

<p align="center">
  <a href="https://ascii.rest/night-coast/"><img src="https://ascii.rest/og/night-coast.png" width="32%" alt="night-coast"></a>
  <a href="https://ascii.rest/tokyo-rain/"><img src="https://ascii.rest/og/tokyo-rain.png" width="32%" alt="tokyo-rain"></a>
  <a href="https://ascii.rest/aurora-fjord/"><img src="https://ascii.rest/og/aurora-fjord.png" width="32%" alt="aurora-fjord"></a>
</p>

## Version

**1.0.3** — Sharper scenes: the screensaver terminal font is sized per monitor so the 200-column ascii.rest scenes show at full detail instead of Omarchy's size-18 blocks. Override with `ASCII_SCREENSAVER_FONT_SIZE`.

**1.0.2** — Entry point renamed to `AsciiScreensaverService.qml`. After installing or upgrading on a running session, run `omarchy restart shell` once: the running Quickshell keeps compiled QML and directory listings cached, so an in-place upgrade otherwise loads stale code.

**1.0.1** — Service.qml rebased on Omarchy **4.0.4-mac.1** stock idle (`IpcHandler`, not `ShellIpc`). Launcher wraps the installed `omarchy-launch-screensaver` so it matches that Omarchy build. Missing Node.js falls back to stock without breaking idle/lock.

## Credits

- **Scenes & player:** [ascii.rest](https://ascii.rest) by [@bas3line](https://github.com/bas3line) — MIT. Vendored as `vendor/ascii.rest` (npm package [`ascii.rest`](https://www.npmjs.com/package/ascii.rest) 0.2.1). See `NOTICE` and `third_party/ASCII.REST-LICENSE.txt`.
- **Idle / launch plumbing:** adapted from [Omarchy](https://github.com/omacom/omarchy) by David Heinemeier Hansson — MIT. See `AsciiScreensaverService.qml`, `IdleModel.js`, `bin/ascii-screensaver-launch`, and `third_party/OMARCHY-LICENSE.txt`.
- **This package:** MIT — Taras Kornichuk (`LICENSE`).

## Install (Omarchy Quattro — recommended)

This repo is a real Omarchy **shell plugin**: it clones the built-in idle service (`omarchy.idle`) and redirects only the screensaver launch to the ascii.rest player. Timings in `~/.config/omarchy/shell.json` stay as they are.

Requires [Node.js](https://nodejs.org/) for the ascii.rest scenes. Install it first if needed:

```bash
sudo pacman -S --needed nodejs
omarchy plugin add https://github.com/artile/omarchy-ascii-screensaver.git --enable
```

`omarchy plugin add` does not run install hooks, so optionally put the CLI on your PATH:

```bash
~/.config/omarchy/plugins/io.github.artile.ascii-screensaver/bin/ascii-screensaver-link-cli
```

Then open the screensaver once to try it (`System → Screensaver`, or `ascii-screensaver --launch` after linking).

If Node.js is missing, the idle plugin still loads and **falls back to the stock Omarchy screensaver** — idle timings and lock are unchanged. Re-add Node.js later and the ascii scenes come back automatically.

Update later with `omarchy plugin update io.github.artile.ascii-screensaver`.

### Remove

```bash
omarchy plugin remove io.github.artile.ascii-screensaver
```

That restores Omarchy’s stock idle service. If you also ran `./install.sh` (PATH hook), run `./uninstall.sh` as well.

> Replace the GitHub URL with your fork once the repo is public. Plugin id: `io.github.artile.ascii-screensaver`.

## Install (PATH hook — Omarchy 3.x / no plugin system)

Works without replacing the idle plugin: puts `omarchy-screensaver` ahead of `/usr/bin` via Omarchy’s documented `~/.config/uwsm/default` hook.

**One-liner** (after the repo is on GitHub):

```bash
git clone https://github.com/artile/omarchy-ascii-screensaver.git
cd omarchy-ascii-screensaver && ./install.sh
```

Or from a tarball:

```bash
tar -xzf omarchy-ascii-screensaver.tar.gz
cd omarchy-ascii-screensaver && ./install.sh
```

Log out/in (or restart Hyprland). Optional immediate test:

```bash
PATH="$HOME/.local/share/omarchy-ascii-screensaver/bin:$PATH" omarchy-launch-screensaver force
```

### Remove

```bash
~/.local/share/omarchy-ascii-screensaver/uninstall.sh
# add --purge to also delete ~/.config/omarchy-ascii-screensaver
```

## Usage

```bash
ascii-screensaver --list
ascii-screensaver --preview night-coast
ascii-screensaver --launch          # fullscreen on every monitor
ascii-screensaver                   # cycle in the current terminal
```

Config file (created on install): `~/.config/omarchy-ascii-screensaver/config`

```bash
ASCII_SCREENSAVER_SECONDS=45
ASCII_SCREENSAVER_ORDER=shuffle   # shuffle | sequential | random
ASCII_SCREENSAVER_ONLY=""         # or "night-coast,tokyo-rain"
ASCII_SCREENSAVER_LIGHT=0
```

Exit the fullscreen screensaver with **any key**, or when the screensaver window loses focus (same idea as stock Omarchy). Lock still tears it down by window class `org.omarchy.screensaver`.

## Scenes (15)

`alpine-dawn` · `aurora-fjord` · `deep-reef` · `desert-night` · `earthrise` · `kyoto-dusk` · `lantern-lake` · `marine-drive` · `misty-forest` · `night-coast` · `ocean-sunset` · `storm-plains` · `taj-dawn` · `tokyo-rain` · `varanasi-ghats`

## How it hooks Omarchy

| Omarchy | Idle trigger | What this package does |
|--------|--------------|------------------------|
| **4.x Quattro** | `omarchy.idle` service → `omarchy-launch-screensaver` | Plugin with `omarchy.clonedFrom: omarchy.idle` patches the *installed* launcher at runtime (absolute path to our `omarchy-screensaver`); non-zero exit falls back to stock |
| **3.x** | `hypridle` → `omarchy-launch-screensaver` | `install.sh` prepends this package’s `bin/` on PATH so `omarchy-screensaver` is ours |

Terminals: Alacritty, Foot, Ghostty, or Kitty (same constraint as stock Omarchy). Window class stays `org.omarchy.screensaver`.

## Requirements

- Omarchy on Arch (Hyprland)
- Node.js ≥ 18 (`pacman -S --needed nodejs`) — required for ascii scenes; without it the plugin falls back to stock
- install.sh can install Node.js for you (PATH-hook path)
- No network at screensaver time (ascii.rest is vendored)

## Catalog notes (for maintainers)

Where community Omarchy add-ons are listed, and how to submit — **do not submit until the GitHub repo is public and you are ready**:

1. **Shell plugins (this package fits here)** — [omarchyplugins.com](https://omarchyplugins.com) / [omacom/omarchy-plugin-marketplace](https://github.com/omacom/omarchy-plugin-marketplace)  
   - Need: public GitHub repo, root `manifest.json`, README with install/remove, LICENSE, unique id (not `omarchy.*`). Optional `preview.png`.  
   - Submit: GitHub issue on that repo with title `[Plugin]: ASCII Screensaver`, body from [SUBMISSION.md](https://github.com/omacom/omarchy-plugin-marketplace/blob/main/SUBMISSION.md) (or the [submit-plugin form](https://github.com/omacom/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)).  
   - Suggested metadata: category `System`, tags `system`, `hyprland`.  
   - Publication requires automated validation + maintainer `approved-and-verified`.

2. **Themes only** — [omarchy.org/themes](https://omarchy.org/themes/) via PR to [omacom-io/omarchy-site](https://github.com/omacom-io/omarchy-site) (documented in Omarchy manual §43). Not applicable here.

3. **Community theme lists** — e.g. [Wheel-Smith/awesome-omarchy](https://github.com/Wheel-Smith/awesome-omarchy) (themes; PR with preview + repo URL). Not for shell plugins.

Official plugin docs: Omarchy manual [Shell Plugins](https://omarchy.org/manual/) chapter 32 / repo `manual/32-shell-plugins.md`.

---

## Українською (коротко)

Screensaver для Omarchy зі всіх 15 кольорових сцен [ascii.rest](https://ascii.rest) (@bas3line, MIT).

**Встановлення (Omarchy 4):**
```bash
sudo pacman -S --needed nodejs
omarchy plugin add https://github.com/artile/omarchy-ascii-screensaver.git --enable
~/.config/omarchy/plugins/io.github.artile.ascii-screensaver/bin/ascii-screensaver-link-cli   # опційно, CLI у PATH
```
Без Node.js плагін все одно завантажується і показує стандартний screensaver Omarchy.

**Або через скрипт (Omarchy 3 / без плагінів):**
```bash
git clone https://github.com/artile/omarchy-ascii-screensaver.git
cd omarchy-ascii-screensaver && ./install.sh
```
Після цього — logout/login. Перевірка: `ascii-screensaver --launch`.

**Видалення:** `omarchy plugin remove io.github.artile.ascii-screensaver` і/або `~/.local/share/omarchy-ascii-screensaver/uninstall.sh`.

Сцени: night-coast, tokyo-rain, aurora-fjord, earthrise, kyoto-dusk та інші (див. `ascii-screensaver --list`).
