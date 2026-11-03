#!/bin/bash
# Statusline: model | git branch | cwd basename | session cost (+ /clear nudge).
# Reads Claude Code hook JSON from stdin. No network calls; git lookups are
# local-only (branch --show-current) so a missing/non-repo dir is silent.

input=$(cat)

JQ=$(command -v jq) || { printf '%s' "status line needs jq"; exit 0; }

model=$(printf '%s' "$input" | "$JQ" -r '.model.display_name // "unknown"')
dir=$(printf '%s' "$input" | "$JQ" -r '.workspace.current_dir // .cwd // "."')
cost=$(printf '%s' "$input" | "$JQ" -r '.cost.total_cost_usd // empty')
big=$(printf '%s' "$input" | "$JQ" -r '.exceeds_200k_tokens // false')

branch=$(git -C "$dir" branch --show-current 2>/dev/null)
base=$(basename "$dir")

out="$model"
[ -n "$branch" ] && out="$out | $branch"
out="$out | $base"

if [ -n "$cost" ]; then
  # Tiered cost display: plain under $10, 💸 under $40, alarm above.
  fmt=$(printf '%.2f' "$cost" 2>/dev/null || echo "$cost")
  whole=${fmt%%.*}
  if [ "${whole:-0}" -ge 40 ] 2>/dev/null; then
    out="$out | 🚨 \$$fmt, /clear?"
  elif [ "${whole:-0}" -ge 10 ] 2>/dev/null; then
    out="$out | 💸 \$$fmt"
  else
    out="$out | \$$fmt"
  fi
fi

[ "$big" = "true" ] && out="$out | ctx>200k, /clear?"

printf '%s' "$out"
