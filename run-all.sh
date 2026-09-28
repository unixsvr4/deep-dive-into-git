#!/usr/bin/env bash
# Run every lab and print a transcript. Nothing here needs root, a cloud
# account, or a container: it is git, python3, curl and a shell.
#
#   ./run-all.sh              run all labs
#   ./run-all.sh 05           run one lab
set -uo pipefail
cd "$(dirname "$0")"
sel="${1:-}"
echo "host git : $(git --version)"
echo "date     : $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
fail=0
for f in labs/lab-*.sh; do
  n=$(basename "$f" | sed -n 's/^lab-\([0-9]*\)-.*/\1/p')
  [ -n "$sel" ] && [ "$sel" != "$n" ] && continue
  echo
  echo "########## $(basename "$f") ##########"
  bash "$f" || { echo "LAB $n FAILED"; fail=1; }
done
echo
[ "$fail" = 0 ] && echo "all labs passed" || echo "some labs failed"
exit "$fail"
