# Deep Dive into Git, eleven years later

An audit of Edward Thomson's **"Deep Dive into Git"** (GOTO Copenhagen,
21 October 2015, 71,920 views as of 2026-09-28), re-run on git 2.55.0 in
September 2026.

The talk explains git's object model: blobs, trees, commits, refs, and the
storage format underneath them. This repository checks two things.

1. **Does any of it still hold?** Yes — completely. Two of the object IDs
   printed on the slides are recomputable today to the character, and every
   plumbing command the talk relies on is still present.
2. **What is about to change?** The half nobody was told to stop depending
   on. Git 3.0 changes the default object hash, the default branch name, and
   the on-disk format of references.

Everything here runs on a laptop in under a minute. No cloud account, no
container, no root.

```sh
./run-all.sh        # all eight labs
./run-all.sh 05     # just one
```

Requires `git`, `python3`, `curl`, and a POSIX shell. Lab 05 needs git 2.45
or newer (`--ref-format` landed in 2.45, May 2024; Debian bookworm's 2.39
cannot run it and the lab says so and exits clean). Lab 07 needs network.

## What was measured

| # | Lab | Result |
|---|---|---|
| 01 | Recompute the slide | `af5626b…` and `d65b79a…` reproduce exactly, eleven years on |
| 02 | Content versus context | the commit IDs on the same slide are not reproducible, by design |
| 03 | The object on disk | a loose object is still `blob 14\0Hello, world!\n`, zlib-deflated |
| 04 | Refs are files | a branch is 40 hex characters and a newline, in a file |
| 05 | Reftable breaks the one-liner | `cat .git/HEAD` returns `ref: refs/heads/.invalid` |
| 06 | The hash that could not be replaced | `fatal: mismatched algorithms`, both directions |
| 07 | SHAttered | the two colliding PDFs get **different** git object IDs |
| 08 | Nominated for removal | 25 of 25 plumbing commands survive; two porcelain ones do not |

## The finding

Slide 17 of the talk shows an object graph with six abbreviated IDs. Two of
them are derivable from what is on the slide, and both reproduce exactly on a
2026 machine:

```
blob af5626b4a114abcb82d63db7c8082c3c4756e51b   sha1("blob 14\0Hello, world!\n")
tree d65b79a3eedbb4a7251c9e7bf5151d49c3e4429b   sha1("tree 37\0" + one entry)
```

No repository is involved. That is lab 01's first half: forty characters of
python and no git binary at all.

The other four IDs are two commits and the objects behind a second file whose
bytes are not on the slide. None of them can be reproduced, and **that is not
decay** — a commit hashes the author, the committer, two timestamps with
timezones and the message, so one second of difference changes it completely
(lab 02). Content is portable across eleven years. Context is not portable
across one second.

### The half that is about to move

Git 3.0 will change three defaults for newly created repositories
([BreakingChanges](https://git-scm.com/docs/BreakingChanges)): the object
hash becomes SHA-256, the initial branch becomes `main`, and reference
storage becomes **reftable** instead of files. There is no announced release
date.

The object store is not affected. References are, and that is the half with
twenty years of shell scripts wrapped around it:

```
files backend                      reftable backend
-------------------------------    ----------------------------------------
$ cat .git/HEAD                    $ cat .git/HEAD
ref: refs/heads/main               ref: refs/heads/.invalid

$ cut -d/ -f3- .git/HEAD           $ cut -d/ -f3- .git/HEAD
main                               .invalid

$ cat .git/refs/heads/main         $ cat .git/refs/heads/main
e42f3cb31fc588ca…                  cat: .git/refs/heads/main: Not a directory
```

`.git/HEAD` is still there, still a text file, still parses. It names a
branch that cannot exist, because `.invalid` is not a legal ref name. A
script reading it does not crash — it gets a plausible string and keeps
going. `.git/refs/heads` becomes a 41-byte text file reading `this repository
uses the reftable format`, which is exactly the length of the ref file it
replaces.

`git rev-parse --abbrev-ref HEAD`, `git symbolic-ref HEAD` and
`git for-each-ref` return the right answer under both backends and always
have. For twenty years there has been no reason to prefer them.

### The hash

SHA-1 was broken in public in February 2017, sixteen months after this talk.
Git gained a SHA-256 object format in 2.29 (October 2020). Six years later:

```
$ git fetch ../sha1repo
fatal: mismatched algorithms: client sha256; server sha1
```

Both directions. The
[hash function transition](https://git-scm.com/docs/hash-function-transition)
design describes the interoperability layer in future tense; it is not
implemented. GitHub does not host SHA-256 repositories.

An object ID is the one identifier in the system that cannot be versioned,
because it is derived from the thing it names. That is what makes a 2015 blob
ID checkable in 2026, and it is the same property that has held the migration
off a broken hash for nine years.

### SHAttered, precisely

The two SHAttered PDFs have one SHA-1 and **two different git object IDs**
(lab 07), because git hashes `blob <length>\0` before the content and the
2017 attack was an identical-prefix collision computed for the PDF's own
first 192 bytes. That is an accident of framing, not a defence, and it was
answered in 2020 by the first practical chosen-prefix collision. What
actually protects a repository is that git is built against SHA-1DC
(`git version --build-options` → `SHA-1: SHA1_DC`), which detects the attack
pattern and aborts.

## If you run production

Two things are worth ten minutes:

- Grep your build and deploy tooling for anything that reads `.git/` as a
  filesystem — `cat .git/HEAD`, `.git/refs/heads/$BRANCH`, `.git/ORIG_HEAD`.
  Under reftable the first of those returns a wrong answer rather than an
  error. Replace with `git rev-parse` / `git symbolic-ref`.
- Grep for anything that validates or slices a commit ID as 40 hex
  characters: SBOM tooling, provenance attestations, cache keys, image tags,
  release manifests. A SHA-256 repository produces 64.

## Sources

- Edward Thomson, *Deep Dive into Git*, GOTO Copenhagen 2015 —
  [video](https://www.youtube.com/watch?v=dBSHLb1B8sw) ·
  [slides](https://gotocon.com/dl/goto-cph-2015/slides/EdwardThomson_DeepDiveIntoGit.pdf)
- git [BreakingChanges](https://git-scm.com/docs/BreakingChanges),
  [hash-function-transition](https://git-scm.com/docs/hash-function-transition),
  `gitdatamodel(7)` (new in git 2.51)
- Stevens, Bursztein, Karpman, Albertini, Markov, *The first collision for
  full SHA-1*, 2017 — <https://shattered.io>
- Leurent & Peyrin, *SHA-1 is a Shambles*, USENIX Security 2020 —
  <https://eprint.iacr.org/2020/014>

See [RESEARCH.md](RESEARCH.md) for how each number was produced, including
the parts that did not work.
