#!/bin/bash

. lib_gcloud.sh
. lib_mysql.sh

latest_file=$(find_latest_file $SKYWIN_BACKUP_LOCATION/skywin-*.sql)
if [ -z "$latest_file" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 1
fi

file="skywin.sql"
download_file $latest_file $file

recreate_database $MYSQL_DATABASE $MYSQL_USER $MYSQL_PASSWORD
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
