#!/usr/bin/env bash
# Install ascii.rest scenes as the Omarchy screensaver (update-safe).
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-ascii-screensaver"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-ascii-screensaver"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-ascii-screensaver"
MARKER_BEGIN="# BEGIN omarchy-ascii-screensaver"
MARKER_END="# END omarchy-ascii-screensaver"
UWSM_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/default"
UWSM_ENV_D="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env.d/50-ascii-screensaver"
LOCAL_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"
PATH_BIN="$DEST/bin"
# Prefer a $HOME-relative path in the uwsm hook when using the default data dir,
# so the hook still works if the username/home path is the same shape after restore.
if [[ $DEST == "$HOME/.local/share/omarchy-ascii-screensaver" ]]; then
  # shellcheck disable=SC2016 # literal $HOME, expanded later by uwsm
  PATH_BIN_HOOK='$HOME/.local/share/omarchy-ascii-screensaver/bin'
else
  PATH_BIN_HOOK=$PATH_BIN
fi

log() { printf '→ %s\n' "$*"; }
die() { printf '✗ %s\n' "$*" >&2; exit 1; }

ensure_node() {
  if command -v node >/dev/null 2>&1; then
    log "Node.js: $(node -v)"
    return 0
  fi
  if command -v pacman >/dev/null 2>&1; then
    log "Node.js missing — installing via pacman (sudo required)…"
    sudo pacman -S --needed --noconfirm nodejs || die "failed to install nodejs"
    command -v node >/dev/null 2>&1 || die "nodejs installed but node is not on PATH"
    log "Node.js: $(node -v)"
    return 0
  fi
  die "Node.js is required. Install with: sudo pacman -S --needed nodejs"
}

install_files() {
  mkdir -p "$DEST" "$STATE_DIR" "$CFG_DIR" "$LOCAL_BIN" \
    "$(dirname "$UWSM_ENV_D")" "$(dirname "$UWSM_DEFAULT")"
  log "Installing into $DEST"
  rm -rf "$DEST"
  mkdir -p "$DEST"
  cp -a "$SRC/bin" "$SRC/lib" "$SRC/vendor" "$SRC/scenes.txt" \
    "$SRC/README.md" "$SRC/LICENSE" "$SRC/NOTICE" "$SRC/third_party" \
    "$SRC/manifest.json" "$SRC/AsciiScreensaverService.qml" "$SRC/IdleModel.js" \
    "$SRC/install.sh" "$SRC/uninstall.sh" "$DEST/"
  [[ -f $SRC/config.example ]] && cp -a "$SRC/config.example" "$DEST/"
  chmod +x "$DEST/bin/"* "$DEST/lib/play-scenes.mjs" "$DEST/install.sh" "$DEST/uninstall.sh"

  ln -sfn "$DEST/bin/ascii-screensaver" "$LOCAL_BIN/ascii-screensaver"
  log "CLI: $LOCAL_BIN/ascii-screensaver"

  if [[ ! -f $CFG_DIR/config ]]; then
    cp -a "$SRC/config.example" "$CFG_DIR/config"
    log "Config: $CFG_DIR/config"
  else
    log "Config already present: $CFG_DIR/config (left untouched)"
  fi
}

path_snippet() {
  # Expand DEST so it works even if the user relocates XDG_DATA_HOME later.
  cat <<SNIP
$MARKER_BEGIN
# Prepend so this overrides /usr/bin/omarchy-screensaver (and \$OMARCHY_PATH/bin).
# Managed by omarchy-ascii-screensaver — remove via uninstall.sh
case ":\${PATH:-}:" in
  *":$PATH_BIN_HOOK:"*) ;;
  *) export PATH="$PATH_BIN_HOOK\${PATH:+:\$PATH}" ;;
esac
$MARKER_END
SNIP
}

strip_markers() {
  local file=$1 out
  out="$(mktemp)"
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { print }
  ' "$file" >"$out"
  # Drop a trailing blank line left where the block was.
  if [[ -s $out ]]; then
    printf '%s\n' "$(cat "$out")" >"$file"
  else
    : >"$file"
  fi
  rm -f "$out"
}

