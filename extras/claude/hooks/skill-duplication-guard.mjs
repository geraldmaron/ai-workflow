#!/usr/bin/env node
// PostToolUse(Write|Edit|MultiEdit): catch a skill being authored that already
// exists somewhere else on this machine.
//
// The global instruction file already says to search for an existing
// implementation before creating a new one. That rule is context, not
// enforcement, and it is scoped to "the project", so it does not fire when the
// existing implementation lives in a different repo or is installed in a host's
// skills directory. This check does, deterministically, at the moment the file
// is written rather than at deploy time.
import { readFileSync, existsSync } from 'node:fs';
import { join, basename, dirname } from 'node:path';
import { homedir } from 'node:os';
import { readStdin, targetFile, flag, ok } from './hook-lib.mjs';

const input = await readStdin();
const file = targetFile(input);
if (!/\/skills\/[^/]+\/SKILL\.md$/.test(file)) ok();

const name = basename(dirname(file));
const hits = [];

// Already installed under this name in a host's skills directory.
const roots = ['.claude/skills', '.agents/skills', '.gemini/skills', '.cursor/skills', '.copilot/skills', '.bob/skills'];
for (const root of roots) {
  const dir = join(homedir(), root, name);
  // A directory this repo deployed is our own copy, not a competing one.
  if (existsSync(join(dir, 'SKILL.md')) && !managedHere(dir)) {
    hits.push(`already installed by another source at ~/${root}/${name}`);
  }
}

if (hits.length) {
  flag(
    `SKILL DUPLICATION: '${name}' already exists elsewhere.\n` +
      hits.map((h) => `  - ${h}`).join('\n') +
      '\n\nRead the existing one before continuing. Extend or defer to it rather than ' +
      'maintaining a second version. Same-name precedence depends on the host. ' +
      'If this really is a distinct concept, rename it so the trigger does not overlap.',
  );
}
ok();

function managedHere(dir) {
  try {
    // Pre-rename installs say ai-workflow-config; deploy rewrites them.
    return /^deployed by ai-workflow(-config)?; removed by scripts\/deploy when the repo drops it, or by scripts\/uninstall$/.test(
      readFileSync(join(dir, '.managed-by'), 'utf8').trim(),
    );
  } catch {
    return false;
  }
}
