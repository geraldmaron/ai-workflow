#!/usr/bin/env node
// PreToolUse(Bash): refuse commands that skip the repo's own quality gates.
//
// Bypassing hooks is a human decision, not an agent one. If a pre-commit hook
// is genuinely wrong, the fix is to fix the hook. Denying here is advisory to
// the model, not a security boundary: the user can always run it themselves.
import { readStdin, deny, allow } from './hook-lib.mjs';

const BYPASSES = [
  { re: /\bgit\s+(commit|merge|rebase|push)\b[^|;&]*\s--no-verify\b/, why: '--no-verify skips pre-commit and pre-push hooks' },
  { re: /\bgit\s+commit\b[^|;&]*\s-n\b/, why: '-n on git commit is --no-verify' },
  { re: /\bgit\s+push\b[^|;&]*\s--force(?![-\w])/, why: '--force can destroy a teammate\'s commits; --force-with-lease is the safe form' },
  { re: /\bHUSKY\s*=\s*0\b/, why: 'HUSKY=0 disables the repo\'s commit hooks' },
  { re: /--no-gpg-sign\b/, why: 'skipping commit signing' },
];

const input = await readStdin();
// A commit message is data, not flags: a heredoc opened on a git commit or
// git tag line, then a quoted -m or --message value. Other quoted or heredoc
// text stays, so sh -c "git commit --no-verify" is still caught.
const command = (input?.tool_input?.command ?? '')
  .replace(/^(.*\bgit\s+(?:commit|tag)\b.*<<-?\s*(["']?)(\w+)\2.*)\n[\s\S]*?^\s*\3\b/gm, '$1\n$3')
  .replace(/(\s(?:-m|--message)(?:=|\s+))(["'])(?:\\.|(?!\2)[^\\])*\2/g, '$1""');

const hit = BYPASSES.find(({ re }) => re.test(command));
if (hit) {
  deny(
    `Blocked: ${hit.why}.\n` +
      'If the gate is genuinely wrong, fix the gate or ask the user to run this themselves. ' +
      'Do not work around it silently.',
  );
}
allow();
