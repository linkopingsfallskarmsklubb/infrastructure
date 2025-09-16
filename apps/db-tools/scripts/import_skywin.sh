#!/bin/bash

. gcloud.sh
. mysql.sh

latest_file=$(find_latest_file gs://lfk-backup/sql/skywin-*.sql)
if [ -z "$latest_file" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 2
fi

SKYWIN_FILE="skywin.sql"
download_file $latest_file $SKYWIN_FILE
run_query "DROP DATABASE IF EXISTS $MYSQL_DATABASE;"
import_sql_file $SKYWIN_FILE

echo "Import completed successfully."
