#!/usr/bin/env node
// PostToolUse(Write|Edit|MultiEdit): syntax-check structured files right after
// they are written, so a malformed config is caught at the edit rather than at
// the next run.
//
// Replaces an earlier inline `node -e` hook that read
// process.env.TOOL_INPUT_FILE_PATH. Claude Code never sets that variable, so
// the path was always empty and the hook validated nothing while appearing to
// pass. Payload comes from stdin.
import { readFileSync } from 'node:fs';
import { readStdin, targetFile, flag, ok } from './hook-lib.mjs';

const input = await readStdin();
const file = targetFile(input);
if (!file) ok();

let text = '';
try {
  text = readFileSync(file, 'utf8');
} catch {
  ok();
}

const problem = check(file, text);
if (problem) flag(`${problem}\nFix it before moving on; the file is currently invalid on disk.`);
ok();

function check(path, content) {
  // Files whose tools accept comments despite the .json name.
  const JSONC = /(\.(jsonc|code-workspace)|(^|\/)(tsconfig|jsconfig)[^/]*\.json|(^|\/)\.vscode\/[^/]+\.json|(^|\/)\.?devcontainer\.json)$/;
  // JSON with comments is checked loosely: only bracket balance, since a
  // strict parse would false-positive on legal comments.
  if (JSONC.test(path)) return balanced(content) ? null : `UNBALANCED BRACKETS in ${path}`;
  if (/\.json$/.test(path)) {
    try {
      JSON.parse(content);
    } catch (e) {
      return `INVALID JSON in ${path}: ${e.message}`;
    }
  }
  return null;
}

function balanced(s) {
  const stack = [];
  const pairs = { ')': '(', ']': '[', '}': '{' };
  let inString = false;
  for (let i = 0; i < s.length; i++) {
    const c = s[i];
    if (inString) {
      if (c === '\\') i++;
      else if (c === '"') inString = false;
      continue;
    }
    // JSON strings are double-quoted only; an apostrophe in a comment is text.
    if (c === '"') inString = true;
    else if (c === '/' && (s[i + 1] === '/' || s[i + 1] === '*')) {
      const close = s[i + 1] === '/' ? '\n' : '*/';
      const end = s.indexOf(close, i + 2);
      i = end === -1 ? s.length : end + close.length - 1;
    } else if ('([{'.includes(c)) stack.push(c);
    else if (pairs[c]) {
      if (stack.pop() !== pairs[c]) return false;
    }
  }
  return stack.length === 0;
}
