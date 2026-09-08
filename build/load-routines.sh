#!/bin/bash
# load-routines.sh
#
# Loads every .m routine in routines/ into the shared VistA/IRIS instance.
# Called by Jenkins after a merge to main. Can also be run manually from a
# dev VM for local testing before pushing.
#
# Requires: IRIS_HOST, IRIS_PORT, IRIS_NAMESPACE, IRIS_USER, IRIS_PASSWORD
# set as environment variables (Jenkins pulls these from its credentials store).

set -euo pipefail

IRIS_HOST="${IRIS_HOST:?Set IRIS_HOST}"
IRIS_PORT="${IRIS_PORT:-1972}"
IRIS_NAMESPACE="${IRIS_NAMESPACE:-USER}"
IRIS_USER="${IRIS_USER:?Set IRIS_USER}"
IRIS_PASSWORD="${IRIS_PASSWORD:?Set IRIS_PASSWORD}"

ROUTINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../routines" && pwd)"

echo "Loading routines from ${ROUTINE_DIR} into ${IRIS_HOST}:${IRIS_PORT}/${IRIS_NAMESPACE}"

# Uses the IRIS command-line session to run ObjectScript non-interactively.
# $System.OBJ.ImportDir() imports every routine file in the directory in one call.
iris session iris -U "${IRIS_NAMESPACE}" <<EOF
set sc = \$System.OBJ.ImportDir("${ROUTINE_DIR}", "*.m", "ck", .errorlog, 1)
if sc '= 1 write "Load FAILED",!  quit
write "Load succeeded",!
halt
EOF

echo "Done."
