// Copilot stub for upstream `hooks/lib/prd-template.ts`.
// Emits PRDFORMAT v2.0 frontmatter + canonical section skeleton. Matches
// `bun ~/.pai/PAI/Tools/algorithm.ts new` output so `algorithm.ts` produces identical PRDs.

export interface PRDInput {
  title: string;
  slug: string;
  effortLevel?: string | number;
  mode?: string;
  started?: string;
  iteration?: number;
}

function nowUTC(): string {
  return new Date().toISOString().replace(/\.\d{3}Z$/, "Z");
}

export function generatePRDTemplate(input: PRDInput): string {
  const started = input.started || nowUTC();
  const effort = String(input.effortLevel ?? "medium");
  const mode = input.mode || "interactive";
  const iteration = input.iteration ? `iteration: ${input.iteration}\n` : "";
  return `---
task: ${input.title}
slug: ${input.slug}
effort: ${effort}
phase: observe
progress: 0/1
mode: ${mode}
started: ${started}
updated: ${started}
${iteration}---

# ${input.title}

## Problem

_What are we solving? Why now?_

## Ideal State Criteria (ISC)

- [ ] Criterion 1

## Approach

## Notes
`;
}
