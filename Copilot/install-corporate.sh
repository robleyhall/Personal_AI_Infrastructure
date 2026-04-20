#!/usr/bin/env bash
# install-corporate.sh — Corporate-friendly installer for PAI (Copilot edition)
#
# Derivative of Copilot/install.sh. Tier 3 bundle only:
#   - Reads Copilot/CorporateBundle/INCLUDES.txt as the authoritative allowlist
#   - Never installs voice server, TypeScript skill tools, or excluded skills
#   - Applies the 3 path-fix seds from GAPS.md during install
#   - Honors PAI_USER_DIR for relocating USER/ out of $HOME if corp policy requires
#   - Installs sidecar/pai-copilot-corp (not the full pai-copilot)
#   - Does NOT add PAI_VOICE_URL export
#   - Preflight summary + confirmation prompt (unless --yes / --dry-run)
#
# Flags:
#   --dry-run    Print what would happen; make no changes
#   --yes        Skip confirmation prompt
#   --force      Overwrite existing ~/.pai/ without prompting (destructive)
#
# Idempotent: safe to re-run unless --force is passed.

set -euo pipefail

PAI_DIR="${PAI_DIR:-$HOME/.pai}"
PAI_USER_DIR_OVERRIDE="${PAI_USER_DIR:-}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$REPO_ROOT/Copilot"
BUNDLE_DIR="$SRC/CorporateBundle"
INCLUDES_FILE="$BUNDLE_DIR/INCLUDES.txt"
FABRIC_PATTERNS_FILE="$BUNDLE_DIR/FABRIC_PATTERNS.txt"
SHELL_RC=""
DRY_RUN=0
ASSUME_YES=0
FORCE=0
SKIP_SHELL_RC=0

say()  { printf '\033[36m[pai-install-corp]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[pai-install-corp]\033[0m %s\n' "$*" >&2; }
die()  { printf '\033[31m[pai-install-corp]\033[0m %s\n' "$*" >&2; exit 1; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '  (dry-run) %s\n' "$*"
  else
    eval "$@"
  fi
}

parse_args() {
  while (( $# > 0 )); do
    case "$1" in
      --dry-run) DRY_RUN=1 ;;
      --yes|-y)  ASSUME_YES=1 ;;
      --force)   FORCE=1 ;;
      --no-shell-rc) SKIP_SHELL_RC=1 ;;
      -h|--help)
        sed -n '2,25p' "$0" | sed 's/^# \{0,1\}//'
        exit 0
        ;;
      *) die "unknown arg: $1" ;;
    esac
    shift
  done
}

require() {
  command -v "$1" >/dev/null 2>&1 || die "missing dependency: $1"
}

check_deps() {
  say "checking dependencies…"
  require bash
  require rsync
  require python3
  require grep
  require sed
  require find
  command -v copilot >/dev/null 2>&1 || warn "copilot CLI not found — install before running \`pai\`"
  say "dependency check OK"
}

detect_shell_rc() {
  case "${SHELL##*/}" in
    zsh)  SHELL_RC="$HOME/.zshrc" ;;
    bash) SHELL_RC="$HOME/.bashrc" ;;
    *)    SHELL_RC="" ;;
  esac
}

resolve_user_dir() {
  if [[ -n "$PAI_USER_DIR_OVERRIDE" ]]; then
    echo "$PAI_USER_DIR_OVERRIDE"
  else
    echo "$PAI_DIR/USER"
  fi
}

