# ai-workflow

A standalone toolkit for sharing working preferences and portable skills across AI coding tools. It includes the skill library, supporting resources, installation scripts, and optional Claude Code hooks. No other project, preinstalled skill package, or maintainer-specific setup is required.

## Quick start

On macOS or Linux, install Git and zsh, plus whichever AI tools you use. Then:

```bash
git clone https://github.com/geraldmaron/ai-workflow.git
cd ai-workflow
./install --dry-run
./install
```

Or in one line, which clones to `~/ai-workflow` and installs:

```bash
git clone https://github.com/geraldmaron/ai-workflow.git ~/ai-workflow && ~/ai-workflow/install
```

Before installing for the first time, review [core/GLOBAL.md](core/GLOBAL.md), the [skill catalog](skills/CATALOG.md), and the dry-run output. These are opinionated defaults you can adapt. Some global instruction destinations are replaced in full; see [Safety and limits](#safety-and-limits) before installing over existing settings.

`./install` checks prerequisites, deploys the source in this checkout, and ends with a status report. Missing AI tools are skipped. The shared `~/.agents/skills/` directory is populated even when no tool is detected. Installation does not download an external skill library or sign in to any service.

Node.js is optional for Claude Code hooks; their status line also needs `jq`. Python 3 enables advisory prose checks and is required for optional routing evaluations. Use `./install --no-hooks` to skip hook installation. See [new-device setup](docs/new-device.md) for the full walkthrough.

## What you get

| Layer | What it is | Where it goes |
|---|---|---|
| Core preferences | [core/GLOBAL.md](core/GLOBAL.md): intake, grounding and anti-fabrication, verification, reuse, challenge before committing, writing voice, research, cost, secrets, version control. Short on purpose, because it loads in every session. | Each tool's global instruction file ([manifests/managed-files.tsv](manifests/managed-files.tsv)) |
| Skills | [skills/](skills/CATALOG.md): eighteen skills covering intake, research (look up, verify, internal history), decision framing, adversarial review, context mapping, requirements, writing voice, engineering practice (verification, debugging, commits), product leadership (strategy, metrics, discovery, launches, org entry, impact), and knowledge-base curation. Each is a house output shape, a stand-down boundary, and the task's failure modes, with a worked example. Loaded on demand. Method lineage is in [skills/PROFILES.md](skills/PROFILES.md). | One skill root per tool ([manifests/skill-dest-roots.tsv](manifests/skill-dest-roots.tsv)) |
| Claude Code hooks | Secret scan, written-file validation, bypass guard, skill duplication guard, session cost guard, status line. Merged into `settings.json` without touching anything else. | `~/.claude/hooks`, `~/.claude/settings.json` |

Skills use the open [Agent Skills](https://agentskills.io/specification) format. Each tool gets the library in exactly one root it reads, because several tools read more than one root and do not say how they resolve a duplicate; the [support table](docs/tool-support.md) records what each tool reads, how it treats duplicates, and the one known residual.

## Using your skills

There is nothing to call. Each tool loads only a skill's name and description at startup, and reads the full skill when a request matches it: "poke holes in this plan" brings in `adversarial-review`, "is this done?" brings in `implementation-verification`. To use one explicitly, name it in the request ("use the intake skill on these notes"); in Claude Code you can also type `/<skill-name>`, such as `/intake`.

To see what is installed, run `scripts/skills list` or read the [catalog](skills/CATALOG.md). After editing a skill in this checkout, run `./install` again to deploy it, then start a new session in the tool. To pick up changes from GitHub, run `scripts/update`.

## Commands

```bash
./install [--dry-run] [--no-hooks] [--adopt]
scripts/update [--dry-run]        # git pull --ff-only from the upstream branch, then install
scripts/uninstall [--dry-run]     # remove only what this repo installed
scripts/rollback [snapshot]       # undo the last run (or a named one)
scripts/doctor                    # read-only status: drift, foreign skills, hooks, lint
scripts/verify                    # optional model smoke probe; not proof of loading
scripts/skills list | show <name> | new <name> | lint | catalog
scripts/evals [--judge=codex|claude]   # routing eval; calls a model, costs tokens
scripts/evals --behavior [--live]       # skill vs no-skill on planted traps; offline unless --live
scripts/project-init /path/to/repo [--dry-run]   # project AGENTS.md and CLAUDE.md
tests/run-tests.sh                # safety tests against a scratch home and repo copy
```

Both `scripts/verify` and `scripts/evals` invoke installed model CLIs and may incur usage charges. Installation makes no model calls; CI uses CLI fixtures for evaluation tests. `scripts/evals --behavior` without `--live` only re-scores recorded fixtures and makes no model calls.

## Customize and keep local state private

Edit `core/GLOBAL.md` for shared preferences and the folders under `skills/` for reusable methods. Run `scripts/skills lint` after edits and `scripts/skills catalog` after changing discovery metadata. [AUTHORING.md](skills/AUTHORING.md) explains the local conventions.

For settings that should not travel with the repository, create `local/GLOBAL.local.md`. Sync appends it after the shared core. It is optional: a fresh checkout needs no `local/` files.

The entire `local/` directory is ignored by Git. It holds personal overrides, backups, generated Cursor paste-in text, and evaluation results. Keep private review notes there too. Share a committed Git checkout or source archive, not a copy of a working folder containing local state. Authentication and credentials stay in each tool's normal storage or your existing secret manager.

## Existing skill installations

A same-name skill from another source stops deployment before it writes any
skills or instructions. The error lists every colliding folder. Review those
copies before transferring ownership:

```bash
./install --dry-run --adopt
./install --adopt
```

Adoption backs up the existing directories and replaces them with this
repository's versions. A normal install thereafter updates only owned skills.
No external skill package or authoring runtime is required. The local standard
is [skills/AUTHORING.md](skills/AUTHORING.md).

## Safety and limits

- **Backups.** Managed instruction files, skills, and hooks are backed up under `local/backups/`. One top-level install shares a snapshot across its stages. Keep that directory until you no longer need recovery; `scripts/rollback` restores saved paths and removes paths recorded as newly created. Regenerable Cursor paste-in text is not part of the backup transaction.
- **Global instructions.** Destinations marked `wholesale` in the manifest replace the whole file, including pre-existing personal content. Backups permit recovery but do not merge that content. `--adopt` controls skill collisions only. To recover pre-install content, roll back the installation's snapshot rather than uninstalling.
- **Marked regions.** In files other tools also write, only the text between `<!-- ai-workflow:begin -->` and `<!-- ai-workflow:end -->` changes. A file with duplicated or unpaired markers is refused, not guessed at.
- **Provenance.** Skills this repo deploys carry a matching ownership value in `.managed-by`. Deploy and uninstall prune only matching ownership; foreign collisions require explicit adoption.
- **Retired roots.** Each skill root deployed to is recorded in `local/state/skill-roots`. If the manifest later drops a root, the next install removes this repo's skills from it, and uninstall reaches it too. Entries are compared as resolved paths, and only absolute paths ending in `/skills` are acted on, so a damaged or hand-edited record cannot point a prune at a live root or any other directory. A fresh clone has no record, so this covers roots deployed from the same checkout.
- **Symlinks.** A managed file or `settings.json` that is a symlink (a dotfiles manager's, say) is written through: the link stays, its target changes, and the backup saves the target's content and mode.
- **Interrupted runs.** Each skill is copied whole, ownership marker included, beside its destination and swapped in only when complete. A failed or interrupted copy leaves the previous version in place.
- **Claude Code settings.** A `settings.json` that is not a JSON object with event arrays under `hooks` (JSON with comments, for instance) stops the hook install before any hook file is copied, and is left unchanged. A hook entry counts as this repo's only when every command in it is exactly one this repo writes; a wrapper or edit around one of its scripts belongs to the user.
- **Re-runs.** An unchanged skill, hook, or instruction file is not rewritten or backed up, so a re-run with nothing new adds no snapshot and `scripts/rollback` still undoes the last real change.
- **Lint gate.** `scripts/skills lint` runs before every deploy. It checks selected frontmatter rules, naming, portability, the stand-down heading, per-skill and whole-catalog description budgets, and vocabulary overlap between descriptions. It is not a complete YAML parser. The bundled writing checker supplies advisory warnings when Python is available.
- **Nothing pushed.** No script creates a remote or pushes anything.
- **Checks have limits.** `scripts/doctor` checks files and wiring, not live behavior. The current `scripts/verify` probe can produce false positives; inspect native skill discovery and test a representative task yourself. `evals/routing.tsv` is a reviewed regression set; the optional model-judged run measures label selection, not task quality or a host's loading. Hooks cover only their configured Claude Code events and are not a security boundary; every other harness gets instructions only.

## Development

```bash
scripts/skills lint
tests/run-tests.sh
```

Tests use isolated homes and repository copies, with CLI fixtures instead of paid model calls. CI runs these checks on macOS and Linux. Keep reusable examples and tests in the repository; keep run-specific output in `local/`.

See [docs/decisions.md](docs/decisions.md) for why each of these exists, [docs/tool-support.md](docs/tool-support.md) for what each tool reads, and [docs/new-device.md](docs/new-device.md) for setting up a new machine.
