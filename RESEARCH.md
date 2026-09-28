# RESEARCH.md — how every number here was produced

Audit run 2026-09-28 on macOS 15 (Darwin 25.6.0, arm64), `git version 2.55.0`,
plus a `debian:bookworm-slim` container (`git version 2.39.5`) as a
second data point for old-git behaviour.

## 1. Choosing the talk

Candidates were ranked by real YouTube view counts read out of
`ytInitialData`, not from a blog list, using `my-linkedin/yt_talks.py`:

    python3 yt_talks.py search "GOTO conference git internals"

    dBSHLb1B8sw |     71,920 views | 10y ago | Deep Dive Into Git • Edward Thomson • GOTO 2015
    fHLcZGi3yMQ |      8,558 views |  6y ago | Knowledge is Power… • Steve Smith • GOTO 2019
    SiokK8Q1wo0 |      5,649 views | 10y ago | Understanding Git's Behaviour • Steve Smith • GOTO 2015
    DwIkptdspPc |      3,856 views |  6y ago | Git from the Ground Up • Safia Abdalla • GOTO 2020

Selection rule carried over from the previous two audits: five or more years
old, a central claim that can be **executed**, and an existing audience.
Thomson's is eleven years old, the largest in its category by 8x, and is
almost entirely a live demo of plumbing commands.

Also searched and rejected: performance, networking, database and security
tracks (see `my-linkedin/talk-audit-candidates.md`). Nothing in GOTO's
catalogue combines age, reach and executability the way this does except
Liz Rice's two talks, one of which was audited on 2026-09-22.

## 2. Recovering the slide

The slides are a 5.7 MB PDF of mostly images:

    curl -sLO https://gotocon.com/dl/goto-cph-2015/slides/EdwardThomson_DeepDiveIntoGit.pdf
    pdftotext -layout EdwardThomson_DeepDiveIntoGit.pdf -

48 lines of extractable text, of which the useful part is the object graph:

    commit 03ce18e...            \file1.txt
         tree d65b79a...
              blob af5626b... file1.txt
    commit 69a846f...            \file1.txt \file2.txt
         tree c1cacf9...
              blob af5626b... file1.txt
              blob 031defe... file2.txt

**The ASR transcript could not be fetched.** YouTube's `timedtext` endpoint
returns zero bytes without a PO token, and `yt-dlp` is not installed. The
audit therefore verifies the slides, not a command-by-command replay of the
demo, and the README says so.

### Recovering file1.txt's content from its blob ID

`af5626b…` is the SHA-1 of `blob <len>\0<content>`. The content is not on the
slide, so it was brute-forced over a small greeting corpus:

    checked 78 candidates -> MATCH af5626b 'Hello, world!\n'

Confirmed two independent ways (lab 01): by hand in python, and by
`git hash-object -w file1.txt`. The tree ID `d65b79a…` follows from it and
also matched, which makes the recovery certain rather than a coincidence of
one prefix.

### What could not be recovered, and why it is not a failure

`031defe…` (file2.txt) resisted 8,120 candidates across greeting × separator
× target × punctuation × trailing-newline combinations. Its bytes are not on
the slide, and a content-addressed ID gives nothing back without them. That
is the system working. `c1cacf9…` depends on it, and the two commit IDs
depend on identity and timestamps that are not on the slide either.

This distinction matters: the previous audit (`containers-from-scratch`)
found two apparent failures that were demo artifacts rather than decay, and
misreporting those would have been the worst available outcome. Four
unreproducible IDs here are design, not rot.

## 3. Reproducing the objects — lab 01, 02, 03

    $ printf 'Hello, world!\n' > file1.txt
    $ git hash-object -w file1.txt
    af5626b4a114abcb82d63db7c8082c3c4756e51b     <- slide
    $ git update-index --add file1.txt && git write-tree
    d65b79a3eedbb4a7251c9e7bf5151d49c3e4429b     <- slide

Same blob ID from git 2.39.5 in Debian, so this is not a property of one
build. Storage format, unchanged since 2005:

    $ python3 -c "import zlib;print(repr(zlib.decompress(open('.git/objects/af/5626b…','rb').read())))"
    b'blob 14\x00Hello, world!\n'

Commit IDs move with context; one second of timestamp difference:

    Alice 2015-10-05T10:00:00+0200 -> 178ead145869a031444eaa2b396bb4a9e4871290
    Alice 2015-10-05T10:00:01+0200 -> c056dca97f831b4b77ce73f21f094ae76022287c
    Bob   2015-10-05T10:00:00+0200 -> ecef42af8504a40ea9efa32730bb9903e5149ac8

