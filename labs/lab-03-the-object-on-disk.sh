#!/usr/bin/env bash
# Lab 03 — what a loose object actually is on disk.
#
# The talk's core claim: an object is its type, a space, its length in bytes,
# a NUL, then the content; zlib-deflated; filed under the first two hex
# characters of its SHA-1. That was true in 2005, it was true on stage in
# 2015, and this lab checks it in 2026.
set -euo pipefail
cd "$(mktemp -d)"
git init -q .
printf 'Hello, world!\n' > file1.txt
ID=$(git hash-object -w file1.txt)
echo "object id      : $ID"
echo "path on disk   : .git/objects/${ID:0:2}/${ID:2}"
ls -l ".git/objects/${ID:0:2}/${ID:2}"
echo
echo "inflated bytes :"
python3 -c "import zlib,sys;print(repr(zlib.decompress(open(sys.argv[1],'rb').read())))" \
  ".git/objects/${ID:0:2}/${ID:2}"
echo
echo "git's own view :"
echo "  git cat-file -t $ID -> $(git cat-file -t "$ID")"
echo "  git cat-file -s $ID -> $(git cat-file -s "$ID")"
echo "  git cat-file -p $ID -> $(git cat-file -p "$ID")"
