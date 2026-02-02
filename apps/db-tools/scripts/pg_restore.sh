#!/bin/bash

. lib_gcloud.sh
. lib_pgsql.sh

# Find latest backup for this DB
latest_file=$(find_latest_file $PG_BACKUP_LOCATION/${PG_DATABASE}-*.sql)
if [ -z "$latest_file" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 1
fi

file="${PG_DATABASE}.sql"
download_file $latest_file $file

recreate_database $PG_DATABASE $PG_USER $PG_PASSWORD
if [ $? -ne 0 ]; then
  echo "Failed to recreate database."
  exit 1
fi
echo "Database recreated successfully."

import_sql_file $file
if [ $? -ne 0 ]; then
  echo "Failed to import $file into PostgreSQL."
  exit 1
fi
echo "Successfully imported $file into $PG_DATABASE"

echo "Import completed successfully."
