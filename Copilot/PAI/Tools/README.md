# PAI Tools

Upstream PAI v4.0.3 `PAI/Tools/*.ts` bun utilities, ported verbatim with
`.claude` → `.pai` path rewrites. Shebang lines preserved; run with `bun`.

## Install deps once

```bash
cd ~/.pai/PAI/Tools && bun install
cd ~/.pai/PAI/ACTIONS && bun install
```

Dependencies: `openai`, `yaml`, `ajv`, `ajv-formats`, `glob`, `zod`.

## Local stubs

Five tools (`algorithm.ts`, `pai.ts`, `IntegrityMaintenance.ts`,
`SessionHarvester.ts`, `TranscriptParser.ts`) import from
`../../hooks/lib/*`. Upstream release tree does **not** ship those libs,
so Copilot provides minimal stubs under `Copilot/hooks/lib/`
(`identity.ts`, `learning-utils.ts`, `prd-template.ts`).

## Skipped

`BuildCLAUDE.ts` and `RebuildPAI.ts` are installer-side for Claude Code
and do not apply to the Copilot environment.
