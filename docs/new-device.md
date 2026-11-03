# New-device setup

1. Install Git, zsh, and the AI tools you plan to use. Any subset of supported AI tools works. Node.js enables the optional Claude Code hooks, `jq` is needed for their status line, and Python 3 enables the prose checker and optional routing evaluation.
2. Clone over HTTPS; GitHub SSH setup is not required:

   ```bash
   git clone https://github.com/geraldmaron/ai-workflow.git
   cd ai-workflow
   ./install --dry-run
   ```

   If a required tool is missing, `./install` stops and prints a package-manager command. The dry run does not install files.
3. Read [the shared preferences](../core/GLOBAL.md), [skill catalog](../skills/CATALOG.md), and [safety limits](../README.md#safety-and-limits). Inspect the proposed destinations: wholesale instruction files will replace existing personal content. All skills and supporting resources ship in the checkout; no local override or other repository is required.
4. Run `./install`, or `./install --no-hooks` to omit hooks. If same-name foreign skills cause a collision, the error lists each one; compare them with the repository copies before using `./install --dry-run --adopt` and then `./install --adopt`. Adoption backs up and replaces those skills; it does not change how global instruction files are handled.

5. Sign in through each AI tool's normal setup. The installer does not manage accounts, credentials, or authentication.
6. If Cursor is detected, paste the generated `local/cursor-user-rules.md` into its user-rules settings. This step is manual.
7. Optionally put personal or machine-specific preferences in `local/GLOBAL.local.md`, then run `scripts/sync --dry-run` before `scripts/sync`. Keep credentials out of instruction files. The `local/` directory is ignored and is not needed on another user's machine.
8. Restart the tools, run `scripts/doctor`, and use each tool's native discovery interface to confirm the expected skills appear. Exercise a representative task. The optional `scripts/verify` command calls models and may incur charges; its heuristic result is not proof that the intended instructions loaded.

## Updates and recovery

`scripts/update` fast-forwards from the checkout's configured Git upstream and runs installation; a fork can use its own upstream. With no upstream (a detached HEAD, or a branch without one) it stops before fetching anything. Review incoming source changes before deploying them. `scripts/update --dry-run` fetches upstream metadata but previews deployment of the current checkout, not the fetched revision.

Keep `local/backups/` for recovery. `scripts/rollback` reverses the latest snapshot. `scripts/uninstall --dry-run` previews removal, and `scripts/uninstall` removes managed content. Uninstall is not a restore of the configuration that existed before installation.

## What stays manual

- Cursor user rules (account storage).
- Hooks for tools other than Claude Code.
- Claude Desktop and claude.ai, which have no file-based instruction or skill directory.
