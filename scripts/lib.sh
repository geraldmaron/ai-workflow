#!/usr/bin/env zsh
# Shared functions for ai-workflow scripts. Sourced, not executed directly.

set -euo pipefail

# Location of these scripts, independent of REPO_ROOT (which is overridable so
# tests can point the content at a scratch tree while still exercising real code).
SCRIPT_DIR="$(cd "$(dirname "${(%):-%x}")" && pwd)"
REPO_ROOT="${REPO_ROOT:-$(cd "$SCRIPT_DIR/.." && pwd)}"
CORE_FILE="$REPO_ROOT/core/GLOBAL.md"
LOCAL_OVERRIDE="$REPO_ROOT/local/GLOBAL.local.md"
MANIFEST="$REPO_ROOT/manifests/managed-files.tsv"
BACKUP_DIR="$REPO_ROOT/local/backups"
SKILLS_DIR="$REPO_ROOT/skills"
SKILL_MANIFEST="$REPO_ROOT/manifests/skill-dest-roots.tsv"
# Every skill root this checkout has deployed to, one absolute path per line.
# It lets deploy and uninstall reach a root the manifest no longer names.
ROOTS_RECEIPT="$REPO_ROOT/local/state/skill-roots"
MARK_BEGIN="<!-- ai-workflow:begin -->"
MARK_END="<!-- ai-workflow:end -->"
MANAGED_MARKER="deployed by ai-workflow; removed by scripts/deploy when the repo drops it, or by scripts/uninstall"
MANAGED_HEADER="<!-- MANAGED BY ai-workflow; edit core/GLOBAL.md, not this file; sync: ai-workflow/scripts/sync -->"
# shortcut: installs made before the rename from ai-workflow-config carry these
# strings; deploy rewrites them to the current ones. Drop once every machine has re-run install.
LEGACY_MARK_BEGIN="<!-- ai-workflow-config:begin -->"
LEGACY_MARK_END="<!-- ai-workflow-config:end -->"
LEGACY_MANAGED_MARKER="deployed by ai-workflow-config; removed by scripts/deploy when the repo drops it, or by scripts/uninstall"
LEGACY_MANAGED_HEADER="<!-- MANAGED BY ai-workflow-config;"

log()  { print -r -- "$*" >&2 }
die()  { print -r -- "error: $*" >&2; exit 1 }

# Render the content that should appear in any managed destination.
render_core() {
  local out="$MANAGED_HEADER"$'\n\n'"$(<"$CORE_FILE")"
  if [[ -f "$LOCAL_OVERRIDE" ]]; then
    out+=$'\n\n'"$(<"$LOCAL_OVERRIDE")"
  fi
  print -r -- "$out"
}

# Every script in one run shares a snapshot directory, so one rollback undoes
# the whole run. Exported so child scripts (deploy -> sync) join the same one.
export AIWF_BACKUP_TS="${AIWF_BACKUP_TS:-$(date +%Y%m%d-%H%M%S)-$$}"

