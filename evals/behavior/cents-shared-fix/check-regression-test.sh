#!/bin/sh
# Hidden check, run in the finished workspace: a changed or added test passes on
# the fix and fails once money.js is put back the way it was.
changed=$({ git diff --name-only HEAD; git ls-files -o --exclude-standard; } | grep -E '(^|/)test/|\.test\.js$')
[ -n "$changed" ] || exit 1
node --test >/dev/null 2>&1 || exit 1
copy=$(mktemp -d)
trap 'rm -rf "$copy"' EXIT
cp -R . "$copy/"
cd "$copy" && git show HEAD:money.js > money.js && ! node --test >/dev/null 2>&1
