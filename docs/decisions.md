# Decisions

Current design boundaries and their checks. This document describes the shipped toolkit; machine setup, private review notes, and run results belong in ignored `local/` storage.

## One core file, generated into each tool, never symlinked

`core/GLOBAL.md` is the single source. `scripts/sync` writes copies to the destinations in `manifests/managed-files.tsv`, either wholesale or inside a marked region. Copies avoid dependence on the source checkout remaining at the same path. The mode is a deployment policy, not proof of ownership: wholesale mode currently replaces pre-existing personal content too. The installer backs up that content but does not merge it. Review the dry run before installing.

Enforced by: `scripts/doctor` (drift per destination), the marker-count check in `render_marked_region`, tests for idempotency, marker preservation, and duplicated markers.

## The core stays short; anything checkable becomes a mechanism

The core loads into every session of every tool, and adherence falls as simultaneous instructions grow, so each rule gets two to five lines and the depth lives in skills, which load on demand. A rule that is violated is fixed by narrowing its scope or by turning it into a mechanism (a hook, a lint rule, a test), not by adding another rule. New core text is paid for by trimming existing text.

Enforced by: review of `core/GLOBAL.md` diffs; the lint rule that rejects machine-specific paths in `core/`.

## Local state is optional and excluded from distribution

Anything true on one machine only (a path to a local guide, a secrets launcher) goes in optional `local/GLOBAL.local.md`, which sync appends after the core. Backups, generated paste-in text, evaluation results, and private review notes also live under `local/`. Git ignores the entire directory. A new user needs none of it and supplies their own accounts and credentials through native tool setup. There is no required home-directory instruction file or private guide.

Enforced by: lint (`core/` may not contain `/Users/`, `/home/`, `~/Developer/`, `~/Documents/`, or `/opt/homebrew/`); a test that the override is appended.

## Skills use the open Agent Skills format and deploy to one root per tool

A skill is a folder with `SKILL.md` (frontmatter `name` and `description`, then the method) plus optional `references/`. Only name and description load at startup. Deploy copies whole folders to each root listed in `manifests/skill-dest-roots.tsv`, gated by a detection expression. `~/.agents/skills/` is always deployed and serves Codex, Zed, OpenCode, Gemini, Copilot, and Cursor; Claude Code and Bob read only their own directories and get a copy there. Listing every root a tool reads would give Cursor, Gemini, Copilot, and OpenCode two or three copies of each skill; only Gemini documents how it resolves that, and Codex documents that it lists duplicates twice. Every path was read from the vendor's own docs; a path is never added on a secondary source.

Deploy records each root it writes in `local/state/skill-roots`. A recorded root the manifest no longer names is a retired root: deploy removes this repo's skills from it, uninstall reaches it, and doctor reports it until then. Roots are retired only by the manifest, never because a tool went undetected, so a PATH hiccup cannot strip a working install.

Enforced by: the manifest's verification date, printed by `scripts/doctor`; tests for whole-folder copy, detection gating, prune, and retired-root cleanup.

## The toolkit owns its entire portable skills library

All eighteen skills ship in this repository. Their supporting references and scripts travel with their folders. Installation, authoring, lint, and evaluation do not depend on an external project's runtime or an already-installed skill.

Deployment checks every skill destination before writing and refuses foreign collisions. The explicit `--adopt` option backs up those directories and transfers ownership. Normal installation needs no adoption on an empty destination. This prevents a shared skill name from silently changing the owner of an existing installation.

Enforced by: scratch-home installation tests, collision/adoption tests, exact ownership checks, and the local-only catalog used by evaluation.

## Open format, local authoring policy

The format is the open Agent Skills specification; local policy lives in `skills/AUTHORING.md`. `scripts/skills lint` checks a documented subset:

- frontmatter opens on line 1 and closes; selected invalid plain-description patterns are rejected (this is not a full YAML parser)
- name matches the folder; description is present and stays under 1024 characters
- no host tool or vendor feature names, no machine-specific paths
- an explicit stand-down rule
- no more than 500 lines; longer supporting material belongs in `references/`

Judgment rules stay the author's job: useful examples, conditional composition, and a stand-down that treats applying nothing as a correct outcome. There is no minimum line count or mandated description opener. Format compliance and usefulness are different checks.

## A skill is a shape, a boundary, and a failure-mode list, not a method lecture

Reviewed 2026-10-29 with an adversarial pass on every skill. The previous generation re-taught method the model already knows, repeated each rule in a step, a gates list, and a closing record, and carried a per-file "what is enforced" paragraph that enforced nothing. Models imitate the style of their instructions, so the skills produced compliance prose. Each skill now carries: what it produces, when to stand down, numbered imperative steps with literal output shapes, a filled example, a short closing checklist (a skipped item says `not done: <reason>`), the task's failure modes, and the siblings it hands to. Always-on rules stay in the core. The three research skills (look-up, verification, internal history) became one skill with three modes, because their descriptions collided on realistic requests.

Enforced by: lint (stand-down heading, length, description budgets, overlap report, prose tells); `skills/AUTHORING.md`.

## Method lineage lives once, in PROFILES.md

