// Copilot stub for upstream `hooks/lib/identity.ts` (not shipped in v4.0.3 release tree).
// Reads ~/.pai/USER/DAIDENTITY.md + ABOUTME.md if present. Safe fallbacks.
import { readFileSync, existsSync } from "fs";
import { homedir } from "os";
import { join } from "path";

export interface Identity {
  daName: string;
  userName: string;
  daIdentityPath: string;
  aboutMePath: string;
}

function readFirst(p: string): string {
  try { return existsSync(p) ? readFileSync(p, "utf-8") : ""; } catch { return ""; }
}

function extractName(text: string, fallback: string): string {
  const m = text.match(/(?:Name|DA|Digital Assistant)\s*[:=]\s*([A-Za-z][A-Za-z0-9 _-]{0,40})/i);
  return m ? m[1].trim() : fallback;
}

export function getIdentity(): Identity {
  const base = join(homedir(), ".pai", "USER");
  const daPath = join(base, "DAIDENTITY.md");
  const aboutPath = join(base, "ABOUTME.md");
  const daText = readFirst(daPath);
  const aboutText = readFirst(aboutPath);
  return {
    daName: extractName(daText, "Assistant"),
    userName: extractName(aboutText, process.env.USER || "user"),
    daIdentityPath: daPath,
    aboutMePath: aboutPath,
  };
}

export function getDAName(): string {
  return getIdentity().daName;
}
