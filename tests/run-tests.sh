#!/usr/bin/env zsh
# Safety-behavior tests. Every test runs against a scratch HOME and a scratch
# copy of the repo, so nothing touches the real machine or this checkout.

set -euo pipefail
REAL_REPO="$(cd "$(dirname "${(%):-%x}")/.." && pwd)"
SCRIPTS="$REAL_REPO/scripts"
FAIL=0

pass() { print -r -- "PASS: $1" }
fail() { print -r -- "FAIL: $1"; FAIL=1 }
digest() { cksum < "$1" | awk '{print $1 $2}' }

# write_fixture_skill <dir> <name> - a minimal skill that passes lint, so
# deploy-path tests are not blocked by it.
write_fixture_skill() {
  local dir="$1" fname="$2"
  mkdir -p "$dir"
  print -r -- "---
name: ${fname}
description: Use when exercising the deploy path in tests and nothing else at all. Stand down outside the test suite.
license: Apache-2.0
metadata:
  version: 0.1.0
---

# ${fname}

## 1. Scope, and when to stand down

Engage only inside the test suite. Stand down everywhere else.

## 2. The closing gates

1. Fixture used only in tests.

## 3. The record

\`\`\`
Fixture record
- Gate: answered, see <where>
\`\`\`

## 4. What is enforced, and by what

Nothing here is machine-enforced by this file.

## When NOT to use

Outside the test suite.
" > "$dir/SKILL.md"
}

# scratch_repo [skill-name...] - a repo copy with the real core and manifests
# and only the named fixture skills. Prints its path.
scratch_repo() {
  local dir name
  dir=$(mktemp -d)
  cp -R "$REAL_REPO/core" "$REAL_REPO/manifests" "$dir/"
  mkdir -p "$dir/skills"
  for name in "$@"; do write_fixture_skill "$dir/skills/$name" "$name"; done
  print -r -- "$dir"
}

TMPHOME=$(mktemp -d)
CLEANUP=("$TMPHOME")
trap 'rm -rf "${CLEANUP[@]}"' EXIT
export HOME="$TMPHOME"
mkdir -p "$HOME/.codex" "$HOME/.gemini" "$HOME/.config/opencode"

# Stand-ins for AI tool CLIs, so detection is under the test's control and does
# not depend on what happens to be installed on the machine running the tests.
FAKEBIN=$(mktemp -d)
CLEANUP+=("$FAKEBIN")
for tool in codex gemini opencode; do
  print -r -- $'#!/bin/sh\nexit 0' > "$FAKEBIN/$tool"
  chmod +x "$FAKEBIN/$tool"
done
# Only the stand-ins and the system directories, so real AI tools installed on
# this machine are invisible to detection. zsh and python3 live in these on
# macOS and on Linux distributions alike.
BASEPATH="$FAKEBIN:/usr/bin:/bin"

export REPO_ROOT=$(scratch_repo keeper)
CLEANUP+=("$REPO_ROOT")

# --- sync: wholesale write on empty file ---
PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true
if [[ -f "$HOME/.codex/AGENTS.md" ]] && grep -q "MANAGED BY ai-workflow" "$HOME/.codex/AGENTS.md"; then
  pass "wholesale destination created with managed header"
else
  fail "wholesale destination missing or unheadered"
fi

# --- sync: idempotency ---
before=$(digest "$HOME/.codex/AGENTS.md")
PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true
if [[ "$before" == "$(digest "$HOME/.codex/AGENTS.md")" ]]; then
  pass "idempotent: unchanged source produces unchanged output"
else
  fail "second sync run changed output with no source edits"
fi

# --- sync: marked region preserves content outside markers ---
print -r -- "# my hand-written gemini notes" > "$HOME/.gemini/GEMINI.md"
PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true
if grep -q "my hand-written gemini notes" "$HOME/.gemini/GEMINI.md" && grep -q "ai-workflow:begin" "$HOME/.gemini/GEMINI.md"; then
  pass "marked-region preserves pre-existing hand-written content"
else
  fail "marked-region write clobbered existing content"
fi

# --- sync: duplicated markers are refused, not guessed at ---
dup="$HOME/.gemini/GEMINI.md"
cat "$dup" "$dup" > "$dup.tmp" && mv "$dup.tmp" "$dup"
before=$(digest "$dup")
if PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1; then
  fail "sync accepted a file with duplicated markers"
elif [[ "$before" == "$(digest "$dup")" ]]; then
  pass "duplicated markers stop sync and leave the file untouched"
else
  fail "sync refused duplicated markers but still changed the file"
fi
doctor_out=$(PATH="$BASEPATH" "$SCRIPTS/doctor" 2>/dev/null) || true
if [[ "$doctor_out" == *"markers-broken"*"SKILLS"*"HOOKS"* ]]; then
  pass "doctor reports duplicated markers and finishes the report"
else
  fail "doctor stopped at a file with duplicated markers"
fi
print -r -- "# my hand-written gemini notes" > "$dup"

# --- sync: dry-run makes no filesystem changes ---
rm -f "$HOME/.config/opencode/AGENTS.md"
PATH="$BASEPATH" "$SCRIPTS/sync" --dry-run >/dev/null 2>&1 || true
if [[ ! -f "$HOME/.config/opencode/AGENTS.md" ]]; then
  pass "dry-run wrote nothing to a missing destination"
else
  fail "dry-run wrote a file to disk"
fi

# --- sync: absent tools are skipped, not errors ---
if out=$(PATH="/usr/bin:/bin:${PATH}" HOME="$(mktemp -d)" "$SCRIPTS/sync" --dry-run 2>&1); then
  if [[ "$out" == *"skip"* ]]; then
    pass "missing tools are skipped, not treated as errors"
  else
    fail "expected skip messages not found"
  fi
else
  fail "sync exited nonzero when tools were simply absent"
fi

# --- sync: the per-machine override is appended after the shared core ---
mkdir -p "$REPO_ROOT/local"
print -r -- "machine-only override line" > "$REPO_ROOT/local/GLOBAL.local.md"
PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true
if grep -q "machine-only override line" "$HOME/.codex/AGENTS.md"; then
  pass "local/GLOBAL.local.md is appended on sync"
else
  fail "local override was not appended"
fi
rm -f "$REPO_ROOT/local/GLOBAL.local.md"
PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true

# --- lint: the real library passes ---
if REPO_ROOT="$REAL_REPO" "$SCRIPTS/skills" lint >/dev/null 2>&1; then
  pass "shipped skills library passes lint"
else
  fail "shipped skills library fails lint (run: scripts/skills lint)"
fi

# --- lint: catches a defective skill ---
SCRATCH=$(mktemp -d); CLEANUP+=("$SCRATCH")
mkdir -p "$SCRATCH/skills/broken"
print -r -- '---
name: mismatched
---

# Broken
' > "$SCRATCH/skills/broken/SKILL.md"
lint_out=$(REPO_ROOT="$SCRATCH" "$SCRIPTS/skills" lint 2>&1 || true)
missed=""
for expected in "does not match directory" "frontmatter has no 'description:'" "stand-down rule"; do
  [[ "$lint_out" == *"$expected"* ]] || missed="$missed '$expected'"
done
if [[ -z "$missed" ]]; then
  pass "lint detects name mismatch, missing description, and missing boundary"
else
  fail "lint missed:$missed"
fi

# --- lint: short methods do not require a fixed ceremony ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
print -r -- '---
name: keeper
description: Exercise a narrow fixture workflow when validating the toolkit in isolation.
---

# Keeper

## Scope, and when to stand down

Use the fixture only for its test. Stand down for other tasks.
' > "$SCRATCH/skills/keeper/SKILL.md"
if REPO_ROOT="$SCRATCH" "$SCRIPTS/skills" lint >/dev/null 2>&1; then
  pass "short methods need no fixed opener, record, or enforcement boilerplate"
else
  fail "lint required ceremonial text in a valid short method"
fi

# --- lint: names must be functional, not personas or vendors ---
SCRATCH=$(scratch_repo devils-advocate); CLEANUP+=("$SCRATCH")
lint_out=$(REPO_ROOT="$SCRATCH" "$SCRIPTS/skills" lint 2>&1 || true)
if [[ "$lint_out" == *"persona, metaphor, or vendor"* ]]; then
  pass "lint rejects a persona-named skill"
else
  fail "lint accepted a persona-named skill"
fi

# --- lint: a description strict YAML parsers would reject is caught ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
sed -i.bak 's/^description: Use when exercising the deploy path in tests/description: Use when exercising the deploy path: in tests/' "$SCRATCH/skills/keeper/SKILL.md"
lint_out=$(REPO_ROOT="$SCRATCH" "$SCRIPTS/skills" lint 2>&1 || true)
if [[ "$lint_out" == *"plain YAML value"* ]]; then
  pass "lint rejects a plain YAML description containing ': '"
else
  fail "lint accepted a description strict YAML parsers reject"
fi

# --- lint: core preferences must not carry a machine-specific path ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
print -r -- "Read ~/Developer/Guides/secret.md first." >> "$SCRATCH/core/GLOBAL.md"
lint_out=$(REPO_ROOT="$SCRATCH" "$SCRIPTS/skills" lint 2>&1 || true)
if [[ "$lint_out" == *"core/GLOBAL.md"*"machine-specific path"* ]]; then
  pass "lint rejects a machine-specific path in core"
else
  fail "lint accepted a machine-specific path in core"
fi

# --- deploy: whole-directory copy, and prune of what the repo dropped ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
mkdir -p "$SCRATCH/skills/keeper/references"
print -r -- "supporting reference material" > "$SCRATCH/skills/keeper/references/notes.md"
mkdir -p "$HOME/.agents/skills/stale-skill"
print -r -- "left over from a deleted skill" > "$HOME/.agents/skills/stale-skill/SKILL.md"
print -r -- "deployed by ai-workflow-config; removed by scripts/deploy when the repo drops it, or by scripts/uninstall" > "$HOME/.agents/skills/stale-skill/.managed-by"
PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -f "$HOME/.agents/skills/keeper/references/notes.md" ]]; then
  pass "deploy copies supporting files, not just SKILL.md"
else
  fail "deploy dropped a skill's supporting files"
fi
if [[ ! -d "$HOME/.agents/skills/stale-skill" ]]; then
  pass "deploy prunes skills the repo no longer defines"
else
  fail "orphaned skill survived deploy and will keep firing"
fi

# --- deploy: an install made under the old name migrates in place ---
# (the stale-skill above carries the old marker, so prune already covers it)
MHOME=$(mktemp -d); CLEANUP+=("$MHOME")
mkdir -p "$MHOME/.agents/skills" "$MHOME/.gemini"
cp -R "$SCRATCH/skills/keeper" "$MHOME/.agents/skills/keeper"
print -r -- "deployed by ai-workflow-config; removed by scripts/deploy when the repo drops it, or by scripts/uninstall" > "$MHOME/.agents/skills/keeper/.managed-by"
print -r -- "# my notes"$'\n\n'"<!-- ai-workflow-config:begin -->"$'\n'"old core"$'\n'"<!-- ai-workflow-config:end -->" > "$MHOME/.gemini/GEMINI.md"
HOME="$MHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if grep -q "^deployed by ai-workflow;" "$MHOME/.agents/skills/keeper/.managed-by"; then
  pass "deploy adopts a skill deployed under the old name and rewrites its marker"
else
  fail "deploy left or refused a skill deployed under the old name"
fi
if [[ -f "$MHOME/.gemini/GEMINI.md" ]] && ! grep -q "ai-workflow-config" "$MHOME/.gemini/GEMINI.md" \
  && (( $(grep -c "ai-workflow:begin" "$MHOME/.gemini/GEMINI.md") == 1 )) && grep -q "# my notes" "$MHOME/.gemini/GEMINI.md"; then
  pass "deploy rewrites an old-name marked region instead of adding a second"
else
  fail "old-name marked region was duplicated or lost: $(grep -c 'begin' "$MHOME/.gemini/GEMINI.md" 2>/dev/null)"
fi

# --- deploy: a renamed skill leaves nothing behind under its old name ---
mv "$SCRATCH/skills/keeper" "$SCRATCH/skills/renamed-keeper"
sed -i.bak 's/^name: keeper$/name: renamed-keeper/' "$SCRATCH/skills/renamed-keeper/SKILL.md" && rm -f "$SCRATCH/skills/renamed-keeper/SKILL.md.bak"
PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -d "$HOME/.agents/skills/renamed-keeper" && ! -d "$HOME/.agents/skills/keeper" ]]; then
  pass "a renamed skill is deployed under its new name and pruned under its old one"
else
  fail "rename left the old skill behind or skipped the new one"
fi

# --- deploy: lint failure blocks deployment ---
SCRATCH=$(mktemp -d); CLEANUP+=("$SCRATCH")
cp -R "$REAL_REPO/core" "$REAL_REPO/manifests" "$SCRATCH/"
mkdir -p "$SCRATCH/skills/no-boundary"
print -r -- '---
name: no-boundary
description: Use when testing that a failing lint blocks deployment entirely.
---

# No boundary
' > "$SCRATCH/skills/no-boundary/SKILL.md"
if PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1; then
  fail "deploy ran on a library that fails lint"
elif [[ ! -d "$HOME/.agents/skills/no-boundary" ]]; then
  pass "failing lint blocks deploy and writes nothing"
else
  fail "lint gate exited nonzero but still wrote skills"
fi

# --- deploy: one skill root per tool, following real tool detection ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
rm -rf "$HOME/.agents" "$HOME/.claude" "$HOME/.gemini" "$HOME/.copilot" "$HOME/.bob"
mkdir -p "$HOME/.bob"
PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -d "$HOME/.agents/skills/keeper" ]]; then
  pass "the tool-neutral ~/.agents/skills root deploys unconditionally"
else
  fail "~/.agents/skills did not receive the skill"
fi
if [[ -d "$HOME/.bob/skills/keeper" ]]; then
  pass "a detected tool with its own root (bob) receives the skill there"
else
  fail "bob was detectable but its skill root was not populated"
fi
if [[ ! -d "$HOME/.gemini/skills" ]]; then
  pass "a tool that also reads ~/.agents/skills (fake gemini on PATH) gets no second copy"
else
  fail "gemini received a duplicate copy in its own root"
fi
if [[ ! -d "$HOME/.copilot/skills" && ! -d "$HOME/.claude/skills" ]]; then
  pass "undetected tools receive no skill deploy"
else
  fail "a skill root was populated for a tool that was not detected"
fi

# --- deploy: foreign skills survive; ours carry a provenance marker ---
mkdir -p "$HOME/.agents/skills/from-another-tool"
print -r -- "installed by a different tool entirely" > "$HOME/.agents/skills/from-another-tool/SKILL.md"
PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -f "$HOME/.agents/skills/from-another-tool/SKILL.md" ]]; then
  pass "a skill from another tool survives deploy and prune"
else
  fail "prune destroyed a skill this repo did not deploy"
fi
if [[ -f "$HOME/.agents/skills/keeper/.managed-by" ]]; then
  pass "repo-deployed skills carry a provenance marker"
else
  fail "deployed skill has no .managed-by marker"
fi

# --- ownership: collisions require adoption; other marker values survive ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
CHOME=$(mktemp -d); CLEANUP+=("$CHOME")
mkdir -p "$CHOME/.agents/skills/keeper" "$CHOME/.agents/skills/foreign-marked"
print -r -- "foreign original" > "$CHOME/.agents/skills/keeper/SKILL.md"
print -r -- "foreign marked" > "$CHOME/.agents/skills/foreign-marked/SKILL.md"
print -r -- "different installer" > "$CHOME/.agents/skills/foreign-marked/.managed-by"
if HOME="$CHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1; then
  fail "deploy accepted a same-name foreign skill without adoption"
elif [[ "$(<"$CHOME/.agents/skills/keeper/SKILL.md")" == "foreign original" && ! -e "$SCRATCH/local/backups" && ! -e "$CHOME/.codex/AGENTS.md" ]]; then
  pass "foreign collision blocks the entire deploy before writes"
else
  fail "collision refusal changed the existing installation"
fi
HOME="$CHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" --adopt --dry-run >/dev/null 2>&1
if [[ "$(<"$CHOME/.agents/skills/keeper/SKILL.md")" == "foreign original" && ! -e "$SCRATCH/local/backups" ]]; then
  pass "adoption dry run preserves foreign skills and creates no backup"
else
  fail "adoption dry run wrote files"
fi
HOME="$CHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" --adopt >/dev/null 2>&1
if [[ -f "$CHOME/.agents/skills/keeper/.managed-by" && -f "$CHOME/.agents/skills/foreign-marked/SKILL.md" ]]; then
  pass "explicit adoption marks our skill and preserves other owners' markers"
else
  fail "adoption did not preserve ownership boundaries"
fi
HOME="$CHOME" REPO_ROOT="$SCRATCH" "$SCRIPTS/rollback" >/dev/null 2>&1
if [[ "$(<"$CHOME/.agents/skills/keeper/SKILL.md")" == "foreign original" && ! -e "$CHOME/.agents/skills/keeper/.managed-by" ]]; then
  pass "rollback restores the foreign skill and its original ownership"
else
  fail "adoption rollback did not restore the foreign skill"
fi
HOME="$CHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/uninstall" >/dev/null 2>&1
if [[ -f "$CHOME/.agents/skills/foreign-marked/SKILL.md" ]]; then
  pass "uninstall preserves a marker belonging to another installer"
else
  fail "uninstall deleted a directory owned by another installer"
fi

LHOME=$(mktemp -d); CLEANUP+=("$LHOME")
mkdir -p "$LHOME/.bob" "$LHOME/.bob/skills/keeper"
print -r -- "later root is foreign" > "$LHOME/.bob/skills/keeper/SKILL.md"
if HOME="$LHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1; then
  fail "deploy accepted a foreign collision in a later root"
elif [[ ! -e "$LHOME/.agents/skills/keeper" ]]; then
  pass "a later-root collision is detected before the first root is written"
else
  fail "later-root collision left a partial skill deployment"
fi

SHOME=$(mktemp -d); CLEANUP+=("$SHOME")
LINKREPO=$(scratch_repo keeper); CLEANUP+=("$LINKREPO")
mkdir -p "$SHOME/.agents/skills"
ln -s "$SHOME/missing-target" "$SHOME/.agents/skills/keeper"
HOME="$SHOME" PATH="$BASEPATH" REPO_ROOT="$LINKREPO" "$SCRIPTS/deploy" --adopt >/dev/null 2>&1
HOME="$SHOME" REPO_ROOT="$LINKREPO" "$SCRIPTS/rollback" >/dev/null 2>&1
if [[ -L "$SHOME/.agents/skills/keeper" && "$(readlink "$SHOME/.agents/skills/keeper")" == "$SHOME/missing-target" ]]; then
  pass "adoption rollback restores an existing broken symlink"
else
  fail "adoption lost the original broken symlink"
fi

# --- rollback: restores paths containing underscores, removes what the run created ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
mkdir -p "$HOME/some_tool/nested_dir"
print -r -- "original" > "$HOME/some_tool/nested_dir/config_file.md"
REPO_ROOT="$SCRATCH" AIWF_BACKUP_TS=rollback-test zsh -c '
  source "'"$SCRIPTS"'/lib.sh"
  backup_path "$HOME/some_tool/nested_dir/config_file.md"
  backup_path "$HOME/some_tool/created_by_run.md"' 2>/dev/null
print -r -- "changed" > "$HOME/some_tool/nested_dir/config_file.md"
print -r -- "new" > "$HOME/some_tool/created_by_run.md"
REPO_ROOT="$SCRATCH" "$SCRIPTS/rollback" rollback-test >/dev/null 2>&1 || true
if [[ "$(<"$HOME/some_tool/nested_dir/config_file.md")" == "original" && ! -e "$HOME/some/tool" ]]; then
  pass "rollback restores a path containing underscores to that exact path"
else
  fail "rollback restored to the wrong path or did not restore"
fi
if [[ ! -e "$HOME/some_tool/created_by_run.md" ]]; then
  pass "rollback removes files the run created"
else
  fail "rollback left behind a file the run created"
fi

# --- uninstall: returns the machine to its pre-install state, and rollback undoes it ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
UHOME=$(mktemp -d); CLEANUP+=("$UHOME")
mkdir -p "$UHOME/.gemini" "$UHOME/.agents/skills/from-another-tool"
print -r -- "# notes that predate the install" > "$UHOME/.gemini/GEMINI.md"
print -r -- "foreign" > "$UHOME/.agents/skills/from-another-tool/SKILL.md"
gemini_before=$(digest "$UHOME/.gemini/GEMINI.md")
HOME="$UHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
HOME="$UHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/uninstall" >/dev/null 2>&1 || true
if [[ "$gemini_before" == "$(digest "$UHOME/.gemini/GEMINI.md")" && ! -e "$UHOME/.codex/AGENTS.md" ]]; then
  pass "uninstall restores shared files byte for byte and removes managed ones"
else
  fail "uninstall left managed content behind or damaged a shared file"
fi
if [[ ! -d "$UHOME/.agents/skills/keeper" && -f "$UHOME/.agents/skills/from-another-tool/SKILL.md" ]]; then
  pass "uninstall removes this repo's skills and keeps everyone else's"
else
  fail "uninstall removed the wrong skills"
fi
HOME="$UHOME" REPO_ROOT="$SCRATCH" "$SCRIPTS/rollback" >/dev/null 2>&1 || true
if [[ -d "$UHOME/.agents/skills/keeper" ]] && grep -q "ai-workflow:begin" "$UHOME/.gemini/GEMINI.md"; then
  pass "rollback undoes an uninstall"
else
  fail "rollback did not restore what uninstall removed"
fi

# --- hooks: install merges with foreign entries; uninstall removes only ours ---
if command -v node >/dev/null 2>&1; then
  HHOME=$(mktemp -d); CLEANUP+=("$HHOME")
  HREPO=$(scratch_repo); CLEANUP+=("$HREPO")
  cp -R "$REAL_REPO/extras" "$HREPO/"
  mkdir -p "$HHOME/.claude"
  print -r -- '{"model":"x","hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"node /elsewhere/theirs.mjs"}]}]},"statusLine":{"type":"command","command":"bash /elsewhere/status.sh"}}' > "$HHOME/.claude/settings.json"
  HOME="$HHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  HOME="$HHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  counts=$(node -e '
    const s = require(process.argv[1]);
    const cmds = Object.values(s.hooks).flat().flatMap((e) => e.hooks.map((h) => h.command));
    console.log([cmds.filter((c) => c.includes("theirs.mjs")).length,
                 cmds.filter((c) => c.includes("block-no-verify.mjs")).length,
                 s.model, s.statusLine.command.includes("/elsewhere/") ? "kept" : "replaced"].join(" "));
  ' "$HHOME/.claude/settings.json")
  if [[ "$counts" == "1 1 x kept" ]]; then
    pass "hooks install merges once, keeps foreign hooks, other keys, and a foreign status line"
  else
    fail "hooks install result was: $counts (want: 1 1 x kept)"
  fi
  HOME="$HHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" uninstall >/dev/null 2>&1 || true
  left=$(node -e '
    const s = require(process.argv[1]);
    console.log(Object.values(s.hooks ?? {}).flat().flatMap((e) => e.hooks.map((h) => h.command)).join(","));
  ' "$HHOME/.claude/settings.json")
  if [[ "$left" == "node /elsewhere/theirs.mjs" && ! -e "$HHOME/.claude/hooks/block-no-verify.mjs" ]]; then
    pass "hooks uninstall removes only this repo's hooks and files"
  else
    fail "hooks uninstall left: $left"
  fi
  if [[ -d "$HREPO/local/backups" ]]; then
    pass "hook tests keep their backups in the scratch repository"
  else
    fail "hook tests did not isolate their backup state"
  fi
else
  print -r -- "SKIP: hooks tests (node not installed)"
fi

# --- duplication feedback uses installed ownership, with no external registry ---
if command -v node >/dev/null 2>&1; then
  DHOME=$(mktemp -d); CLEANUP+=("$DHOME")
  mkdir -p "$DHOME/.agents/skills/keeper"
  print -r -- "installed skill" > "$DHOME/.agents/skills/keeper/SKILL.md"
  print -r -- "another installer" > "$DHOME/.agents/skills/keeper/.managed-by"
  payload='{"tool_input":{"file_path":"/scratch/skills/keeper/SKILL.md"}}'
  if print -r -- "$payload" | HOME="$DHOME" node "$REAL_REPO/extras/claude/hooks/skill-duplication-guard.mjs" >/dev/null 2>&1; then
    fail "duplication guard ignored a foreign ownership value"
  elif [[ $? == 2 ]]; then
    pass "duplication guard flags a foreign same-name skill"
  else
    fail "duplication guard crashed"
  fi
  print -r -- "deployed by ai-workflow; removed by scripts/deploy when the repo drops it, or by scripts/uninstall" > "$DHOME/.agents/skills/keeper/.managed-by"
  if print -r -- "$payload" | HOME="$DHOME" node "$REAL_REPO/extras/claude/hooks/skill-duplication-guard.mjs" >/dev/null 2>&1; then
    pass "duplication guard accepts a copy managed by this repository"
  else
    fail "duplication guard rejected this repository's own copy"
  fi
fi

# --- hook guards: what each one catches, and what it must let through ---
if command -v node >/dev/null 2>&1; then
  GUARDS="$REAL_REPO/extras/claude/hooks"
  GDIR=$(mktemp -d); CLEANUP+=("$GDIR")
  # bash_verdict <command> - deny or allow, as block-no-verify decides it.
  bash_verdict() {
    node -e 'console.log(JSON.stringify({tool_input:{command:process.argv[1]}}))' "$1" \
      | node "$GUARDS/block-no-verify.mjs" | grep -q '"deny"' && print deny || print allow
  }
  guard_bad=0
  while IFS=$'\t' read -r want cmd; do
    cmd=${cmd//\\n/$'\n'}
    got=$(bash_verdict "$cmd")
    [[ "$got" == "$want" ]] || { fail "block-no-verify: $got, want $want: ${cmd//$'\n'/⏎}"; guard_bad=1 }
  done <<'CASES'
deny	git commit -n -m "x"
deny	git commit -m "x" --no-verify
deny	sh -c "git commit --no-verify"
deny	sh <<'EOF'\ngit commit --no-verify\nEOF
deny	git commit -m "$(cat <<'EOF'\nx\nEOF\n)" --no-verify
deny	git push --force origin main
allow	git push --force-with-lease --force-if-includes origin main
allow	git commit -m "add -n flag to the parser"
allow	git commit --message='mention --no-verify'
allow	git commit -F - <<'MSG'\nthe guard reads --no-verify as a flag\nMSG
allow	git commit -m "$(cat <<'EOF'\nmention -n and --no-verify\nEOF\n)"
CASES
  # file_exit <hook> <path> <content> - the hook's exit code after a write to path.
  file_exit() {
    mkdir -p "${2:h}"
    print -rn -- "$3" > "$2"
    node -e 'console.log(JSON.stringify({tool_input:{file_path:process.argv[1]}}))' "$2" \
      | node "$GUARDS/$1" >/dev/null 2>&1 && print 0 || print $?
  }
  # Keys are built by padding, so no key-shaped literal sits in this file.
  pad=""
  while IFS=$'\t' read -r want hook file content; do
    content=${content//\\n/$'\n'}
    got=$(file_exit "$hook" "$GDIR/$file" "$content")
    [[ "$got" == "$want" ]] || { fail "$hook on $file: exit $got, want $want"; guard_bad=1 }
  done <<CASES
0	validate-written-file.mjs	tsconfig.json	{\n  // comment\n  "compilerOptions": {}\n}
0	validate-written-file.mjs	.vscode/settings.json	{\n  // comment\n  "a": 1\n}
0	validate-written-file.mjs	notes.jsonc	{\n  // don't touch\n  "a": [1]\n}
0	validate-written-file.mjs	good.json	{"a": "it's"}
2	validate-written-file.mjs	bad.jsonc	{\n  // ok\n  "a": [1\n}
2	validate-written-file.mjs	bad.json	{"a": 1,}
2	scan-secrets.mjs	proj.env	OPENAI_API_KEY=sk-proj-${(l:60::Ab3_:)pad}
2	scan-secrets.mjs	legacy.env	OPENAI_API_KEY=sk-${(l:48::Ab3:)pad}
0	scan-secrets.mjs	prose.md	use the sk-learn style and task-runner names
CASES
  (( guard_bad )) || pass "hook guards catch what they should and let through what they should"
fi

# --- evaluation results are local state, not distributed source ---
if command -v python3 >/dev/null 2>&1; then
  EVALREPO=$(scratch_repo keeper); CLEANUP+=("$EVALREPO")
  EVALBIN=$(mktemp -d); CLEANUP+=("$EVALBIN")
  mkdir -p "$EVALREPO/evals"
  print -r -- $'expected\trequest\nkeeper\tExercise the fixture workflow\nnone\tWhat is a variable?' > "$EVALREPO/evals/routing.tsv"
  print -r -- $'#!/bin/sh\nprintf \'["keeper", "none"]\\n\'' > "$EVALBIN/codex"
  chmod +x "$EVALBIN/codex"
  ln -s "$(command -v python3)" "$EVALBIN/python3"
  eval_out=$(PATH="$EVALBIN:/usr/bin:/bin" REPO_ROOT="$EVALREPO" "$SCRIPTS/evals" --judge=codex)
  if [[ "$eval_out" == *"2/2 requests routed as labeled"* && -f "$EVALREPO/local/evals/last-run.tsv" && ! -e "$EVALREPO/evals/last-run.tsv" ]]; then
    pass "evaluation creates its output under local without an existing local directory"
  else
    fail "evaluation wrote into distributed source or failed to create local results"
  fi
  cp "$REAL_REPO/.gitignore" "$EVALREPO/"
  git -C "$EVALREPO" init -q
  if git -C "$EVALREPO" check-ignore -q local/evals/last-run.tsv; then
    pass "evaluation output is excluded by the shipped Git ignore policy"
  else
    fail "evaluation output is not ignored"
  fi
else
  print -r -- "SKIP: evaluation output test (python3 not installed)"
fi

# --- behavior eval: offline fixtures gate the scorer; the live path runs on a fake CLI ---
if command -v python3 >/dev/null 2>&1 && python3 -c 'import tomllib' 2>/dev/null; then
  if beh_out=$("$SCRIPTS/evals" --behavior 2>&1); then
    pass "behavior eval scores every recorded fixture as its expect file says"
  else
    fail "behavior eval fixtures disagree with their checks: ${beh_out:0:400}"
  fi
  BEHREPO=$(scratch_repo keeper); CLEANUP+=("$BEHREPO")
  BEHBIN=$(mktemp -d); CLEANUP+=("$BEHBIN")
  mkdir -p "$BEHREPO/evals/behavior/probe/fixtures/hit" "$BEHREPO/evals/behavior/probe/fixtures/miss"
  print -r -- $'skill = "keeper"\nprompt = "Name the trap."\n[[check]]\nid = "names-trap"\nkind = "trap"\nabout = "says trap"\nwhere = "answer"\nall = [\'planted trap\']' > "$BEHREPO/evals/behavior/probe/scenario.toml"
  print -r -- "The planted trap is here." > "$BEHREPO/evals/behavior/probe/fixtures/hit/answer.md"
  print -r -- "names-trap" > "$BEHREPO/evals/behavior/probe/fixtures/hit/expect"
  print -r -- "Looks fine." > "$BEHREPO/evals/behavior/probe/fixtures/miss/answer.md"
  : > "$BEHREPO/evals/behavior/probe/fixtures/miss/expect"
  if REPO_ROOT="$BEHREPO" "$SCRIPTS/evals" --behavior >/dev/null 2>&1; then
    pass "behavior eval accepts fixtures that agree with their checks"
  else
    fail "behavior eval rejected agreeing fixtures"
  fi
  print -r -- "names-trap" > "$BEHREPO/evals/behavior/probe/fixtures/miss/expect"
  if REPO_ROOT="$BEHREPO" "$SCRIPTS/evals" --behavior >/dev/null 2>&1; then
    fail "behavior eval accepted a fixture its check scores differently"
  else
    pass "behavior eval fails when a fixture and its check disagree"
  fi
  : > "$BEHREPO/evals/behavior/probe/fixtures/miss/expect"
  print -r -- $'#!/bin/sh\nprintf \'{"type":"system","subtype":"init","model":"fake-model"}\\n{"type":"result","result":"The planted trap is here."}\\n\'' > "$BEHBIN/claude"
  chmod +x "$BEHBIN/claude"
  PATH="$BEHBIN:$PATH" REPO_ROOT="$BEHREPO" "$SCRIPTS/evals" --behavior --live --targets=claude:fake --arms=bare --runs=1 >/dev/null 2>&1 || true
  beh_res="$BEHREPO/local/evals/behavior/last-run.tsv"
  if [[ -f "$beh_res" ]] && grep -q "^# behavior eval" "$beh_res" \
    && grep -qF $'probe\tclaude\tfake-model\tbare\t1\tnames-trap\ttrap\t1\t1.00' "$beh_res"; then
    pass "behavior eval live run records harness, model, arm, runs, and pass rate"
  else
    fail "behavior eval live run did not record the expected result row"
  fi
  # Fake hermes: records the skills.external_dirs it was given, fires the skill only when a dir was set.
  mkdir -p "$HOME/.hermes"
  print -r -- "model: {default: fake-qwen}" > "$HOME/.hermes/config.yaml"
  print -r -- '#!/bin/sh
case "$1" in
  config) [ "$2" = set ] && printf "%s" "$4" > "$HERMES_HOME/dirs"; [ "$2" = get ] && echo fake-qwen; exit 0 ;;
  gateway) exit 0 ;;
esac
printf "%s\n" "{\"type\":\"tool_use\",\"name\":\"terminal\",\"input\":{\"command\":\"node probe.js\"}}"
grep -q skills "$HERMES_HOME/dirs" && printf "%s\n" "{\"type\":\"tool_use\",\"name\":\"skill_view\",\"input\":{\"name\":\"keeper\"}}"
printf "%s\n" "{\"type\":\"result\",\"text\":\"The planted trap is here.\"}"' > "$BEHBIN/hermes"
  chmod +x "$BEHBIN/hermes"
  rm -rf "$BEHREPO/local"  # the claude run above may hold this second's stamp dir
  env -u HERMES_HOME PATH="$BEHBIN:$PATH" REPO_ROOT="$BEHREPO" "$SCRIPTS/evals" --behavior --live --targets=hermes:default --arms=bare,library --runs=1 >/dev/null 2>&1 || true
  hermes_cmds=$(cat "$BEHREPO"/local/evals/behavior/*/probe.hermes-default.bare.1/commands.txt 2>/dev/null || true)
  if grep -qF $'probe\thermes\tfake-qwen\tbare\t1\tnames-trap\ttrap\t1\t1.00' "$beh_res" \
    && grep -qF $'probe\thermes\tfake-qwen\tlibrary\t1\tfired:keeper\tskill\t1\t1.00' "$beh_res" \
    && ! grep -qF $'bare\t1\tfired:keeper' "$beh_res" && [[ "$hermes_cmds" == "node probe.js" ]]; then
    pass "behavior eval hermes harness records answer, commands, and skills only in the library arm"
  else
    fail "behavior eval hermes harness did not record the expected rows: $(<"$beh_res")"
  fi
else
  print -r -- "SKIP: behavior eval tests (python3 3.11+ not installed)"
fi

# --- standalone install: the complete library and hooks share one snapshot ---
FULLREPO=$(mktemp -d); CLEANUP+=("$FULLREPO")
FULLHOME=$(mktemp -d); CLEANUP+=("$FULLHOME")
FULLBIN=$(mktemp -d); CLEANUP+=("$FULLBIN")
cp -R "$REAL_REPO/core" "$REAL_REPO/manifests" "$REAL_REPO/scripts" "$REAL_REPO/skills" "$REAL_REPO/extras" "$REAL_REPO/install" "$FULLREPO/"
cp "$FAKEBIN"/* "$FULLBIN/"
if command -v node >/dev/null 2>&1; then
  ln -s "$(command -v node)" "$FULLBIN/node"
  cp "$FAKEBIN/codex" "$FULLBIN/claude"
fi
if HOME="$FULLHOME" PATH="$FULLBIN:/usr/bin:/bin" REPO_ROOT="$FULLREPO" "$FULLREPO/install" >/dev/null 2>&1; then
  missing_skills=()
  for skill_dir in "$FULLREPO"/skills/*/(N); do
    skill_name="${${skill_dir%/}:t}"
    if ! diff -qr --exclude=.managed-by "${skill_dir%/}" "$FULLHOME/.agents/skills/$skill_name" >/dev/null 2>&1; then
      missing_skills+=("$skill_name")
    fi
  done
  if (( ${#missing_skills} == 0 )) && [[ -f "$FULLHOME/.agents/skills/written-voice/scripts/voice-check.py" ]]; then
    pass "standalone install deploys every skill and bundled resource from the checkout"
  else
    fail "standalone install omitted or changed skills: ${(j:, :)missing_skills}"
  fi
  snapshots=("$FULLREPO"/local/backups/*(N/))
  if (( ${#snapshots} == 1 )); then
    pass "one top-level install creates one rollback snapshot"
  else
    fail "one install created ${#snapshots} rollback snapshots"
  fi
  HOME="$FULLHOME" PATH="$FULLBIN:/usr/bin:/bin" REPO_ROOT="$FULLREPO" "$FULLREPO/install" >/dev/null 2>&1 || true
  snapshots=("$FULLREPO"/local/backups/*(N/))
  if (( ${#snapshots} == 1 )); then
    pass "a re-run with nothing new writes nothing and adds no snapshot"
  else
    fail "a no-op re-run added a snapshot, so rollback no longer undoes the install"
  fi
  if [[ -x "$FULLBIN/node" && ! -f "$FULLHOME/.claude/hooks/block-no-verify.mjs" ]]; then
    fail "standalone install did not include detected hooks"
  fi
  HOME="$FULLHOME" REPO_ROOT="$FULLREPO" "$FULLREPO/scripts/rollback" >/dev/null 2>&1
  remaining=("$FULLHOME"/.agents/skills/*/SKILL.md(N))
  if (( ${#remaining} == 0 )) && [[ ! -e "$FULLHOME/.codex/AGENTS.md" && ! -e "$FULLHOME/.claude/hooks/block-no-verify.mjs" ]]; then
    pass "one rollback removes the entire fresh installation including hooks"
  else
    fail "rollback left part of the fresh installation behind"
  fi
else
  fail "standalone install failed with only system tools and detected CLI fixtures"
fi

# --- ownership: every collision is reported before anything stops ---
SCRATCH=$(scratch_repo keeper second); CLEANUP+=("$SCRATCH")
CHOME=$(mktemp -d); CLEANUP+=("$CHOME")
for n in keeper second; do
  mkdir -p "$CHOME/.agents/skills/$n"
  print -r -- "foreign" > "$CHOME/.agents/skills/$n/SKILL.md"
done
out=$(HOME="$CHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" 2>&1 || true)
if [[ "$out" == *"skills/keeper"*"skills/second"* && "$out" == *"./install --dry-run --adopt"* ]]; then
  pass "a collision refusal lists every colliding skill and the adopt command"
else
  fail "collision refusal did not list every collision: ${out[-200,-1]}"
fi

# --- retired roots: a root the manifest drops is cleaned on the next deploy ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
RHOME=$(mktemp -d); CLEANUP+=("$RHOME")
HOME="$RHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
OLDROOT="$RHOME/.oldtool/skills"
mkdir -p "$OLDROOT/keeper" "$OLDROOT/theirs"
print -r -- "old copy" > "$OLDROOT/keeper/SKILL.md"
print -r -- "deployed by ai-workflow; removed by scripts/deploy when the repo drops it, or by scripts/uninstall" > "$OLDROOT/keeper/.managed-by"
print -r -- "someone else's" > "$OLDROOT/theirs/SKILL.md"
print -r -- "$OLDROOT" >> "$SCRATCH/local/state/skill-roots"
doctor_out=$(HOME="$RHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/doctor" 2>/dev/null || true)
[[ "$doctor_out" == *"retired"*"$OLDROOT"* ]] \
  && pass "doctor reports a retired root that still holds this repo's skills" \
  || fail "doctor did not report the retired root"
HOME="$RHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ ! -e "$OLDROOT/keeper" && -f "$OLDROOT/theirs/SKILL.md" ]] && ! grep -qxF "$OLDROOT" "$SCRATCH/local/state/skill-roots"; then
  pass "deploy removes this repo's skills from a retired root and keeps everyone else's"
else
  fail "retired root cleanup removed the wrong things or kept the receipt entry"
fi
mkdir -p "$OLDROOT/keeper"
print -r -- "deployed by ai-workflow; removed by scripts/deploy when the repo drops it, or by scripts/uninstall" > "$OLDROOT/keeper/.managed-by"
print -r -- "$OLDROOT" >> "$SCRATCH/local/state/skill-roots"
HOME="$RHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/uninstall" >/dev/null 2>&1 || true
if [[ ! -e "$OLDROOT/keeper" && ! -e "$RHOME/.agents/skills/keeper" && ! -e "$SCRATCH/local/state/skill-roots" ]]; then
  pass "uninstall reaches recorded roots the manifest no longer names"
else
  fail "uninstall missed a recorded root"
fi

# --- hooks: ownership is exact, bad settings stop early, symlinks survive ---
if command -v node >/dev/null 2>&1; then
  HREPO=$(scratch_repo keeper); CLEANUP+=("$HREPO")
  cp -R "$REAL_REPO/extras" "$HREPO/"
  KHOME=$(mktemp -d); CLEANUP+=("$KHOME")
  mkdir -p "$KHOME/.claude"
  print -r -- '{"hooks":{"PreToolUse":[{"matcher":"Bash","hooks":[{"type":"command","command":"my-wrapper '"$KHOME"'/.claude/hooks/scan-secrets.mjs"}]}]}}' > "$KHOME/.claude/settings.json"
  HOME="$KHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  if grep -q my-wrapper "$KHOME/.claude/settings.json" && grep -q block-no-verify "$KHOME/.claude/settings.json"; then
    pass "a user's hook that wraps one of ours is kept, not taken as ours"
  else
    fail "hooks install removed a user's hook that only mentions our script"
  fi

  bad_ok=1
  for bad in '[]' '{"hooks":[]}' '{"hooks":{"Stop":"x"}}' '{ // comment
}'; do
    BHOME=$(mktemp -d); CLEANUP+=("$BHOME")
    mkdir -p "$BHOME/.claude"
    print -r -- "$bad" > "$BHOME/.claude/settings.json"
    before=$(digest "$BHOME/.claude/settings.json")
    if HOME="$BHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1; then
      fail "hooks install reported success on unusable settings: $bad"; bad_ok=0
    elif [[ "$before" != "$(digest "$BHOME/.claude/settings.json")" || -e "$BHOME/.claude/hooks" ]]; then
      fail "unusable settings were changed or hooks were copied in unwired: $bad"; bad_ok=0
    fi
  done
  (( bad_ok )) && pass "unusable settings.json stops hooks install before anything is copied"

  RHOME=$(mktemp -d); CLEANUP+=("$RHOME")
  mkdir -p "$RHOME/.claude"
  print -r -- '{}' > "$RHOME/.claude/settings.json"
  chmod 444 "$RHOME/.claude/settings.json"
  if HOME="$RHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1; then
    fail "hooks install reported success writing a read-only settings.json"
  else
    pass "a settings.json that cannot be written fails the install"
  fi

  LHOME=$(mktemp -d); DOT=$(mktemp -d); CLEANUP+=("$LHOME" "$DOT")
  mkdir -p "$LHOME/.claude"
  print -r -- '{"model":"x"}' > "$DOT/settings.json"
  ln -s "$DOT/settings.json" "$LHOME/.claude/settings.json"
  HOME="$LHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  HOME="$LHOME" REPO_ROOT="$HREPO" "$SCRIPTS/rollback" >/dev/null 2>&1 || true
  if [[ -L "$LHOME/.claude/settings.json" && "$(<"$DOT/settings.json")" == '{"model":"x"}' ]]; then
    pass "rollback restores the content behind a symlinked settings.json and keeps the link"
  else
    fail "rollback lost the original content behind a symlinked settings.json"
  fi
else
  print -r -- "SKIP: hooks ownership and settings tests (node not installed)"
fi

# --- sync: a symlinked instruction file keeps its link and its mode ---
SHOME=$(mktemp -d); DOT=$(mktemp -d); CLEANUP+=("$SHOME" "$DOT")
mkdir -p "$SHOME/.codex"
print -r -- "dotfiles copy" > "$DOT/AGENTS.md"
chmod 640 "$DOT/AGENTS.md"
ln -s "$DOT/AGENTS.md" "$SHOME/.codex/AGENTS.md"
HOME="$SHOME" PATH="$BASEPATH" "$SCRIPTS/sync" >/dev/null 2>&1 || true
if [[ -L "$SHOME/.codex/AGENTS.md" ]] && grep -q "MANAGED BY" "$DOT/AGENTS.md" && [[ "$(ls -l "$DOT/AGENTS.md" | cut -c1-10)" == "-rw-r-----" ]]; then
  pass "sync writes through a symlinked instruction file and keeps its mode"
else
  fail "sync replaced a symlinked instruction file or changed its mode"
fi

# --- update: no upstream stops before anything runs ---
UREPO=$(mktemp -d); CLEANUP+=("$UREPO")
git -C "$UREPO" init -q
if out=$(REPO_ROOT="$UREPO" "$SCRIPTS/update" --adopt --dry-run 2>&1); then
  fail "update ran with no upstream branch"
elif [[ "$out" == *"no upstream branch"* ]]; then
  pass "update with no upstream stops with a clear error, dry run or not"
else
  fail "update failed without saying why: ${out:0:120}"
fi

# --- receipt: another spelling of a live root, or a non-skills path, is inert ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
AHOME=$(mktemp -d); CLEANUP+=("$AHOME")
HOME="$AHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
mkdir -p "$AHOME/Documents/empty dir" "$AHOME/Projects/mine/keeper"
cp "$AHOME/.agents/skills/keeper/.managed-by" "$AHOME/Projects/mine/keeper/"
print -r -- "$AHOME/.agents/skills/
$AHOME/.agents/./skills
$AHOME/Documents/empty dir
$AHOME/Projects/mine
relative/skills" >> "$SCRATCH/local/state/skill-roots"
HOME="$AHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -d "$AHOME/.agents/skills/keeper" ]]; then
  pass "a receipt entry spelling a live root differently does not retire it"
else
  fail "a trailing slash or ./ in the receipt pruned the live skill root"
fi
if [[ -d "$AHOME/Documents/empty dir" && -d "$AHOME/Projects/mine/keeper" ]]; then
  pass "receipt entries that are not absolute */skills paths are ignored"
else
  fail "a receipt entry outside a skills root was pruned or removed"
fi

# --- deploy: a failed copy leaves the old skill whole and still ours ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
FHOME=$(mktemp -d); CLEANUP+=("$FHOME")
HOME="$FHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
print -r -- "unreadable" > "$SCRATCH/skills/keeper/blocked.md"
chmod 000 "$SCRATCH/skills/keeper/blocked.md"
HOME="$FHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
chmod 644 "$SCRATCH/skills/keeper/blocked.md"
staged=("$FHOME"/.agents/skills/.aiwf-staging.*(N))
if [[ -f "$FHOME/.agents/skills/keeper/.managed-by" && ! -e "$FHOME/.agents/skills/keeper/blocked.md" ]] && (( ${#staged} == 0 )); then
  pass "a failed skill copy keeps the previous copy and leaves no staging behind"
else
  fail "a failed skill copy left a partial or unmarked skill"
fi
if HOME="$FHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 && [[ -f "$FHOME/.agents/skills/keeper/blocked.md" ]]; then
  pass "the next deploy after a failed copy completes without a collision"
else
  fail "a failed copy blocked the next deploy"
fi

# --- deploy: an executable bit change reaches the deployed copy ---
chmod +x "$SCRATCH/skills/keeper/SKILL.md"
HOME="$FHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ -x "$FHOME/.agents/skills/keeper/SKILL.md" ]]; then
  pass "a mode-only change in a skill is deployed"
else
  fail "deploy treated a mode-only change as unchanged"
fi

# --- rollback: the latest snapshot is chosen numerically ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
NHOME=$(mktemp -d); CLEANUP+=("$NHOME")
AIWF_BACKUP_TS=20261030-120000-9 HOME="$NHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
print -r -- "edit" >> "$SCRATCH/skills/keeper/SKILL.md"
AIWF_BACKUP_TS=20261030-120000-10 HOME="$NHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
HOME="$NHOME" REPO_ROOT="$SCRATCH" "$SCRIPTS/rollback" >/dev/null 2>&1 || true
if [[ -d "$NHOME/.agents/skills/keeper" ]] && ! grep -q '^edit$' "$NHOME/.agents/skills/keeper/SKILL.md"; then
  pass "rollback undoes the newest run when run ids differ in digit count"
else
  fail "rollback picked an older snapshot by lexical order"
fi

# --- retired roots: a symlinked skills root is still retired by its own name ---
SCRATCH=$(scratch_repo keeper); CLEANUP+=("$SCRATCH")
YHOME=$(mktemp -d); CLEANUP+=("$YHOME")
mkdir -p "$YHOME/dotfiles/bob-lib" "$YHOME/.bob"
ln -s "$YHOME/dotfiles/bob-lib" "$YHOME/.bob/skills"
HOME="$YHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
grep -v '^bob' "$SCRATCH/manifests/skill-dest-roots.tsv" > "$SCRATCH/manifests/roots.tmp" && mv "$SCRATCH/manifests/roots.tmp" "$SCRATCH/manifests/skill-dest-roots.tsv"
HOME="$YHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" >/dev/null 2>&1 || true
if [[ ! -e "$YHOME/dotfiles/bob-lib/keeper" && -L "$YHOME/.bob/skills" ]]; then
  pass "a symlinked skills root the manifest drops is cleaned through the link"
else
  fail "a symlinked retired root kept this repo's skills or lost its link"
fi

# --- dry run: leftover staging is reported, not removed ---
mkdir -p "$YHOME/.agents/skills/.aiwf-staging.abc123/sub"
HOME="$YHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/deploy" --dry-run >/dev/null 2>&1 || true
if [[ -d "$YHOME/.agents/skills/.aiwf-staging.abc123/sub" ]]; then
  pass "deploy --dry-run removes nothing, leftover staging included"
else
  fail "deploy --dry-run deleted leftover staging"
fi
HOME="$YHOME" PATH="$BASEPATH" REPO_ROOT="$SCRATCH" "$SCRIPTS/uninstall" >/dev/null 2>&1 || true
if [[ ! -e "$YHOME/.agents/skills/.aiwf-staging.abc123" ]]; then
  pass "uninstall removes leftover staging"
else
  fail "uninstall left staging behind"
fi

if command -v node >/dev/null 2>&1; then
  HREPO=$(scratch_repo keeper); CLEANUP+=("$HREPO")
  cp -R "$REAL_REPO/extras" "$HREPO/"
  # --- rollback: a dangling settings.json link's created target is removed ---
  GHOME=$(mktemp -d); CLEANUP+=("$GHOME")
  mkdir -p "$GHOME/.claude" "$GHOME/dotfiles"
  ln -s "$GHOME/dotfiles/claude-settings.json" "$GHOME/.claude/settings.json"
  HOME="$GHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  HOME="$GHOME" REPO_ROOT="$HREPO" "$SCRIPTS/rollback" >/dev/null 2>&1 || true
  if [[ -L "$GHOME/.claude/settings.json" && ! -e "$GHOME/dotfiles/claude-settings.json" ]]; then
    pass "rollback removes the file a dangling settings link was pointed at"
  else
    fail "rollback left the created target of a dangling settings link"
  fi

  # --- a failed backup stops the write it was protecting ---
  PHOME=$(mktemp -d); CLEANUP+=("$PHOME")
  HOME="$PHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" install >/dev/null 2>&1 || true
  before=$(digest "$PHOME/.claude/settings.json")
  rm -rf "$HREPO/local/backups"; print -r -- "not a directory" > "$HREPO/local/backups"
  if HOME="$PHOME" REPO_ROOT="$HREPO" "$SCRIPTS/hooks" uninstall >/dev/null 2>&1; then
    fail "hooks uninstall succeeded although its backup could not be written"
  elif [[ "$before" == "$(digest "$PHOME/.claude/settings.json")" ]]; then
    pass "a backup that cannot be written stops the change it protects"
  else
    fail "settings.json was rewritten after its backup failed"
  fi
  rm -f "$HREPO/local/backups"
fi

# --- install: a missing required tool stops the install with a fix ---
NOZSH=$(mktemp -d); CLEANUP+=("$NOZSH")
for c in dirname sed git; do
  p=$(command -v "$c") && ln -s "$p" "$NOZSH/$c"
done
if out=$(PATH="$NOZSH" /bin/sh "$REAL_REPO/install" --dry-run 2>&1); then
  fail "install continued without zsh"
elif [[ "$out" == *"MISSING  zsh"* ]]; then
  pass "install stops when zsh is missing and names the fix"
else
  fail "install failed without naming the missing tool: ${out:0:120}"
fi

# --- overlap across installed roots: plugin skills are labeled <plugin>:<skill> ---
if command -v python3 >/dev/null 2>&1; then
  OVL=$(mktemp -d); CLEANUP+=("$OVL")
  mkdir -p "$OVL/ours/debugging" "$OVL/cache/vendor/1.2.3/skills/debug"
  print -r -- $'---\nname: debugging\ndescription: Explains a failing test, exception, or regression before fixing it\n---' > "$OVL/ours/debugging/SKILL.md"
  print -r -- $'---\nname: debug\ndescription: Explains a failing test, exception, or regression before fixing it\n---' > "$OVL/cache/vendor/1.2.3/skills/debug/SKILL.md"
  if python3 "$SCRIPTS/desc-overlap.py" "$OVL/ours" 0.5 "$OVL/cache" | grep -q '^debugging / vendor:debug:'; then
    pass "overlap check labels a plugin skill by plugin, skipping the version folder"
  else
    fail "overlap check missed or mislabeled a plugin skill collision"
  fi
  VAR=$(mktemp -d); CLEANUP+=("$VAR")
  mkdir -p "$VAR/evals/behavior/probe"
  print -r -- $'prompt = "base"\n[[check]]\nid = "c"\nkind = "trap"\nabout = "x"\nwhere = "answer"\nall = [\'x\']\n[variants]\npressure = "hurry"' > "$VAR/evals/behavior/probe/scenario.toml"
  if REPO_ROOT="$VAR" python3 -c 'import importlib.util as u,sys;s=u.spec_from_file_location("b",sys.argv[1]);m=u.module_from_spec(s);s.loader.exec_module(m);ids=[(x["id"],x["prompt"]) for x in m.load()];sys.exit(ids!=[("probe","base"),("probe+pressure","hurry")])' "$SCRIPTS/behavior-eval.py"; then
    pass "behavior eval expands a [variants] prompt into its own scenario with the base checks"
  else
    fail "behavior eval did not expand [variants]"
  fi
fi

echo
if (( FAIL )); then
  echo "one or more tests FAILED"
  exit 1
else
  echo "all tests passed"
fi
