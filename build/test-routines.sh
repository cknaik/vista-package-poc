#!/bin/bash
# test-routines.sh
#
# Lightweight sanity checks run BEFORE deploying to IRIS. Catches obvious
# mistakes without needing a live IRIS connection - fast, runs on every
# commit. This is not a substitute for real unit tests (see smoke-test.sh
# for a post-deploy check that actually exercises the code), just a cheap
# first line of defense.

set -euo pipefail

ROUTINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../routines" && pwd)"
FAILED=0

echo "Checking routines in ${ROUTINE_DIR}"

shopt -s nullglob
for file in "${ROUTINE_DIR}"/*.int "${ROUTINE_DIR}"/*.m; do
    name=$(basename "${file%.*}")
    ext="${file##*.}"
    first_line=$(head -n 1 "$file")

    # Check 1: the routine's declared name (first token on line 1) must
    # match the filename - a common copy/paste mistake in MUMPS routines.
    declared_name=$(echo "$first_line" | awk '{print $1}')
    if [ "$declared_name" != "$name" ]; then
        echo "FAIL: ${name}.${ext} - routine name on line 1 is '${declared_name}', expected '${name}'"
        FAILED=1
    fi

    # Check 2: file must not be empty.
    if [ ! -s "$file" ]; then
        echo "FAIL: ${name}.${ext} - file is empty"
        FAILED=1
    fi

    # Check 3: no leftover merge-conflict markers.
    if grep -qE '^(<<<<<<<|=======|>>>>>>>)' "$file"; then
        echo "FAIL: ${name}.${ext} - contains unresolved merge conflict markers"
        FAILED=1
    fi

    echo "OK: ${name}.${ext}"
done
shopt -u nullglob

if [ "$FAILED" -ne 0 ]; then
    echo "One or more routines failed checks - aborting before deploy."
    exit 1
fi

echo "All routine checks passed."
