# Tool support

What each tool reads, as confirmed against that tool's own documentation on the date in the last column. Re-check a row before relying on it once it is more than a few months old; `scripts/doctor` prints the date the skill paths were last checked.

| Tool | Global instructions (mode) | Skill roots the tool reads | Same name in two roots | We deploy to | Detection | Checked |
|---|---|---|---|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` (marked region; never a symlink, which the app replaces with a copy) | `~/.claude/skills/` | one root only | `~/.claude/skills/` | `claude` on PATH | 2026-10-29 |
| Codex CLI | `~/.codex/AGENTS.md` (wholesale) | `~/.agents/skills/` | listed twice, not merged | `~/.agents/skills/` | `codex` on PATH | 2026-10-29 |
| OpenCode | `~/.config/opencode/AGENTS.md` (wholesale) | `~/.config/opencode/skills/`, `~/.claude/skills/`, `~/.agents/skills/` | not stated; docs say keep names unique | `~/.agents/skills/` | `opencode` on PATH | 2026-10-29 |
| Gemini CLI | `~/.gemini/GEMINI.md` (marked region) | `~/.gemini/skills/`, `~/.agents/skills/` | higher-precedence copy wins; `.agents` beats `.gemini` | `~/.agents/skills/` | `gemini` on PATH | 2026-10-29 |
| Antigravity | shares `~/.gemini/GEMINI.md` (marked region) | not confirmed | not stated | `~/.agents/skills/` | macOS app, or `antigravity` on PATH | 2026-08-22 |
| Copilot CLI | `~/.copilot/instructions/ai-workflow.instructions.md` (wholesale) | `~/.copilot/skills/`, `~/.agents/skills/` | not stated | `~/.agents/skills/` | `copilot` on PATH | 2026-10-29 |
| Cursor | none on disk; paste `local/cursor-user-rules.md` into Settings, then Rules | `~/.cursor/skills/`, `~/.agents/skills/`, plus `~/.claude/skills/` and `~/.codex/skills/` for compatibility | not stated | `~/.agents/skills/` | `~/.cursor`, the macOS app, or `cursor` on PATH | 2026-10-29 |
| Zed | `~/.config/zed/AGENTS.md` (wholesale) | `~/.agents/skills/` | one root only | `~/.agents/skills/` | `~/.config/zed` or the macOS app | 2026-10-29 |
| IBM Bob | `~/.bob/rules/ai-workflow.md` (wholesale) | `~/.bob/skills/` | one root only | `~/.bob/skills/` | `~/.bob` | 2026-09-25 |
| Hermes Agent | not managed (Hermes keeps its own `SOUL.md`) | `~/.hermes/skills/`, plus each path in `skills.external_dirs` of `~/.hermes/config.yaml` | local copy wins; the external one is logged as shadowed | `~/.agents/skills/`, once `~/.agents/skills` is added to `external_dirs` by hand | not detected; opt-in | 2026-11-02 |

Hermes can edit a skill in place where it finds it, external directories included, so a skill it patches shows as drift in `scripts/doctor` and is overwritten by the next install.

The skill format is the open [Agent Skills](https://agentskills.io/specification) spec.

Deployment writes each skill to one root per tool. Writing to every root a tool reads would put two or three copies of the same skill in front of Cursor, Gemini, Copilot, and OpenCode; of those, only Gemini documents how it resolves a duplicate, and Codex documents that it lists both. Known residual: on a machine with Claude Code installed, Cursor and OpenCode also read `~/.claude/skills/` and so still see two copies. Neither documents how it resolves that.

Sources: code.claude.com/docs/en/skills · learn.chatgpt.com/docs/build-skills · opencode.ai/docs/skills · geminicli.com/docs/cli/skills · docs.github.com/copilot/concepts/agents/about-agent-skills · cursor.com/docs/context/skills · zed.dev/docs/ai/skills · bob.ibm.com/docs/ide/features/skills · antigravity.google/docs · Hermes Agent v0.22.5 bundled docs, user-guide/features/skills.md