## 4. Reference storage — lab 04, 05

    $ git init --ref-format=files . && … && cat .git/refs/heads/main
    e42f3cb31fc588ca1a05f20c98f2b33508dc8fa6      (41 bytes with the newline)
    $ cat .git/HEAD
    ref: refs/heads/main

    $ git init --ref-format=reftable . && … && cat .git/HEAD
    ref: refs/heads/.invalid
    $ cat .git/refs/heads/main
    cat: .git/refs/heads/main: Not a directory
    $ file .git/refs/heads ; cat .git/refs/heads
    .git/refs/heads: ASCII text
    this repository uses the reftable format          (41 bytes — same size)
    $ git rev-parse --abbrev-ref HEAD ; git symbolic-ref HEAD
    main
    refs/heads/main

The object store is byte-identical under both backends — the same three
loose object paths, including `af/5626b4a114abcb82d63db7c8082c3c4756e51b`.

`--ref-format` requires git 2.45 (May 2024). Debian bookworm's 2.39.5:

    error: unknown option `ref-format=reftable'

Lab 05 detects this and exits 0 with a message rather than failing.

## 5. The hash transition — lab 06

    $ git init --object-format=sha256 sha256repo
    $ git hash-object file1.txt
    7506cbcf4c572be9e06a1fed35ac5b1df8b5a74d26c07f022648e5d95a9f6f2a
    $ (cd sha256repo && git fetch ../sha1repo)
    fatal: mismatched algorithms: client sha256; server sha1
    $ (cd sha1repo && git fetch ../sha256repo)
    fatal: mismatched algorithms: client sha1; server sha256

    $ git version --build-options
    SHA-1: SHA1_DC
    SHA-256: SHA256_BLK
    default-hash: sha1
    default-ref-format: files

**A correction made during this audit.** Secondary sources summarising the
transition state that "a SHA-256 repository can communicate with SHA-1 Git
servers (push/fetch)". That is the design in
`Documentation/technical/hash-function-transition`, written in future tense,
not the shipped behaviour. The measurement above is what git 2.55.0 actually
does. Read the doc, then run the command.

`git init` in a clean environment still says:

    hint: Using 'master' as the name for the initial branch. This default
    hint: branch name will change to "main" in Git 3.0.

Git 3.0's other defaults, from `BreakingChanges`: SHA-256 object format,
reftable reference storage. **No announced release date.** Removals:
`git pack-redundant`, `git whatchanged`, commit grafts, `.git/branches/`,
`.git/remotes/`, `name-rev --stdin`.

## 6. SHAttered — lab 07

    $ shasum -a 1 shattered-1.pdf shattered-2.pdf
    38762cf7f55934b34d179ae6a4c80cadccbb7f0a  shattered-1.pdf
    38762cf7f55934b34d179ae6a4c80cadccbb7f0a  shattered-2.pdf
    $ git hash-object shattered-1.pdf shattered-2.pdf
    ba9aaa145ccd24ef760cf31c74d8f7ca1a2e47b0
    b621eeccd5c7edac9b7dcba35a8d5afd075e24f2
    $ cmp shattered-1.pdf shattered-2.pdf
    differ: char 193, line 8
    $ cmp -l shattered-1.pdf shattered-2.pdf | tail -1
    320 261 241

Bytes 1–192 are identical: exactly three 64-byte SHA-1 blocks, with the two
near-collision blocks at 193–320. Git prepends `blob 422435\0` (12 bytes),
which changes the chaining value the collision was computed against, so the
crafted blocks no longer cancel.

**A first draft of this lab claimed the collision would survive if git's
header were a multiple of 64 bytes.** That is wrong. SHAttered is an
identical-prefix collision bound to one specific chaining state, so *any*
change to the prefix breaks it, aligned or not. Corrected before publication.
The capability that does absorb an arbitrary prefix is the chosen-prefix
collision of Leurent & Peyrin (2020), complexity 2^63.4.

Git's protection is SHA1_DC, confirmed in `--build-options` above, not the
framing.

## 7. Command survival — lab 08

25 plumbing commands from the talk's era checked against git 2.55.0
(`hash-object`, `cat-file`, `update-index`, `write-tree`, `commit-tree`,
`read-tree`, `ls-tree`, `ls-files`, `rev-parse`, `rev-list`, `symbolic-ref`,
`update-ref`, `show-ref`, `for-each-ref`, `verify-pack`, `count-objects`,
`unpack-objects`, `pack-objects`, `prune`, `fsck`, `gc`, `reflog`,
`merge-base`, `diff-tree`, `mktree`): **0 missing**.

    $ git whatchanged
    'git whatchanged' is nominated for removal.
    $ git pack-redundant --all
    'git pack-redundant' is nominated for removal.

## 8. Shell bugs hit while writing the labs

`set -euo pipefail` plus `cmd 2>&1 | head -1` kills the script when `cmd`
exits non-zero, even though `head` succeeds — `pipefail` propagates the left
side. Hit three times (labs 06, 07, 08) on `git fetch`, `cmp` and
`git pack-redundant`, all of which are *expected* to fail. Fixed with
`{ cmd || true; } | head -1`. Worth knowing before it eats a CI step.

## 9. Reproducing this whole document

    ./run-all.sh > transcript-$(date -u +%Y%m%d).txt

Eight labs, all passing on git 2.55.0 as of 2026-09-28.
