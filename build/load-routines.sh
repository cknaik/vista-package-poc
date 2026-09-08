#!/bin/bash
# load-routines.sh
#
# Loads every .m routine in routines/ into the shared VistA/IRIS instance.
# Called by Jenkins after a merge to main. Can also be run manually from a
# dev VM for local testing before pushing.
#
# IMPORTANT: the `iris` CLI only exists ON the IRIS EC2 instance itself, not
# on Jenkins or the dev VMs - so this script SSHs into IRIS_HOST and runs
# the load there, rather than assuming a local `iris` command.
#
# Requires: IRIS_HOST (private IP of the IRIS EC2 instance) as an env var,
# and SSH key access to that host as the `ubuntu` user. In Jenkins this
# comes from the 'iris-ssh-key' SSH credential (see Jenkinsfile, which wraps
# this script in an sshagent() block) - no key files are stored on disk.

set -euo pipefail

IRIS_HOST="${IRIS_HOST:?Set IRIS_HOST}"
IRIS_NAMESPACE="${IRIS_NAMESPACE:-USER}"

ROUTINE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../routines" && pwd)"
REMOTE_DIR="/tmp/routines-import"

# Some VistA repos use the traditional GT.M/YottaDB ".m" extension instead
# of IRIS's expected ".int" - both are the same MUMPS syntax, so we accept
# either in the repo and normalize to .int only in the staging copy (the
# actual source files in routines/ are never touched or renamed).
# Note: if a routine somehow exists as both NAME.int and NAME.m, the .m
# version will silently overwrite the .int copy in staging - avoid having
# both for the same routine name.
STAGING_DIR="$(mktemp -d)"
trap 'rm -rf "${STAGING_DIR}"' EXIT

shopt -s nullglob
for f in "${ROUTINE_DIR}"/*.int "${ROUTINE_DIR}"/*.m; do
    base="$(basename "${f%.*}")"
    cp "$f" "${STAGING_DIR}/${base}.int"
done
shopt -u nullglob

if [ -z "$(ls -A "${STAGING_DIR}")" ]; then
    echo "No .int or .m routine files found in ${ROUTINE_DIR} - nothing to deploy."
    exit 1
fi

echo "Copying routines from ${ROUTINE_DIR} (normalized to .int) to ${IRIS_HOST}:${REMOTE_DIR}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "mkdir -p ${REMOTE_DIR}"
scp -o StrictHostKeyChecking=accept-new "${STAGING_DIR}"/*.int "ubuntu@${IRIS_HOST}:${REMOTE_DIR}/"

echo "Copying routines into the IRIS container's filesystem"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" \
  "docker exec iris mkdir -p ${REMOTE_DIR} && docker cp ${REMOTE_DIR}/. iris:${REMOTE_DIR}/"

echo "Loading routines into IRIS namespace ${IRIS_NAMESPACE}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" \
  "docker exec -i iris iris session iris" <<EOF
zn "${IRIS_NAMESPACE}"
set sc = \$System.OBJ.ImportDir("${REMOTE_DIR}", "*.int", "ck", .errorlog, 1)
if sc '= 1 write "Load FAILED",!  quit
write "Load succeeded",!
halt
EOF

echo "Cleaning up staging directories"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "rm -rf ${REMOTE_DIR}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "docker exec iris rm -rf ${REMOTE_DIR}"

echo "Done."
