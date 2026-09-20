#!/usr/bin/env bash
#
# Prints a line-coverage summary from an lcov tracefile, in the format lcov's
# own --summary uses:
#
#   lines......: 35.9% (949 of 2647 lines)
#
# `flutter test --coverage` writes coverage/lcov.info but prints no percentage,
# and GitLab reads job coverage by matching a regex against the log (see the
# `coverage:` key on unit-test in .gitlab-ci.yml). Rather than pull in the lcov
# package just for this, compute it from the DA: records.
set -euo pipefail

TRACEFILE="${1:-coverage/lcov.info}"

if [ ! -f "$TRACEFILE" ]; then
  echo "No coverage tracefile at $TRACEFILE" >&2
  exit 1
fi

# DA:<line number>,<execution count> — one per instrumented line.
awk -F'[:,]' '
  /^DA:/ { total++; if ($3 > 0) covered++ }
  END {
    printf "lines......: %.1f%% (%d of %d lines)\n",
      total ? covered * 100 / total : 0, covered, total
  }
' "$TRACEFILE"
