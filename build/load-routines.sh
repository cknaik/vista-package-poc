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

echo "Copying routines from ${ROUTINE_DIR} to ${IRIS_HOST}:${REMOTE_DIR}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "mkdir -p ${REMOTE_DIR}"
scp -o StrictHostKeyChecking=accept-new "${ROUTINE_DIR}"/*.m "ubuntu@${IRIS_HOST}:${REMOTE_DIR}/"

echo "Copying routines into the IRIS container's filesystem"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" \
  "docker exec iris mkdir -p ${REMOTE_DIR} && docker cp ${REMOTE_DIR}/. iris:${REMOTE_DIR}/"

echo "Loading routines into IRIS namespace ${IRIS_NAMESPACE}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" \
  "docker exec -i iris iris session iris" <<EOF
zn "${IRIS_NAMESPACE}"
set sc = \$System.OBJ.ImportDir("${REMOTE_DIR}", "*.m", "ck", .errorlog, 1)
if sc '= 1 write "Load FAILED",!  quit
write "Load succeeded",!
halt
EOF

echo "Cleaning up staging directories"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "rm -rf ${REMOTE_DIR}"
ssh -o StrictHostKeyChecking=accept-new "ubuntu@${IRIS_HOST}" "docker exec iris rm -rf ${REMOTE_DIR}"

echo "Done."
