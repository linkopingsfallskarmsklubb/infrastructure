#!/bin/bash

gcloud auth activate-service-account --key-file=/usr/src/credentials/application-credentials.json

# Read variables from environment, set defaults where needed
GCS_BUCKET="${GCS_BUCKET:-gs://lfk-backup/sql/skywin-*.sql}"
MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-skywin}"

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
LOCAL_FILE="import.sql"
if ! gsutil cp "$LATEST_FILE" "$LOCAL_FILE"; then
  echo "Failed to download file from GCS."
  exit 2
fi

# Import file into MySQL database
echo "Importing $LOCAL_FILE into $MYSQL_DATABASE"
mysql --protocol=tcp \
  --host="$MYSQL_HOST" \
  --user="$MYSQL_USER" \
  --password="$MYSQL_PASSWORD" \
  --port="$MYSQL_PORT" \
  --default-character-set=utf8 \
  --comments \
  --database="$MYSQL_DATABASE" <"$LOCAL_FILE"

if [ $? -ne 0 ]; then
  echo "Failed to import file into MySQL."
  exit 3
fi

echo "Import completed successfully."
