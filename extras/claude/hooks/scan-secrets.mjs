#!/usr/bin/env node
// PostToolUse(Write|Edit|MultiEdit): catch a credential written to disk.
//
// The write has already happened, so this reports rather than blocks. The
// point is that the model notices immediately and removes it, instead of the
// key reaching a commit. Patterns are deliberately narrow: a guard that cries
// wolf gets ignored, and an ignored guard is the same as no guard.
import { readFileSync } from 'node:fs';
import { readStdin, targetFile, flag, ok } from './hook-lib.mjs';

const PATTERNS = [
  [/\bAKIA[0-9A-Z]{16}\b/, 'AWS access key id'],
  [/-----BEGIN (RSA |EC |OPENSSH |PGP )?PRIVATE KEY-----/, 'private key block'],
  [/\bsk-ant-[A-Za-z0-9_-]{20,}/, 'Anthropic API key'],
  [/\bsk-(?:proj-|svcacct-|admin-)?[A-Za-z0-9_-]{32,}/, 'OpenAI-style API key'],
  [/\bgh[pousr]_[A-Za-z0-9]{30,}\b/, 'GitHub token'],
  [/\bxox[abprs]-[A-Za-z0-9-]{10,}\b/, 'Slack token'],
  [/\bAIza[0-9A-Za-z_-]{35}\b/, 'Google API key'],
  [/\bglpat-[A-Za-z0-9_-]{20,}\b/, 'GitLab token'],
  [/\b[rs]k_(?:live|test)_[A-Za-z0-9]{20,}\b/, 'Stripe key'],
  [/\bsbp_[a-f0-9]{40}\b/, 'Supabase access token'],
  [/\b(?:secret|password|passwd|api[_-]?key|access[_-]?token)\s*[:=]\s*["'][^"'\s]{16,}["']/i, 'hardcoded credential'],
];

// Anything that is obviously a stand-in, a test fixture, or documentation.
const PLACEHOLDER = /example|placeholder|redacted|dummy|sample|your[_-]|xxx|<[^>]+>|\bfake\b|changeme|\.\.\./i;
const SKIP_PATH = /(^|\/)(\.env\.example|.*\.lock|package-lock\.json|yarn\.lock|.*\.min\.(js|css)|.*\.map)$/;

const input = await readStdin();
const file = targetFile(input);
if (!file || SKIP_PATH.test(file)) ok();

let text = '';
try {
  text = readFileSync(file, 'utf8');
} catch {
  ok(); // Binary, deleted, or unreadable: not this hook's problem.
}

const hits = [];
for (const line of text.split('\n')) {
  if (line.length > 500 || PLACEHOLDER.test(line)) continue;
  for (const [re, label] of PATTERNS) {
    if (re.test(line)) {
      hits.push(label);
      break;
    }
  }
}

if (hits.length) {
  flag(
    `SECRET SCAN: possible credential written to ${file} (${[...new Set(hits)].join(', ')}).\n` +
      'Remove it now and replace with an environment variable or secret manager reference. ' +
      'If this file was already committed, tell the user the secret must be rotated, not just deleted.',
  );
}
ok();
