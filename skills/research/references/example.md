# Example brief

Request: "Does Codex CLI read skills from ~/.claude/skills, or do I need a
separate directory?"

```
Question:  Which user-level directories Codex CLI scans for skills, as of 2026-10-29
Answer:    Codex scans ~/.agents/skills and .agents/skills directories from the
           working directory up to the repository root. It does not read
           ~/.claude/skills. A skill library that must serve both tools deploys
           to both roots or links one to the other.
Findings:
- Codex scans $CWD/.agents/skills, parent and repo-root .agents/skills,
  $HOME/.agents/skills, and /etc/codex/skills. [OpenAI, "Build skills",
  learn.chatgpt.com/docs/build-skills, opened 2026-10-29]
- Codex follows symlinks and does not merge duplicate skill names. [same]
- Claude Code reads ~/.claude/skills and .claude/skills; cloud sessions do
  not read the personal directory. [Anthropic, "Skills", code.claude.com/docs/en/skills,
  opened 2026-10-29]
Inferences:
- Deploying whole folders to both roots is safer than a symlink, because
  Claude Code replaces a symlinked instruction file with a copy. (inference
  from the Claude Code page's note on symlinked CLAUDE.md; the skills page
  says symlinked skill folders are supported, so a link may also work.)
Open:      Whether Codex re-reads the directory during a session or only at
           start. Not stated on the page opened. Settled by a quick test.
Sources read: 2; not reachable: none
Confidence: high on the directory list, medium on symlink behavior
```

What the example shows: the answer is first and short, every finding
carries a source that was opened and dated, the inference is labeled and
says what it rests on, and the open item names how to close it.