print_preflight() {
  local user_dir
  user_dir="$(resolve_user_dir)"

  cat <<EOF

╔══════════════════════════════════════════════════════════════════╗
║  PAI — Corporate Bundle Installer (Tier 3)                       ║
╚══════════════════════════════════════════════════════════════════╝

  Source:       $SRC
  Allowlist:    $INCLUDES_FILE
  Destination:  $PAI_DIR
  USER dir:     $user_dir
  Shell rc:     ${SHELL_RC:-<unknown; manual setup needed>}

  Will install:
    • Instruction block for ~/.copilot/copilot-instructions.md
      (printed as a diff at end — user applies manually)
    • ~/.pai/sidecar/pai-copilot-corp (slim sidecar, no voice, no tab title)
    • ~/.pai/tools/ — 5 bash scripts (capture-rating, capture-work-learning,
      harvest-session, learning-readback, save-research-memory)
    • ~/.pai/skills/ — 8 green + 4 yellow skills (see INCLUDES.txt)
    • ~/.pai/USER/ — empty scaffolds (user populates)
    • ~/.pai/MEMORY/ — empty directory tree

  Will NOT install:
    • Voice server
    • TypeScript skill tools (Tier 4)
    • Excluded skills (see CorporateBundle/EXCLUDES.txt)
    • Aphorisms copyrighted quote DB
    • PAI_VOICE_URL env var

  Mode: $( [[ $DRY_RUN -eq 1 ]] && echo "DRY-RUN (no changes)" || echo "LIVE" )

EOF
}

confirm_or_exit() {
  [[ $ASSUME_YES -eq 1 ]] && return 0
  [[ $DRY_RUN    -eq 1 ]] && return 0
  read -r -p "Proceed with install? [y/N] " reply
  case "$reply" in
    y|Y|yes|YES) ;;
    *) die "aborted by user" ;;
  esac
}

check_collision() {
  if [[ -d "$PAI_DIR" ]]; then
    if [[ $FORCE -eq 1 ]]; then
      warn "existing $PAI_DIR will be overwritten (--force)"
    else
      warn "existing $PAI_DIR detected — will merge additively (no deletions)."
      warn "use --force to start fresh; not recommended unless you know what you're doing."
    fi
  fi
}

install_tree_skeleton() {
  say "creating directory skeleton at $PAI_DIR"
  local user_dir
  user_dir="$(resolve_user_dir)"

  run mkdir -p "'$PAI_DIR'/"{tools,sidecar,skills,state,logs}
  run mkdir -p "'$PAI_DIR'/"MEMORY/LEARNING/{SIGNALS,FAILURES,ALGORITHM,SYSTEM}
  run mkdir -p "'$PAI_DIR'/"MEMORY/{WORK,RESEARCH,RELATIONSHIP,WISDOM/FRAMES}
  run mkdir -p "'$user_dir'"{,/SKILLCUSTOMIZATIONS,/TELOS}
}

# Reads INCLUDES.txt and returns one relative path per line (ignoring comments).
iter_includes() {
  grep -Ev '^\s*(#|$)' "$INCLUDES_FILE" || true
}

