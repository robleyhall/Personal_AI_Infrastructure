# ATTRIBUTION — Corporate Bundle

This corporate bundle is a derivative work of the following MIT-licensed projects.
Original copyright notices are preserved. See the source repositories for the full
license text.

## Upstream: Personal AI Infrastructure (PAI)

- Project: Personal AI Infrastructure
- Author: Daniel Miessler
- Repository: https://github.com/danielmiessler/Personal_AI_Infrastructure
- License: MIT (see `LICENSE` at the repo root)
- Copyright: © 2025 Daniel Miessler

**What we use:**
- Overall architecture (ambient assistant, memory loop, skills, context routing, Algorithm framework)
- Instruction-file design (USER + MEMORY + startup loading)
- Skill-pack concept and SKILL.md / workflow structure
- Mode system (MINIMAL / NATIVE / ALGORITHM)
- Learning-capture idea and ratings-driven improvement loop

**Modifications in the corporate bundle:**
- Translated from Claude Code to GitHub Copilot CLI (tool naming, instruction format, hook replacement)
- Trimmed skill inventory (8 green + 4 yellow skills; see `INCLUDES.txt` / `EXCLUDES.txt`)
- Removed: voice server, TypeScript skill tools (deferred), Aphorisms DB (IP), Security/Investigation/Parser skills, PAIUpgrade, Evals, Delegation, CreateCLI, USMetrics
- Added: `pai-copilot-corp` slim sidecar, CSA-framed Telos templates, Research domain allowlist, corporate security guardrails, `PAI_USER_DIR` relocation option
- Separate `install-corporate.sh` that honors `INCLUDES.txt`

## Upstream: Fabric

- Project: Fabric
- Author: Daniel Miessler
- Repository: https://github.com/danielmiessler/fabric
- License: MIT
- Copyright: © 2024 Daniel Miessler

**What we use:**
- A curated subset of ~30 generic Fabric prompt patterns (see `FABRIC_PATTERNS.txt` for the list)
- The ExecutePattern workflow (native-execution model, no Fabric CLI required)

**Modifications in the corporate bundle:**
- Excluded 200+ patterns that are either narrowly scoped or brand-specific
- No bundled Fabric CLI (not needed; patterns are read directly as prompt instructions)

## Third-party runtime dependencies (OS-provided)

The corporate bundle relies only on tools that ship with macOS or are
included in a default developer install:

- `bash` (macOS system bash)
- `python3` (macOS system python)
- `rsync` (macOS system rsync)
- `curl` (macOS system curl; used only for voice server in the full bundle, which is excluded here)
- `date`, `grep`, `sed`, `find`, `wc`, `head`, `tail` (POSIX utilities)

No npm, pip, bun, brew, or other package-manager installs are performed during Tier 3 installation.

## Corporate bundle additions (new work)

- `Copilot/CorporateBundle/` scaffolding (README, INCLUDES, EXCLUDES, ATTRIBUTION, SECURITY_REVIEW)
- `Copilot/sidecar/pai-copilot-corp` slim sidecar
- `Copilot/install-corporate.sh` allowlist-honoring installer
- CSA-role-framed Telos templates (no customer or internal-confidential content)
- Research domain allowlist mechanism
- Corporate extensions to §12 Security guardrails

These additions are MIT-licensed consistent with upstream.

## Full license text

See `LICENSE` at the repo root for the upstream PAI MIT license. The same terms apply to this corporate bundle.
