#!/usr/bin/env bash
# PAI (Copilot edition) — installer for the Phase 0 spike.
#
# Copies Copilot/ into $PAI_DIR (default: ~/.pai/), sets up a `pai` shell
# alias that invokes the sidecar wrapper, and verifies dependencies.
#
# Idempotent: safe to re-run.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/Copilot"
SHELL_RC=""

say() { printf '\033[36m[pai-install]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[pai-install]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m[pai-install]\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

detect_shell_rc() {
  case "${SHELL##*/}" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
    *)    SHELL_RC="" ;;
  esac
}

check_deps() {
  say "checking dependencies…"
  require bash
  require curl
  require git
  command -v bun     >/dev/null 2>&1 || warn "bun not found — voice server will not start"
  command -v copilot >/dev/null 2>&1 || warn "copilot CLI not found — install from https://docs.github.com/copilot"
  command -v say     >/dev/null 2>&1 || warn "macOS \`say\` not found — voice output will fail silently"
}

install_tree() {
  say "installing to $PAI_DIR"
  mkdir -p "$PAI_DIR"/{skills,tools,VoiceServer,sidecar,MEMORY/LEARNING/SIGNALS,MEMORY/LEARNING/FAILURES,MEMORY/RESEARCH,MEMORY/WORK,USER,state,logs}

  rsync -a --delete "$SRC/VoiceServer/" "$PAI_DIR/VoiceServer/"
  rsync -a --delete "$SRC/sidecar/"     "$PAI_DIR/sidecar/"
  rsync -a --delete "$SRC/tools/"       "$PAI_DIR/tools/"
  rsync -a           "$SRC/skills/"      "$PAI_DIR/skills/"

  chmod +x \
    "$PAI_DIR/VoiceServer/start.sh" \
    "$PAI_DIR/sidecar/pai-copilot" \
    "$PAI_DIR/tools/save-research-memory.sh"
}

install_alias() {
  detect_shell_rc
  local wrapper="$PAI_DIR/sidecar/pai-copilot"
  local line="alias pai='$wrapper'"

  if [[ -z "$SHELL_RC" ]]; then
    warn "unknown shell ($SHELL) — add this line manually: $line"
    return
  fi

  if grep -Fq "$line" "$SHELL_RC" 2>/dev/null; then
    say "alias already present in $SHELL_RC"
    return
  fi

  printf '\n# PAI (Copilot edition)\n%s\n' "$line" >>"$SHELL_RC"
  say "added alias to $SHELL_RC — run: source $SHELL_RC"
}

main() {
  check_deps
  install_tree
  install_alias
  say "done. Launch with: pai"
  say "(or, first time: source $SHELL_RC && pai)"
}

main "$@"
