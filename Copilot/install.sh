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

append_shell_line() {
  local line="$1"
  grep -Fq "$line" "$SHELL_RC" 2>/dev/null || printf '%s\n' "$line" >>"$SHELL_RC"
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
  mkdir -p "$PAI_DIR"/{skills,tools,VoiceServer,sidecar,instructions/.github,Bin,MEMORY/LEARNING/SIGNALS,MEMORY/LEARNING/FAILURES,MEMORY/LEARNING/ALGORITHM,MEMORY/LEARNING/SYSTEM,MEMORY/RESEARCH,MEMORY/WORK,MEMORY/WISDOM/FRAMES,MEMORY/RELATIONSHIP,USER/SKILLCUSTOMIZATIONS,state,logs}

  rsync -a --delete "$SRC/VoiceServer/" "$PAI_DIR/VoiceServer/"
  rsync -a --delete "$SRC/sidecar/"     "$PAI_DIR/sidecar/"
  rsync -a --delete "$SRC/tools/"       "$PAI_DIR/tools/"
  rsync -a           "$SRC/skills/"      "$PAI_DIR/skills/"
  install -m 0644 "$SRC/README.md"           "$PAI_DIR/README.md"
  install -m 0644 "$SRC/Algorithm.md"        "$PAI_DIR/Algorithm.md"
  install -m 0644 "$SRC/ContextRouting.md"   "$PAI_DIR/ContextRouting.md"
  install -m 0644 "$REPO_ROOT/.github/copilot-instructions.md" "$PAI_DIR/instructions/AGENTS.md"
  install -m 0644 "$REPO_ROOT/.github/copilot-instructions.md" "$PAI_DIR/instructions/.github/copilot-instructions.md"

  chmod +x \
    "$PAI_DIR/VoiceServer/start.sh" \
    "$PAI_DIR/sidecar/pai-copilot" \
    "$PAI_DIR/tools/save-research-memory.sh" \
    "$PAI_DIR/tools/capture-rating.sh" \
    "$PAI_DIR/tools/capture-work-learning.sh" \
    "$PAI_DIR/tools/learning-readback.sh" \
    "$PAI_DIR/tools/harvest-session.sh"
}

install_alias() {
  detect_shell_rc
  local wrapper="$PAI_DIR/sidecar/pai-copilot"
  local line="alias pai='$wrapper'"

  if [[ -z "$SHELL_RC" ]]; then
    warn "unknown shell ($SHELL) — add this line manually: $line"
    return
  fi

  append_shell_line ""
  append_shell_line "# PAI (Copilot edition)"
  append_shell_line "export PAI_DIR=\"\$HOME/.pai\""
  append_shell_line "export PAI_VOICE_URL=\"http://localhost:8888\""
  append_shell_line "$line"
  say "ensured shell exports and alias in $SHELL_RC — run: source $SHELL_RC"
}

main() {
  check_deps
  install_tree
  install_alias
  say "done. Launch with: pai"
  say "(or, first time: source $SHELL_RC && pai)"
}

main "$@"
