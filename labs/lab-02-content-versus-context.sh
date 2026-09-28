#!/usr/bin/env bash
# Lab 02 — why the blob reproduces across eleven years and the commit cannot.
#
# The slide also shows "commit 03ce18e..." and "commit 69a846f...". Those are
# not reproducible from anything on the slide, and never will be. A commit
# object hashes the tree, the parents, the author name and email, the
# committer name and email, two timestamps with timezones, and the message.
# A blob hashes the bytes. One is content, the other is context.
set -euo pipefail
cd "$(mktemp -d)"
git init -q .
printf 'Hello, world!\n' > file1.txt
git update-index --add file1.txt
TREE=$(git write-tree)
echo "tree (same for everyone, forever): $TREE"
echo
echo "same tree, same message, three different contexts:"
for who in "Alice:alice@example.com:2015-10-05T10:00:00+0200" \
           "Alice:alice@example.com:2015-10-05T10:00:01+0200" \
           "Bob:bob@example.com:2015-10-05T10:00:00+0200"; do
  name=$(echo "$who" | cut -d: -f1)
  mail=$(echo "$who" | cut -d: -f2)
  ts=$(echo "$who" | cut -d: -f3-)
  C=$(GIT_AUTHOR_NAME="$name" GIT_AUTHOR_EMAIL="$mail" GIT_AUTHOR_DATE="$ts" \
      GIT_COMMITTER_NAME="$name" GIT_COMMITTER_EMAIL="$mail" GIT_COMMITTER_DATE="$ts" \
      git commit-tree "$TREE" -m "first")
  printf '  %-34s -> %s\n' "$name $ts" "$C"
done
echo
echo "A one second difference in a timestamp changes the commit ID completely."
echo "That is why a 2015 blob ID is checkable in 2026 and a 2015 commit ID is not."