install_tools() {
  say "installing bash tools…"
  while IFS= read -r entry; do
    [[ "$entry" == tools/* ]] || continue
    local rel="${entry#tools/}"
    local src="$SRC/tools/$rel"
    local dst="$PAI_DIR/tools/$rel"
    if [[ -f "$src" ]]; then
      run install -m 0755 "'$src'" "'$dst'"
    else
      warn "missing tool: $src"
    fi
  done < <(iter_includes)
}

install_sidecar() {
  say "installing slim sidecar…"
  run install -m 0755 "'$SRC/sidecar/pai-copilot-corp'" "'$PAI_DIR/sidecar/pai-copilot-corp'"
}

install_green_yellow_skills() {
  say "installing allowlisted skills…"

  # Green + yellow skills (except Fabric patterns, handled separately)
  local entries=(
    "FirstPrinciples"
    "Thinking"
    "ContentAnalysis"
    "Documents/Pdf"
    "Research"
    "CreateSkill"
  )

  for rel in "${entries[@]}"; do
    local src="$SRC/skills/$rel"
    local dst="$PAI_DIR/skills/$rel"
    if [[ -d "$src" ]]; then
      run mkdir -p "'$(dirname "$dst")'"
      # rsync excluding .ts files keeps skill workflows but drops any compiled/source tools
      run rsync -a --exclude='*.ts' --exclude='node_modules' --exclude='.turbo' "'$src/'" "'$dst/'"
    else
      warn "missing skill source: $src"
    fi
  done

  # Prompting — markdown + templates only; Tools/ is TS (deferred to Tier 4)
  if [[ -d "$SRC/skills/Prompting" ]]; then
    run mkdir -p "'$PAI_DIR/skills/Prompting'"
    run install -m 0644 "'$SRC/skills/Prompting/SKILL.md'"     "'$PAI_DIR/skills/Prompting/SKILL.md'"
    run install -m 0644 "'$SRC/skills/Prompting/Standards.md'" "'$PAI_DIR/skills/Prompting/Standards.md'"
    run rsync -a --exclude='*.ts' --exclude='node_modules' "'$SRC/skills/Prompting/Templates/'" "'$PAI_DIR/skills/Prompting/Templates/'"
  fi

  # Fabric — only the curated pattern subset
  install_fabric_subset

  # Telos — CSA-framed templates from CorporateBundle, not upstream Telos
  install_telos_csa

  # Porting notes for the installed subset
  if [[ -f "$SRC/skills/PORTING_NOTES.md" ]]; then
    run install -m 0644 "'$SRC/skills/PORTING_NOTES.md'" "'$PAI_DIR/skills/PORTING_NOTES.md'"
  fi
}

install_fabric_subset() {
  say "installing Fabric subset (per FABRIC_PATTERNS.txt)…"
  local fabric_src="$SRC/skills/Fabric"
  local fabric_dst="$PAI_DIR/skills/Fabric"

  run mkdir -p "'$fabric_dst/Patterns'" "'$fabric_dst/Workflows'"
  run install -m 0644 "'$fabric_src/SKILL.md'" "'$fabric_dst/SKILL.md'"
  run rsync -a "'$fabric_src/Workflows/'" "'$fabric_dst/Workflows/'"

  local count=0
  while IFS= read -r pattern; do
    pattern="${pattern%%#*}"
    pattern="${pattern// /}"
    [[ -z "$pattern" ]] && continue
    local psrc="$fabric_src/Patterns/$pattern"
    local pdst="$fabric_dst/Patterns/$pattern"
    if [[ -d "$psrc" ]]; then
      run rsync -a "'$psrc/'" "'$pdst/'"
      count=$((count+1))
    else
      warn "fabric pattern not found: $pattern"
    fi
  done < "$FABRIC_PATTERNS_FILE"
  say "fabric patterns installed: $count"
}

install_telos_csa() {
  say "installing CSA-framed Telos…"
  local telos_src="$BUNDLE_DIR/skills/Telos"
  local telos_dst="$PAI_DIR/skills/Telos"
  if [[ -d "$telos_src" ]]; then
    run mkdir -p "'$telos_dst'"
    run rsync -a "'$telos_src/'" "'$telos_dst/'"
  else
    warn "CSA Telos templates not found at $telos_src — skill will be installed empty"
  fi
}

install_attribution() {
  run install -m 0644 "'$BUNDLE_DIR/ATTRIBUTION.md'" "'$PAI_DIR/ATTRIBUTION.md'"
  if [[ -f "$REPO_ROOT/LICENSE" ]]; then
    run install -m 0644 "'$REPO_ROOT/LICENSE'" "'$PAI_DIR/LICENSE'"
  fi
}

apply_path_fixes() {
  say "applying GAPS.md path fixes to installed skills…"
  # See ~/.pai/MEMORY/WORK/.../GAPS.md from the live-test session.
  # Three systemic seds: PAI/USER, Utilities/, aphorisms casing.
  if [[ $DRY_RUN -eq 1 ]]; then
    printf '  (dry-run) would run 3 seds across %s/skills/\n' "$PAI_DIR"
    return 0
  fi

  find "$PAI_DIR/skills" -type f \( -name '*.md' -o -name '*.txt' \) -print0 \
    | xargs -0 sed -i '' \
        -e 's|pai/PAI/USER|pai/USER|g' \
        -e 's|skills/Utilities/|skills/|g' \
        -e 's|skills/aphorisms/|skills/Aphorisms/|g' 2>/dev/null || true

  say "path fixes applied"
}

setup_shell_rc() {
  if [[ $SKIP_SHELL_RC -eq 1 ]]; then
    say "skipping shell-rc update (--no-shell-rc)"
    return
  fi
  detect_shell_rc
  local wrapper="$PAI_DIR/sidecar/pai-copilot-corp"
  local pai_dir_line="export PAI_DIR=\"\$HOME/.pai\""
  local user_dir_line=""
  if [[ -n "$PAI_USER_DIR_OVERRIDE" ]]; then
    user_dir_line="export PAI_USER_DIR=\"$PAI_USER_DIR_OVERRIDE\""
  fi
  local alias_line="alias pai='$wrapper'"

  if [[ -z "$SHELL_RC" ]]; then
    warn "unknown shell ($SHELL); add these manually to your shell rc:"
    printf '  %s\n' "$pai_dir_line"
    [[ -n "$user_dir_line" ]] && printf '  %s\n' "$user_dir_line"
    printf '  %s\n' "$alias_line"
    return
  fi

  if [[ $DRY_RUN -eq 1 ]]; then
    printf '  (dry-run) would append to %s:\n' "$SHELL_RC"
    printf '  %s\n' "$pai_dir_line"
    [[ -n "$user_dir_line" ]] && printf '  %s\n' "$user_dir_line"
    printf '  %s\n' "$alias_line"
    return
  fi

  local block_start="# BEGIN PAI (Copilot corporate edition)"
  local block_end="# END PAI (Copilot corporate edition)"
  if grep -Fq "$block_start" "$SHELL_RC" 2>/dev/null; then
    say "$SHELL_RC already contains PAI block; leaving unchanged"
    return
  fi

  {
    printf '\n%s\n' "$block_start"
    printf '%s\n' "$pai_dir_line"
    [[ -n "$user_dir_line" ]] && printf '%s\n' "$user_dir_line"
    printf '%s\n' "$alias_line"
    printf '%s\n' "$block_end"
  } >>"$SHELL_RC"
  say "added PAI block to $SHELL_RC — reload with: source $SHELL_RC"
}

print_instruction_diff() {
  local instr_src="$BUNDLE_DIR/copilot-instructions.corporate.md"
  if [[ ! -f "$instr_src" ]]; then
    warn "corporate instruction bundle not found at $instr_src — skipping diff hint"
    return
  fi
  say ""
  say "next step — merge the PAI instruction block into your Copilot instructions:"
  say "  1. Open: ~/.copilot/copilot-instructions.md"
  say "  2. Paste the contents of: $instr_src"
  say "     between these markers (add them if missing):"
  say "       [BEGIN PAI BLOCK]"
  say "       ... paste here ..."
  say "       [END PAI BLOCK]"
  say "  3. Reload your shell: source $SHELL_RC"
  say "  4. Test: pai --help"
}

main() {
  parse_args "$@"
  [[ -f "$INCLUDES_FILE" ]] || die "missing allowlist: $INCLUDES_FILE"

  check_deps
  detect_shell_rc
  check_collision
  print_preflight
  confirm_or_exit

  install_tree_skeleton
  install_tools
  install_sidecar
  install_green_yellow_skills
  install_attribution
  apply_path_fixes
  setup_shell_rc

  if [[ $DRY_RUN -eq 1 ]]; then
    say "DRY-RUN complete. No changes made."
  else
    say "install complete."
  fi
  print_instruction_diff
}

main "$@"
