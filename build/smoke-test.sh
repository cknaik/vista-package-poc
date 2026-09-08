#!/bin/bash
# smoke-test.sh
#
# Runs AFTER routines are loaded into IRIS. Actually calls the deployed
# code and checks the output, so a routine that loads cleanly but is
# logically broken still fails the build. Deliberately minimal for the
# POC - calls one known entry point and checks for expected text.
#
# Requires: IRIS_HOST, same SSH access as load-routines.sh.

set -euo pipefail

IRIS_HOST="${IRIS_HOST:?Set IRIS_HOST}"
IRIS_NAMESPACE="${IRIS_NAMESPACE:-USER}"

echo "Running smoke test against ${IRIS_HOST}/${IRIS_NAMESPACE}"

OUTPUT=$(ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" bash <<EOF
iris session iris -U "${IRIS_NAMESPACE}" <<'INNEREOF'
do GREET^XYZFOO("SmokeTest")
halt
INNEREOF
EOF
)

echo "--- Routine output ---"
echo "${OUTPUT}"
echo "----------------------"

if echo "${OUTPUT}" | grep -q "Hello, SmokeTest!"; then
    echo "Smoke test PASSED."
    exit 0
else
    echo "Smoke test FAILED - expected output not found."
    exit 1
fi
