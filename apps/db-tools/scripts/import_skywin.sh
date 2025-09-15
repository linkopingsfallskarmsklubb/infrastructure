#!/bin/bash

. shared.sh

gcloud_auth
check_env

download_latest_file() {
  local latest_file="$1"
  local output_file="$2"
  if ! gsutil cp "$latest_file" "$output_file"; then
    echo "Failed to download file from GCS."
    exit 2
  fi
}

find_latest_file() {
  local path="$1"
  gsutil ls -l $path | sort -k2 -nr | head -n1 | awk '{print $3}'
}

latest_file=$(find_latest_file gs://lfk-backup/sql/skywin-*.sql)
if [ -z "$latest_file" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 2
fi

SKYWIN_FILE="skywin.sql"
download_latest_file $latest_file $SKYWIN_FILE
import_sql_file $SKYWIN_FILE

echo "Import completed successfully."