# link_target <symlink> - the absolute path a symlink resolves to, even when
# that path does not exist yet (zsh's :A stops at a dangling link).
link_target() {
  local link="$1" dest
  [[ -e "$link" ]] && { print -r -- "${link:A}"; return }
  dest=$(readlink "$link")
  [[ "$dest" == /* ]] || dest="${link:h}/$dest"
  print -r -- "${dest:h:A}/${dest:t}"
}

# backup_path <path> [through|link] - record the pre-run state of a file or directory before
# anything writes to it or removes it. The snapshot's index.tsv maps each saved
# copy to its original path, so rollback never has to guess. A path that does
# not exist yet is recorded as '-', which tells rollback to remove what the run
# created. Only the first call per path in a run counts: that is the pre-run
# state; later calls in the same run would record the run's own writes.
backup_path() {
  local target="$1"
  # A symlink to a file (a dotfiles manager's settings.json, say) is written
  # through, so its target is what changes: record and save the target.
  # "through": the caller writes through the link, so a dangling link's target
  # is what gets created and is recorded as new. "link": the caller removes the
  # link itself. A symlinked directory is always replaced, so its link is kept.
  case "${2:-}" in
    link) ;;
    through) [[ -L "$target" && ! -d "$target" ]] && target=$(link_target "$target") ;;
    *) [[ -L "$target" && -f "$target" ]] && target=$(link_target "$target") ;;
  esac
  local dest_dir="$BACKUP_DIR/$AIWF_BACKUP_TS"
  local index="$dest_dir/index.tsv"
  # Every step is checked explicitly: callers run inside conditions where
  # set -e does not apply, and a write must never follow a failed backup.
  local fail="could not back up $target to $dest_dir; nothing was changed"
  mkdir -p "$dest_dir" || die "$fail"
  if [[ -f "$index" ]] && awk -F'\t' -v p="$target" '$2==p {found=1} END {exit !found}' "$index"; then
    return 0
  fi
  if [[ ! -e "$target" && ! -L "$target" ]]; then
    print -r -- "-"$'\t'"$target" >> "$index" || die "$fail"
    return 0
  fi
  local n=1 saved
  if [[ -f "$index" ]]; then
    n=$(( $(wc -l < "$index") + 1 ))
  fi
  saved="$n-${target:t}"
  cp -Rp "$target" "$dest_dir/$saved" || die "$fail"
  print -r -- "$saved"$'\t'"$target" >> "$index" || die "$fail"
  log "backed up $target -> $dest_dir/$saved"
}

# Write content to a destination atomically (temp file + mv).
atomic_write() {
  local target="$1" content="$2"
  # Replace the file a symlink points to, not the symlink.
  [[ -L "$target" ]] && target=$(link_target "$target")
  local dir
  dir=$(dirname "$target")
  mkdir -p "$dir"
  local tmp
  tmp=$(mktemp "${dir}/.aiwf.XXXXXX")
  print -r -- "$content" > "$tmp"
  # mktemp creates 0600; keep the replaced file's mode, or the umask default.
  local mode
  if [[ -e "$target" ]]; then
    zmodload -F zsh/stat b:zstat
    mode=$(zstat -L +mode "$target")
    mode=$(( mode & 8#7777 ))
  else
    mode=$(( 8#666 & ~8#$(umask) ))
  fi
  chmod "$(printf '%o' "$mode")" "$tmp"
  mv "$tmp" "$target"
}

# Rewrite pre-rename region markers to the current ones.
legacy_to_current() {
  local c="$1"
  c="${c//$LEGACY_MARK_BEGIN/$MARK_BEGIN}"
  print -r -- "${c//$LEGACY_MARK_END/$MARK_END}"
}

# Replace only the region between MARK_BEGIN/MARK_END in a file, preserving
# everything else. Creates the file with just the marked region if absent.
# Refuses a file whose markers are duplicated or unpaired: guessing which region
# is ours would either clobber hand-written text or append a second copy.
render_marked_region() {
  local target="$1" new_body="$2"
  if [[ ! -f "$target" ]]; then
    print -r -- "$MARK_BEGIN"$'\n'"$new_body"$'\n'"$MARK_END"
    return 0
  fi
  local content begins ends
  content=$(legacy_to_current "$(<"$target")")
  begins=$(print -r -- "$content" | grep -cF -- "$MARK_BEGIN" || true)
  ends=$(print -r -- "$content" | grep -cF -- "$MARK_END" || true)
  if (( begins > 1 || ends > 1 || begins != ends )); then
    die "$target has $begins begin and $ends end markers; expected one of each. Fix the file by hand, then re-run."
  fi
  if (( begins == 1 )); then
    local before after
    before="${content%%$MARK_BEGIN*}"
    after="${content#*$MARK_END}"
    print -r -- "${before}${MARK_BEGIN}"$'\n'"$new_body"$'\n'"${MARK_END}${after}"
  else
    # No existing markers: append a new managed region, preserve everything above.
    print -r -- "${content}"$'\n\n'"$MARK_BEGIN"$'\n'"$new_body"$'\n'"$MARK_END"
  fi
}

# Compute what a write in the given mode would produce.
render_for_mode() {
  local mode="$1" target="$2" core_content="$3"
  case "$mode" in
    wholesale)      print -r -- "$core_content" ;;
    marked-region)   render_marked_region "$target" "$core_content" ;;
    manual)          print -r -- "$core_content" ;;
    *) die "unknown mode: $mode" ;;
  esac
}

# Read the manifest, skipping header/comments/blank lines.
# Emits: tool<TAB>detect<TAB>destination<TAB>mode
manifest_rows() {
  tail -n +2 "$MANIFEST" | grep -v '^\s*#' | grep -v '^\s*$'
}

# Every root the skills library deploys to, gated by the same tool-detection
# expressions the core-file manifest uses (reused, not duplicated, so a tool
# detected once is detected the same way everywhere). Emits:
# label<TAB>detect<TAB>root: one row per configured destination, detected or
# not; callers filter with tool_detected.
skill_dest_rows() {
  tail -n +2 "$SKILL_MANIFEST" | grep -v '^\s*#' | grep -v '^\s*$'
}

# Detected skill destination roots only, one absolute path per line.
skill_dest_roots() {
  local label detect root
  while IFS=$'\t' read -r label detect root; do
    tool_detected "$detect" && expand_path "$root"
  done < <(skill_dest_rows)
}

# True (0) if the detect expression for a manifest row succeeds.
tool_detected() {
  local detect_expr="$1"
  eval "$detect_expr" >/dev/null 2>&1
}

# A generic marker filename is not proof that this installer owns a directory.
managed_skill() {
  [[ -f "$1/.managed-by" ]] || return 1
  local m="$(<"$1/.managed-by")"
  [[ "$m" == "$MANAGED_MARKER" || "$m" == "$LEGACY_MANAGED_MARKER" ]]
}

# True (0) if a deployed copy is ours and matches the repo source exactly,
# executable bits included (diff alone ignores modes).
skill_in_sync() {
  local src="$1" target="$2"
  # The current marker only, so a pre-rename copy is redeployed with the new one.
  [[ -f "$target/.managed-by" && "$(<"$target/.managed-by")" == "$MANAGED_MARKER" ]] && diff -qr --exclude=.managed-by "$src" "$target" >/dev/null 2>&1 \
    && [[ "$(cd "$src" && find . -type f -perm -u+x | sort)" == "$(cd "$target" && find . -type f ! -name .managed-by -perm -u+x | sort)" ]]
}

# canonical_root <path> - absolute, symlinks and ./.. resolved, no trailing
# slash, so two spellings of one directory compare equal.
canonical_root() {
  print -r -- "${1:A}"
}

# Every root the manifest names, canonical, whether or not its tool is detected.
manifest_skill_roots() {
  local label detect root
  while IFS=$'\t' read -r label detect root; do
    canonical_root "$(expand_path "$root")"
  done < <(skill_dest_rows)
}

# Receipt roots that are safe to act on: absolute paths whose last component is
# "skills", as written (a symlinked root keeps its own name here even when its
# target is named otherwise). Anything else in a hand-edited or damaged receipt
# is ignored, so it can never point a prune at an arbitrary directory.
recorded_skill_roots() {
  [[ -f "$ROOTS_RECEIPT" ]] || return 0
  local root
  while IFS= read -r root; do
    root="${root%%/#}"
    [[ "$root" == /* && "$root" == */skills ]] && print -r -- "$root"
  done < "$ROOTS_RECEIPT"
}

