#!/bin/bash

gcloud auth activate-service-account --key-file=/usr/src/credentials/application-credentials.json

# Read variables from environment, set defaults where needed
GCS_BUCKET="${GCS_BUCKET:-gs://lfk-backup/sql/skywin-*.sql}"
MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-skywin}"
SKYWIN_RENAME_SCRIPT="${SKYWIN_RENAME_SCRIPT:-MySQL.Rename_all_tables.sql}"

# Check required variables
if [ -z "$GCS_BUCKET" ] || [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ]; then
  echo "Missing required environment variables."
  exit 1
fi

# Find the latest file in the bucket
LATEST_FILE=$(gsutil ls -l gs://lfk-backup/sql/skywin-*.sql | sort -k2 -nr | head -n1 | awk '{print $3}')
if [ -z "$LATEST_FILE" ]; then
  echo "No files found in bucket $GCS_BUCKET."
  exit 2
fi

# Download the latest file from Google Cloud Storage
SKYWIN_FILE="skywin.sql"
if ! gsutil cp "$LATEST_FILE" "$SKYWIN_FILE"; then
  echo "Failed to download file from GCS."
  exit 2
fi

# Import file into MySQL database
echo "Importing $SKYWIN_FILE into $MYSQL_DATABASE"
mysql --protocol=tcp \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASSWORD" \
  --port="$MYSQL_PORT" \
  --default-character-set=utf8 \
  --comments \
  --database="$MYSQL_DATABASE" <"$SKYWIN_FILE"

# Rename tables: https://skywin.se/download
RENAME_FILE=rename.sql
echo "Importing $RENAME_FILE into $MYSQL_DATABASE"
curl https://www.skywinner.se/skywin/_files/sql_ddl/MySQL.Rename_all_tables.sql >$RENAME_FILE
mysql --protocol=tcp \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASSWORD" \
  --port="$MYSQL_PORT" \
  --default-character-set=utf8 \
  --comments \
  --database="$MYSQL_DATABASE" <"$RENAME_FILE"

if [ $? -ne 0 ]; then
  echo "Failed to import file into MySQL."
  exit 3
fi

echo "Import completed successfully."
