#!/usr/bin/env node
// UserPromptSubmit hook: warns when the current session's transcript has grown
// past size thresholds (a cheap proxy for context bloat / cache-read cost).
// Emits a systemMessage for the user and additionalContext for Claude so both
// naturally converge on splitting the session instead of running a marathon.
import { statSync } from 'node:fs';
import { readStdin } from './hook-lib.mjs';

const input = await readStdin();
let out = {};
try {
  const path = input.transcript_path;
  if (path) {
    const mb = statSync(path).size / (1024 * 1024);
    // Thresholds chosen from observed whale sessions: transcripts past ~10MB
    // correlate with sessions that ended up costing $100+.
    if (mb > 25) {
      out = {
        systemMessage: `⚠️ Session transcript is ${mb.toFixed(0)}MB; this is whale-session territory. Strongly consider /clear or a fresh session; each turn now re-bills a huge cached context.`,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext:
            'This session is very long and expensive (large cached context re-billed every turn). Finish the current task efficiently, avoid spawning subagents or workflows unless explicitly asked, and when the task completes, suggest the user start a fresh session or /clear.',
        },
      };
    } else if (mb > 10) {
      out = {
        systemMessage: `💸 Session transcript is ${mb.toFixed(0)}MB. When this task wraps, /clear or a new session will cut per-turn cost significantly.`,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext:
            'This session is getting long. Prefer lean approaches (no unprompted multi-agent fan-outs) and suggest /clear at the next natural task boundary.',
        },
      };
    }
  }
} catch {
  // Never block the prompt on a guard failure.
}

process.stdout.write(JSON.stringify(out));
