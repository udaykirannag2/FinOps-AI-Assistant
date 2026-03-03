#!/bin/bash
# Copy existing CUR 2.0 data from your source bucket (Management) to CID Data Collection bucket
# For users who already have CUR 2.0 in an S3 bucket and want to backfill CID without waiting for replication.
# Uses local staging: download with Management profile, upload with Data Collection profile.
#
# Usage: ./copy-cur-to-cid.sh
# Config: Source config.sh (or set env vars below). See deploy/README.md for details.
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "${SCRIPT_DIR}/config.sh" ] && source "${SCRIPT_DIR}/config.sh"

SOURCE_BUCKET="${CUR_SOURCE_BUCKET:-curbucketforroot}"
DEST_BUCKET="${CID_DATA_EXPORTS_BUCKET:-cid-${DATA_COLLECTION_ACCOUNT_ID:-010928194325}-data-exports}"
SOURCE_PREFIX="${CUR_SOURCE_PREFIX:-costreports/CUR/data}"
MGMT_ACCOUNT_ID="${MANAGEMENT_ACCOUNT_ID:-568838249405}"
DEST_PREFIX="cur2/source_account_id=${MGMT_ACCOUNT_ID}/report_name=CUR/data=data"
MGMT_PROFILE="${MANAGEMENT_PROFILE:-management-account}"
DC_PROFILE="${DATA_COLLECTION_PROFILE:-data-collection-access-profile}"
REGION="${AWS_REGION:-us-east-1}"
TEMP_DIR=$(mktemp -d -t cur-copy-XXXXXX)
trap "rm -rf ${TEMP_DIR}" EXIT

echo "Copying CUR data from ${SOURCE_BUCKET} to ${DEST_BUCKET}..."
echo "Using temp dir: ${TEMP_DIR}"

aws s3 ls "s3://${SOURCE_BUCKET}/${SOURCE_PREFIX}/" --profile "${MGMT_PROFILE}" --region "${REGION}" | while read -r line; do
  if [[ "$line" == *"PRE BILLING_PERIOD="* ]]; then
    period=$(echo "$line" | awk '{print $2}' | sed 's/BILLING_PERIOD=//' | sed 's/\///')
    if [[ -n "$period" ]]; then
      echo "Copying billing period: $period"
      aws s3 sync \
        "s3://${SOURCE_BUCKET}/${SOURCE_PREFIX}/BILLING_PERIOD=${period}/" \
        "${TEMP_DIR}/${period}/" \
        --profile "${MGMT_PROFILE}" \
        --region "${REGION}" \
        --only-show-errors
      aws s3 sync \
        "${TEMP_DIR}/${period}/" \
        "s3://${DEST_BUCKET}/${DEST_PREFIX}/billing_period=${period}/" \
        --profile "${DC_PROFILE}" \
        --region "${REGION}" \
        --only-show-errors
      rm -rf "${TEMP_DIR}/${period}"
    fi
  fi
done

echo "Copy complete. Starting Glue crawler to refresh partitions..."
aws glue start-crawler --name cid-DataExportCUR2Crawler \
  --profile "${DC_PROFILE}" \
  --region "${REGION}"

echo "Done. Crawler started - partitions will be available once it completes (~few mins)."