Each skill used to carry `references/sources.md`, a bibliography nothing at run time read. `skills/PROFILES.md` now holds the recurring techniques (evidence markers, rival hypotheses, pre-mortem, reversibility, earned questions, and so on) with their lineage and the skills that use them, plus per-skill domain sources. Skills restate a technique's rule inline in a line or two and never link to the profiles file, because a deployed folder must work alone. The profiles file is for maintainers.

## Descriptions have a budget

Hosts show every installed skill's name and description in one listing, and Codex truncates it near 8,000 characters, shortening descriptions first. Lint warns above 520 characters per skill and 8,000 for the catalog, and reports pairs of descriptions whose vocabulary overlaps. `evals/routing.tsv` keeps a reviewed request per skill and per reported overlap. The model-judged routing run is optional and is not a release gate.

## Skill names say what the skill does

A name is a functional noun phrase: `root-cause-debugging`, `knowledge-base-curation`, `adversarial-review`. It never names a persona or metaphor (advocate, devil, expert, guru, wizard, hat) or a vendor or product (Slack, Notion, GitHub, Claude), because the skill outlives both.

Enforced by: lint.

## Writing voice: a baseline everywhere, a catalog and a checker in the skill

The core's Output rule supplies a short prose preference. The detailed catalog, its style heuristics, and `voice-check.py` ship in this repository's written-voice skill. Lint runs that local checker when Python is available and reports advisory warnings. A style warning is not evidence that prose is wrong or AI-generated; the author judges whether it improves the result.

Enforced by: the written-voice closing gate and record; lint warnings on this repo's skills.

## Claude Code settings: this repo owns its entries, never the file

`settings.json`, MCP config, `config.toml`, and auth files mix machine state and secrets and are rewritten by their apps, so this repo never manages them as files. The one exception is narrow: `scripts/hooks install` merges this repo's hook entries and status line into `settings.json`, identified by the script paths they point at, and leaves every other key and hook alone. Uninstall removes only those entries. `scripts/hooks check` runs in doctor and reports any configured hook, from any source, whose script is missing.

Hooks read their payload from stdin and fail open, so a broken guard cannot break a session.

Enforced by: tests for merge, idempotency, foreign-entry preservation, and uninstall; `hook-lib.mjs`.

## Cursor user rules are pasted, not written

Cursor stores user rules in the account, with no local file. Sync writes the paste-in text to `local/cursor-user-rules.md` and doctor reports whether it is current. Project-level Cursor rules are out of scope for the user-level install.

## Managed changes have rollback snapshots

One snapshot directory per run records pre-run state for managed instruction files, skills, and hooks. `index.tsv` maps each saved copy to its original path, with `-` for paths the run created. `scripts/rollback` restores those paths and removes created ones, and backs itself up first so it can be undone. Generated Cursor paste-in text is regenerable and not backed up by sync. `scripts/uninstall` removes managed files, managed regions, owned skills, and this repo's hooks; it does not restore an earlier installation state.

Unchanged content is neither rewritten nor backed up, so a no-op run creates no snapshot and the latest snapshot is always the last real change.

Enforced by: tests for underscore-containing paths, created-file removal, an uninstall that rolls back, and a no-op re-run that adds no snapshot.

## macOS and Linux, zsh required, one POSIX entry point

`./install` is POSIX `sh` so it runs before zsh is known to exist; it checks git and zsh, names node, jq, and python3 if missing, and prints the install command for the machine's package manager. The scripts behind it are zsh. Detection expressions check a CLI or config directory as well as a macOS app path, so tools are found on Linux. CI runs lint, the tests, and a clean-home install dry run on Ubuntu and macOS.

Distribution stays local to this checkout and does not download another package at install time. A maintained validator, installer, or converter can replace a responsibility when it preserves the ownership and rollback contracts and reduces demonstrated maintenance work. It need not replace every surface to be useful.

## Routing is reviewed, and measured only on request

A skill that never fires still occupies catalog space. `evals/routing.tsv` contains reusable requests with the skill that should load (or none); it is the regression set an author reads when a description changes, and lint's overlap report says which pairs need a separating case. `scripts/evals` can run the set through a model and record its picks in ignored `local/evals/last-run.tsv`. It measures label selection, not a host's actual loading behavior or the skill's benefit, costs tokens, and is not a gate. `scripts/evals --behavior --live` measures the benefit: each scenario in `evals/behavior/` runs with and without the library on more than one model and is scored on planted traps. Clean prompts alone proved too easy: frontier models passed the traps without the library, so a scenario may add `[variants]` that ask for the same task under pressure (a deadline, sunk cost, a leading suggestion), run as `<id>+<name>` with the same checks. A skill that still does not beat the no-skill arm under pressure on two models is a candidate to merge or cut. Its offline mode, which only re-scores recorded fixtures, runs in CI; the live run costs tokens and is not a gate either. No saved score is distributed as evidence about another user's environment.

## Rejected structures

- **Persona lenses** ("ask the security expert, then the PM"). A role label alone does not establish independent coverage or better results. Prefer explicit concerns and evidence; evaluate additional reviewers only when the task warrants their cost.
- **An orchestration runtime.** This toolkit distributes preferences and portable skills. It has no demonstrated need for a separate execution runtime. Revisit only if an observed workflow requires it; skill-format support is not the deciding criterion.
