#!/usr/bin/env bash
# Remove ascii.rest Omarchy screensaver and restore previous hooks.
set -euo pipefail

DEST="${XDG_DATA_HOME:-$HOME/.local/share}/omarchy-ascii-screensaver"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-ascii-screensaver"
CFG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy-ascii-screensaver"
MARKER_BEGIN="# BEGIN omarchy-ascii-screensaver"
MARKER_END="# END omarchy-ascii-screensaver"
UWSM_DEFAULT="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/default"
UWSM_ENV_D="${XDG_CONFIG_HOME:-$HOME/.config}/uwsm/env.d/50-ascii-screensaver"
LOCAL_BIN="${XDG_BIN_HOME:-$HOME/.local/bin}"

log() { printf '→ %s\n' "$*"; }

strip_markers() {
  local file=$1 out
  [[ -f $file ]] || return 0
  out="$(mktemp)"
  awk -v b="$MARKER_BEGIN" -v e="$MARKER_END" '
    $0 == b { skip = 1; next }
    $0 == e { skip = 0; next }
    !skip { print }
  ' "$file" >"$out"
  if [[ -s $out ]]; then
    printf '%s\n' "$(cat "$out")" >"$file"
  else
    : >"$file"
  fi
  rm -f "$out"
}

unhook_uwsm() {
  if [[ -f $STATE_DIR/uwsm-default.created ]]; then
    rm -f "$UWSM_DEFAULT" "$STATE_DIR/uwsm-default.created"
    log "Removed created $UWSM_DEFAULT"
  elif [[ -f $UWSM_DEFAULT ]] && grep -qF "$MARKER_BEGIN" "$UWSM_DEFAULT"; then
    strip_markers "$UWSM_DEFAULT"
    log "Removed marker block from $UWSM_DEFAULT"
  elif [[ -f $STATE_DIR/uwsm-default.bak ]]; then
    cp -a "$STATE_DIR/uwsm-default.bak" "$UWSM_DEFAULT"
    log "Restored $UWSM_DEFAULT from backup"
  fi
  rm -f "$UWSM_ENV_D"
  log "Removed $UWSM_ENV_D (if present)"
}

remove_wrapper() {
  if [[ -f $STATE_DIR/system-wrapper ]]; then
    local w
    w=$(cat "$STATE_DIR/system-wrapper")
    if [[ -n $w && -e $w ]]; then
      if [[ -w $(dirname "$w") ]]; then
        rm -f "$w"
      else
        sudo rm -f "$w" || true
      fi
      log "Removed $w"
    fi
    rm -f "$STATE_DIR/system-wrapper"
  fi
}

main() {
  echo "=== omarchy-ascii-screensaver uninstall ==="
  unhook_uwsm
  remove_wrapper
  if [[ -L $LOCAL_BIN/ascii-screensaver ]]; then
    rm -f "$LOCAL_BIN/ascii-screensaver"
    log "Removed symlink $LOCAL_BIN/ascii-screensaver"
  fi
  rm -rf "$DEST"
  log "Removed $DEST"
  # Keep user config unless they pass --purge
  if [[ ${1:-} == --purge ]]; then
    rm -rf "$CFG_DIR"
    log "Removed $CFG_DIR"
  else
    log "Config kept: $CFG_DIR (pass --purge to delete it)"
  fi
  rm -rf "$STATE_DIR"
  cat <<MSG

Done. Log out/in (or restart Hyprland) so PATH is restored.
The stock Omarchy screensaver is again /usr/bin/omarchy-screensaver.

If you installed via omarchy plugin add, also run:
  omarchy plugin remove io.github.artile.ascii-screensaver

MSG
}

main "$@"
