#!/bin/bash

. gcloud.sh
. mysql.sh

latest_file=$(find_latest_file gs://lfk-backup/sql/skywin-*.sql)
if [ -z "$latest_file" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 1
fi

file="skywin.sql"
download_file $latest_file $file

recreate_database
if [ $? -ne 0 ]; then
  echo "Failed to recreate database."
  exit 1
fi
echo "Database recreated successfully."

import_sql_file $file
if [ $? -ne 0 ]; then
  echo "Failed to import $file into MySQL."
  exit 1
fi
echo "Successfully imported $file into $MYSQL_DATABASE"

echo "Import completed successfully."
