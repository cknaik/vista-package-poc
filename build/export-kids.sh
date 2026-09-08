#!/bin/bash
# export-kids.sh
#
# Sprint-end step: packages the current set of package routines into a
# KIDS build (.KID) file for distribution/audit. This is NOT part of the
# continuous-deploy pipeline (that uses load-routines.sh on every merge) -
# run this manually, or as a separate scheduled Jenkins job, at sprint end.
#
# NOTE: This is a placeholder. Real KIDS build generation needs VistA's
# build utilities (^DIFROM and the KIDS build dictionary) which must be
# present in the target namespace. Fill in BUILD_NAME/routines list to
# match your actual VistA build utilities before relying on this.

set -euo pipefail

IRIS_HOST="${IRIS_HOST:?Set IRIS_HOST}"
IRIS_NAMESPACE="${IRIS_NAMESPACE:-USER}"
BUILD_NAME="${BUILD_NAME:-XYZ POC PACKAGE 1.0}"
OUTPUT_DIR="${OUTPUT_DIR:-./kids-output}"

mkdir -p "${OUTPUT_DIR}"

echo "Generating KIDS build '${BUILD_NAME}' from ${IRIS_HOST}/${IRIS_NAMESPACE}"

# Placeholder call - replace with your actual KIDS build extrinsic once the
# build dictionary entry for BUILD_NAME exists in the target namespace.
iris session iris -U "${IRIS_NAMESPACE}" <<EOF
write "TODO: invoke ^DIFROM or equivalent KIDS build export for ${BUILD_NAME}",!
halt
EOF

echo "KIDS build artifact would be written to ${OUTPUT_DIR}/"
