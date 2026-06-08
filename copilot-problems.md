# Copilot CLI Problems: GitHub Tabs and Scrolling

## Current issue

Recent Copilot CLI sessions started showing a pinned top tab bar:

```text
Session | Issues | Pull requests | Gists
```

This is not helpful for my workflow and appears to reduce usable vertical space in the terminal UI. It may be contributing to, or at least worsening, the problem where long Copilot responses scroll out of reach inside the alternate-screen interface.

## Findings

- The tabs are controlled by an internal Copilot CLI feature flag named `COPILOT_GITHUB_TABS`.
- The installed CLI renders those tabs as a pinned header with `Session`, `Issues`, `Pull requests`, and `Gists`.
- The feature is staff-gated internally, not exposed as a normal documented preference in `copilot help config`.
- Public CLI help documents `/copy`, `/share`, `/exit print`, `/search`, and timeline expansion shortcuts, but does not document a supported setting to remove these GitHub tabs.
- Local testing of the installed feature-flag resolver showed:
  - Normal mode: `COPILOT_GITHUB_TABS` resolves false.
  - Staff-enabled mode: `COPILOT_GITHUB_TABS` resolves true.
  - Environment override `COPILOT_GITHUB_TABS=false` resolves false.
  - `COPILOT_GITHUB_TABS=0` and `COPILOT_GITHUB_TABS=off` do not disable it.
  - Config-style overrides did not disable it in the same way the environment variable did.

## Verified workaround

This suppresses the tabs:

```bash
COPILOT_GITHUB_TABS=false copilot
```

To persist for zsh:

```bash
echo 'export COPILOT_GITHUB_TABS=false' >> ~/.zshrc
exec zsh
```

Verified in a new session: setting `COPILOT_GITHUB_TABS=false` suppresses the tabs.

## Open question

Need to restart the active Copilot session with `COPILOT_GITHUB_TABS=false` to determine whether removing the pinned tabs also improves or fixes the scrolling problem. The deeper scrolling issue may still be caused by Copilot CLI alternate-screen/timeline behavior rather than the tabs alone.