hook_uwsm() {
  # Primary Omarchy hook: ~/.config/uwsm/default is sourced by
  # /usr/share/uwsm/env.d/10-omarchy (v4) and by ~/.config/uwsm/env (v3).
  mkdir -p "$(dirname "$UWSM_DEFAULT")"
  if [[ -f $UWSM_DEFAULT ]]; then
    if [[ ! -f $STATE_DIR/uwsm-default.bak ]]; then
      cp -a "$UWSM_DEFAULT" "$STATE_DIR/uwsm-default.bak"
      log "Backup: $STATE_DIR/uwsm-default.bak"
    fi
    if grep -qF "$MARKER_BEGIN" "$UWSM_DEFAULT"; then
      strip_markers "$UWSM_DEFAULT"
      log "Refreshing PATH hook in $UWSM_DEFAULT"
    else
      log "Adding PATH hook to $UWSM_DEFAULT"
      printf '\n' >>"$UWSM_DEFAULT"
    fi
    path_snippet >>"$UWSM_DEFAULT"
  else
    path_snippet >"$UWSM_DEFAULT"
    : >"$STATE_DIR/uwsm-default.created"
    log "Created $UWSM_DEFAULT with PATH hook"
  fi

  # Also drop env.d file (Omarchy FAQ recommends ~/.config/uwsm/env.d/).
  {
    echo "# Managed by omarchy-ascii-screensaver — remove via uninstall.sh"
    path_snippet
  } >"$UWSM_ENV_D"
  log "env.d: $UWSM_ENV_D"

  printf '%s\n' "$DEST" >"$STATE_DIR/install-root"
  date -Iseconds >"$STATE_DIR/installed-at"
}

optional_usr_local() {
  # Optional: /usr/local/bin usually precedes /usr/bin, so this works even if
  # the session PATH hook hasn't been picked up yet.
  [[ ${ASCII_SCREENSAVER_SYSTEM_WRAPPER:-0} == 1 ]] || return 0
  local wrapper=/usr/local/bin/omarchy-screensaver
  local body
  body=$(cat <<WRAP
#!/usr/bin/env bash
exec "$PATH_BIN/omarchy-screensaver" "\$@"
WRAP
)
  if [[ -w /usr/local/bin ]]; then
    printf '%s\n' "$body" >"$wrapper"
    chmod +x "$wrapper"
  else
    printf '%s\n' "$body" | sudo tee "$wrapper" >/dev/null
    sudo chmod +x "$wrapper"
  fi
  echo "$wrapper" >"$STATE_DIR/system-wrapper"
  log "System wrapper: $wrapper"
}

smoke_test() {
  log "Smoke test…"
  "$DEST/bin/ascii-screensaver" --list >/dev/null
  local first
  first=$("$DEST/bin/ascii-screensaver" --list | head -1)
  if command -v script >/dev/null 2>&1; then
    if script -qfc "node '$DEST/lib/play-scenes.mjs' --preview '$first' --seconds 1" /dev/null >/dev/null 2>&1; then
      log "OK: pty preview $first"
    else
      log "(warning) pty preview failed here — should work in a real terminal"
    fi
  fi
  log "OK: scene list and node import work"
}

main() {
  echo "=== omarchy-ascii-screensaver install ==="
  ensure_node
  install_files
  hook_uwsm
  optional_usr_local
  smoke_test
  cat <<MSG

Done.

For the idle screensaver to pick up the PATH hook, log out of Omarchy and back in
(or restart Hyprland from the menu).

Try it without restarting:

  PATH="$PATH_BIN:\$PATH" omarchy-launch-screensaver force
  # or:
  ascii-screensaver --launch

Preview in the current terminal:

  ascii-screensaver --preview night-coast
  ascii-screensaver --list

Config:  $CFG_DIR/config
Remove:  $DEST/uninstall.sh

Prefer the Omarchy Quattro plugin install instead? See README.md
("omarchy plugin add …").

MSG
}

main "$@"
