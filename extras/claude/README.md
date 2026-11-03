# extras/claude

Claude Code hooks and status line, installed by `scripts/hooks install` (which `./install` runs when Claude Code and node are present). Other AI tools have their own hook systems; these scripts are Claude Code only.

| File | Event | What it does |
|---|---|---|
| `hooks/block-no-verify.mjs` | PreToolUse, Bash | Denies `git --no-verify`, `git push --force` (not `--force-with-lease`), `HUSKY=0`, and `--no-gpg-sign`. |
| `hooks/validate-written-file.mjs` | PostToolUse, Write/Edit | Flags invalid JSON and unbalanced JSONC right after the write. |
| `hooks/scan-secrets.mjs` | PostToolUse, Write/Edit | Flags a credential written to disk (cloud, model provider, GitHub, GitLab, Slack, Stripe, Supabase keys, private key blocks, hardcoded passwords). |
| `hooks/skill-duplication-guard.mjs` | PostToolUse, Write/Edit | Flags a same-name installed skill not managed by this toolkit. |
| `hooks/session-cost-guard.mjs` | UserPromptSubmit | Warns when the session transcript passes 10 MB and 25 MB, a proxy for expensive long-context sessions. |
| `statusline-command.sh` | status line | Model, git branch, folder, and session cost, with a nudge to clear context past $40 or 200k tokens. |

All hooks share `hooks/hook-lib.mjs`: read the payload from stdin (Claude Code does not pass tool input in environment variables) and fail open, so a broken guard never blocks a session.

Hooks require Node.js; the status line also requires `jq`. These are event-specific checks, not general enforcement: shell writes and other harnesses are outside the written-file matchers. Transcript size is a cost heuristic, not billing telemetry. Review the shipped policies before enabling them, or use `./install --no-hooks`.

`scripts/hooks install` merges only these entries into `~/.claude/settings.json`; `scripts/hooks uninstall` removes only them; `scripts/hooks check` reports any configured hook whose script is missing. An existing status line from another source is kept.
