// Copilot stub for upstream `hooks/lib/learning-utils.ts`.
// Heuristic classifier — matches upstream behaviour closely enough that the
// few tools that call it (SessionHarvester, ActivityParser) produce sensible
// categories. Keep this in sync with ~/.pai/MEMORY/LEARNING/ directory layout.

const ALGORITHM_KEYWORDS = [
  "algorithm", "phase", "isc", "ideal state", "observe", "think", "plan",
  "build", "execute", "verify", "learn", "prd", "workflow", "skill",
];

const SYSTEM_KEYWORDS = [
  "hook", "sidecar", "tool", "install", "config", "permission", "shell",
  "bun", "node", "script", "cron", "daemon", "socket", "pipeline", "action",
  "infrastructure", "secret", "credential",
];

const CAPTURE_TRIGGERS = [
  "learned", "lesson", "mistake", "bug", "gotcha", "workaround", "discovered",
  "realized", "turned out", "root cause", "takeaway",
];

export function getLearningCategory(text: string): "ALGORITHM" | "SYSTEM" {
  const t = (text || "").toLowerCase();
  let sys = 0, alg = 0;
  for (const k of SYSTEM_KEYWORDS) if (t.includes(k)) sys++;
  for (const k of ALGORITHM_KEYWORDS) if (t.includes(k)) alg++;
  return sys > alg ? "SYSTEM" : "ALGORITHM";
}

export function isLearningCapture(text: string): boolean {
  const t = (text || "").toLowerCase();
  return CAPTURE_TRIGGERS.some((k) => t.includes(k));
}
