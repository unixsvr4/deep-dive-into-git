#!/usr/bin/env bash
# Lab 05 — the same repository with the reference backend Git 3.0 will default
# to, and the one-liner from lab 04 run against it.
#
# Requires git 2.45 or newer (--ref-format landed in 2.45, May 2024).
# Debian bookworm ships 2.39 and cannot run this lab.
set -euo pipefail
git init -q --ref-format=reftable "$(mktemp -d)/probe" 2>/dev/null || {
  echo "this git has no reftable backend: $(git --version)"; exit 0; }
cd "$(mktemp -d)"
git init -q --ref-format=reftable .
printf 'Hello, world!\n' > f && git add f
git -c user.name=A -c user.email=a@a commit -qm first

echo "ref format      : $(git rev-parse --show-ref-format)"
echo "commit          : $(git rev-parse HEAD)"
echo
echo "== the files are gone =="
echo -n ".git/refs/heads/main : "; cat .git/refs/heads/main 2>&1 || true
echo "ls .git/refs         : $(ls -A .git/refs 2>/dev/null | tr '\n' ' ')"
echo ".git/refs/heads is now a $(file -b .git/refs/heads), $(wc -c < .git/refs/heads | tr -d ' ') bytes:"
echo "  $(cat .git/refs/heads)"
echo "  (a branch file used to be 40 hex characters and a newline: also 41 bytes)"
echo "ls .git/reftable     :"; ls -l .git/reftable | sed 's/^/  /'
echo
echo "== .git/HEAD still exists, still parses, and is a trap =="
echo ".git/HEAD            : $(cat .git/HEAD)"
echo "  cut -d/ -f3- .git/HEAD          -> $(cut -d/ -f3- .git/HEAD)"
echo "  sed -e 's,.*/\\(.*\\),\\1,' .git/HEAD -> $(sed -e 's,.*/\(.*\),\1,' .git/HEAD)"
echo
echo "== the plumbing is unmoved =="
echo "  git rev-parse --abbrev-ref HEAD -> $(git rev-parse --abbrev-ref HEAD)"
echo "  git symbolic-ref HEAD           -> $(git symbolic-ref HEAD)"
echo "  git for-each-ref                -> $(git for-each-ref)"
echo
echo "The script does not fail. It returns .invalid and carries on."
