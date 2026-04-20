#!/usr/bin/env bun
/**
 * PAI Voice Server (spike edition)
 *
 * Minimal drop-in replacement for the ElevenLabs-based PAI voice server.
 * Uses macOS `say` for local, offline, zero-cost TTS.
 *
 * Endpoints:
 *   POST /notify              { message, voice?, rate? }
 *   POST /notify/personality  (compat shim — same behaviour)
 *   GET  /health
 *
 * No API key required. No network calls. Runs on localhost:8888.
 */

import { serve } from "bun";
import { spawn } from "child_process";

const PORT = parseInt(process.env.PORT || "8888");
const DEFAULT_VOICE = process.env.PAI_VOICE || "Samantha";
const DEFAULT_RATE = parseInt(process.env.PAI_RATE || "190");

interface NotifyBody {
  message?: string;
  voice?: string;
  rate?: number;
}

function stripEmoji(text: string): string {
  return text.replace(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{1F000}-\u{1F2FF}]/gu, "").trim();
}

function speak(message: string, voice: string, rate: number): Promise<number> {
  return new Promise((resolve) => {
    const proc = spawn("/usr/bin/say", ["-v", voice, "-r", String(rate), message], {
      stdio: "ignore",
    });
    proc.on("exit", (code) => resolve(code ?? 0));
    proc.on("error", () => resolve(1));
  });
}

async function handleNotify(req: Request): Promise<Response> {
  let body: NotifyBody;
  try {
    body = (await req.json()) as NotifyBody;
  } catch {
    return Response.json({ error: "invalid json" }, { status: 400 });
  }

  const raw = (body.message ?? "").toString();
  const message = stripEmoji(raw);
  if (!message) {
    return Response.json({ error: "message required" }, { status: 400 });
  }
  if (message.length > 2000) {
    return Response.json({ error: "message too long (max 2000)" }, { status: 400 });
  }

  const voice = body.voice || DEFAULT_VOICE;
  const rate = Math.max(100, Math.min(400, body.rate || DEFAULT_RATE));

  // Fire and forget — don't block the caller on audio playback.
  speak(message, voice, rate).catch(() => {});

  return Response.json({ ok: true, spoken: message.slice(0, 120) });
}

const server = serve({
  port: PORT,
  async fetch(req) {
    const url = new URL(req.url);

    if (req.method === "GET" && url.pathname === "/health") {
      return Response.json({ ok: true, engine: "macos-say", voice: DEFAULT_VOICE });
    }

    if (
      req.method === "POST" &&
      (url.pathname === "/notify" || url.pathname === "/notify/personality" || url.pathname === "/pai")
    ) {
      return handleNotify(req);
    }

    return new Response("PAI Voice Server (say) — POST /notify { message }", { status: 404 });
  },
});

console.log(`🔊 PAI Voice Server (say) listening on http://localhost:${server.port}`);
console.log(`   Voice: ${DEFAULT_VOICE}   Rate: ${DEFAULT_RATE}`);
console.log(`   Try: curl -X POST http://localhost:${PORT}/notify -H 'content-type: application/json' -d '{"message":"Hello from PAI"}'`);
