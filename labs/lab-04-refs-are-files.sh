#!/usr/bin/env bash
# Lab 04 — a branch is a file containing forty hex characters and a newline.
#
# This is the half of the talk that every build script in the world quietly
# depends on, usually without meaning to. Lab 05 is what happens to it.
set -euo pipefail
cd "$(mktemp -d)"
git init -q --ref-format=files .
printf 'Hello, world!\n' > f && git add f
git -c user.name=A -c user.email=a@a commit -qm first
B=$(git rev-parse --abbrev-ref HEAD)
echo "ref format      : $(git rev-parse --show-ref-format)"
echo ".git/HEAD       : $(cat .git/HEAD)"
echo ".git/refs/heads/$B : $(cat ".git/refs/heads/$B")"
echo "size            : $(wc -c < ".git/refs/heads/$B") bytes"
echo
echo "the one-liner everyone has in a Makefile:"
echo "  cut -d/ -f3- .git/HEAD   -> $(cut -d/ -f3- .git/HEAD)"
echo "  git rev-parse --abbrev-ref HEAD -> $(git rev-parse --abbrev-ref HEAD)"
echo
echo "Both answer correctly. That is the whole problem: for twenty years"
echo "there has been no reason to prefer one over the other."
