#!/usr/bin/env bash
# Lab 06 — SHA-256 object IDs, and the migration that has not happened.
#
# SHA-1 was publicly broken in February 2017, sixteen months after this talk.
# git gained a SHA-256 object format in 2.29 (October 2020). This lab measures
# how far that migration has actually got.
set -euo pipefail
W=$(mktemp -d); cd "$W"

git init -q --object-format=sha256 sha256repo
git init -q --object-format=sha1   sha1repo
for r in sha256repo sha1repo; do
  ( cd "$r" && printf 'Hello, world!\n' > file1.txt
    echo "$r: extensions.objectformat = $(git config --default sha1 --get extensions.objectformat)"
    echo "  git hash-object file1.txt -> $(git hash-object file1.txt)"
    git add -A && git -c user.name=A -c user.email=a@a commit -qm first
    echo "  commit id length          -> $(git rev-parse HEAD | wc -c | tr -d ' ') chars incl newline" )
done

echo
echo "== the same fourteen bytes, two different names =="
echo "  sha1  : $(cd sha1repo   && git hash-object file1.txt)"
echo "  sha256: $(cd sha256repo && git hash-object file1.txt)"

echo
echo "== can they talk to each other? =="
echo -n "  sha256 fetching from sha1 : "; ( cd sha256repo && git fetch ../sha1repo   2>&1 | head -1 || true )
echo -n "  sha1 fetching from sha256 : "; ( cd sha1repo   && git fetch ../sha256repo 2>&1 | head -1 || true )

echo
echo "git's SHA-1 implementation in this build:"
git version --build-options | grep -E '^(SHA-1|SHA-256|default-hash|default-ref-format):' | sed 's/^/  /'
