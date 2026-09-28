#!/usr/bin/env bash
# Lab 01 — recompute two object IDs off a 2015 conference slide.
#
# Slide 17 of Edward Thomson's "Deep Dive into Git" (GOTO Copenhagen 2015)
# shows an object graph with six abbreviated IDs. Two of them are derivable
# from information visible on the slide itself:
#
#     blob af5626b... file1.txt
#     tree d65b79a...
#
# file1.txt's content is not printed on the slide, but the blob ID is, and a
# blob ID is a hash of the content, so the content can be recovered by guess
# and check. It is "Hello, world!\n" (14 bytes). See RESEARCH.md.
#
# This lab recomputes both IDs two ways: with no git at all, and with git.
set -euo pipefail
cd "$(mktemp -d)"

SLIDE_BLOB=af5626b4a114abcb82d63db7c8082c3c4756e51b
SLIDE_TREE=d65b79a3eedbb4a7251c9e7bf5151d49c3e4429b

echo "== 1. by hand: sha1 of a framed byte string, no repository =="
python3 - <<'PY'
import hashlib
content = b"Hello, world!\n"
blob = hashlib.sha1(b"blob %d\0" % len(content) + content).hexdigest()
entry = b"100644 file1.txt\0" + bytes.fromhex(blob)
tree = hashlib.sha1(b"tree %d\0" % len(entry) + entry).hexdigest()
print("blob", blob)
print("tree", tree)
PY

echo
echo "== 2. with git, using only the commands the talk used =="
git init -q .
printf 'Hello, world!\n' > file1.txt
echo "git hash-object -w file1.txt  -> $(git hash-object -w file1.txt)"
git update-index --add file1.txt
echo "git write-tree                -> $(git write-tree)"

echo
echo "== 3. compare against the slide =="
got_blob=$(git hash-object file1.txt)
got_tree=$(git write-tree)
[ "$got_blob" = "$SLIDE_BLOB" ] && echo "blob MATCHES the slide" || { echo "blob DIFFERS"; exit 1; }
[ "$got_tree" = "$SLIDE_TREE" ] && echo "tree MATCHES the slide" || { echo "tree DIFFERS"; exit 1; }
echo
echo "git version: $(git --version)"