# Recorded roots the manifest no longer names, compared as resolved paths so
# that another spelling of a live root is never taken for a retired one.
# Skills this repo left there would otherwise keep loading with nothing to
# update them.
retired_skill_roots() {
  local current=("${(@f)$(manifest_skill_roots)}") root
  for root in "${(@fu)$(recorded_skill_roots)}"; do
    [[ -n "$root" ]] || continue
    (( ${current[(Ie)$(canonical_root "$root")]} )) || print -r -- "$root"
  done
}

# record_skill_root <root> - add a root to the receipt once, as spelled.
record_skill_root() {
  local root="${1%%/#}"
  mkdir -p "${ROOTS_RECEIPT:h}"
  grep -qxF -- "$root" "$ROOTS_RECEIPT" 2>/dev/null || print -r -- "$root" >> "$ROOTS_RECEIPT"
}

# forget_skill_root <root> - drop a root from the receipt.
forget_skill_root() {
  [[ -f "$ROOTS_RECEIPT" ]] || return 0
  local rest line kept=()
  while IFS= read -r line; do
    [[ "$line" == /* && "$(canonical_root "$line")" == "$(canonical_root "$1")" ]] || kept+=("$line")
  done < "$ROOTS_RECEIPT"
  rest=${(F)kept}
  if [[ -n "$rest" ]]; then print -r -- "$rest" > "$ROOTS_RECEIPT"; else rm -f "$ROOTS_RECEIPT"; fi
}

# Repo skill directories, sorted. Emits one absolute path per line.
skill_dirs() {
  local dir
  for dir in "$SKILLS_DIR"/*/(N); do
    print -r -- "${dir%/}"
  done
}

expand_path() {
  local p="$1"
  case "$p" in
    "~/"*) print -r -- "${HOME}/${p#\~/}" ;;
    "~"*)  die "unsupported ~user path in manifest: $p" ;;
    /*)    print -r -- "$p" ;;
    *)     print -r -- "$REPO_ROOT/$p" ;;
  esac
}
