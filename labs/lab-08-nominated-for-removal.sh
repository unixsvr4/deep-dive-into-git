#!/usr/bin/env bash
# Lab 08 — of the commands from the talk's era, what is actually going away.
set -euo pipefail
cd "$(mktemp -d)"; git init -q .; printf x > f; git add f
git -c user.name=A -c user.email=a@a commit -qm x >/dev/null

echo "== plumbing from the talk, present in $(git --version | sed 's/git version //') =="
miss=0
for c in hash-object cat-file update-index write-tree commit-tree read-tree ls-tree \
         ls-files rev-parse rev-list symbolic-ref update-ref show-ref for-each-ref \
         verify-pack count-objects unpack-objects pack-objects prune fsck gc reflog \
         merge-base diff-tree mktree; do
  if git help "$c" >/dev/null 2>&1; then printf '  %-15s present\n' "$c"; else printf '  %-15s MISSING\n' "$c"; miss=$((miss+1)); fi
done
echo "  missing: $miss"

echo
echo "== what Git 3.0 removes (BreakingChanges.html) =="
echo -n "  git whatchanged    : "; { git whatchanged 2>&1 || true; } | head -1
echo -n "  git pack-redundant : "; { git pack-redundant --all </dev/null 2>&1 || true; } | head -1
echo "  also going: commit grafts, .git/branches/, .git/remotes/, name-rev --stdin"
