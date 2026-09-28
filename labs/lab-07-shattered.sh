#!/usr/bin/env bash
# Lab 07 — the two files that broke SHA-1, fed to the talk's first command.
#
# SHAttered (Stevens et al., 23 February 2017) published two PDFs with the
# same SHA-1. The common retelling is "so git is broken". This lab checks
# that claim rather than repeating it. Needs network.
set -euo pipefail
cd "$(mktemp -d)"
for n in 1 2; do
  curl -fsSL -o "shattered-$n.pdf" "https://shattered.io/static/shattered-$n.pdf" || {
    echo "could not download the SHAttered PDFs (no network?), skipping"; exit 0; }
done
sha1() { if command -v sha1sum >/dev/null; then sha1sum "$1" | cut -d' ' -f1; else shasum -a 1 "$1" | cut -d' ' -f1; fi; }

echo "== raw SHA-1 of the two files =="
for n in 1 2; do printf '  shattered-%s.pdf : %s (%s bytes)\n' "$n" "$(sha1 shattered-$n.pdf)" "$(wc -c < shattered-$n.pdf | tr -d ' ')"; done
echo "  -> identical, as advertised"

echo
echo "== where they differ =="
set +e; first=$(cmp shattered-1.pdf shattered-2.pdf 2>&1 | sed -n 's/.*char \([0-9]*\),.*/\1/p') || true
last=$(cmp -l shattered-1.pdf shattered-2.pdf | tail -1 | awk '{print $1}'); set -e
echo "  first differing byte: $first   last differing byte: $last"
echo "  -> bytes 1..$((first-1)) are identical, and $((first-1)) is $(( (first-1)/64 )) whole SHA-1 blocks"
echo
echo "== the same two files as git objects =="
git init -q .
for n in 1 2; do printf '  git hash-object shattered-%s.pdf : %s\n' "$n" "$(git hash-object "shattered-$n.pdf")"; done
echo "  -> different"

echo
cat <<'TXT'
Why they differ: git never hashes the file. It hashes the string
"blob <length>\0" and then the file. SHAttered is an *identical-prefix*
collision: the two PDFs share their first 192 bytes and the collision blocks
that follow were computed for the SHA-1 chaining state reached after exactly
those bytes. Prepending a 12-byte git header changes that state, so the
crafted blocks no longer cancel and the two objects get different IDs.

That defence is an accident of framing, not a design. It was also temporary.
SHA-1 is a Shambles (Leurent & Peyrin, January 2020) demonstrated the first
practical *chosen-prefix* collision on SHA-1, at complexity 2^63.4, which is
exactly the capability needed to absorb an arbitrary prefix such as git's
object header.

What actually protects the repository is that git is built against a SHA-1
that watches for the disturbance vectors these attacks depend on and aborts:
TXT
git version --build-options | grep '^SHA-1:' | sed 's/^/  /'
