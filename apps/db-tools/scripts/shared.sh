#!/bin/bash

gcloud_auth() {
  gcloud auth activate-service-account --key-file=/usr/src/credentials/application-credentials.json
}

check_env() {
  if [ -z "$MYSQL_HOST" ] || [ -z "$MYSQL_USER" ] || [ -z "$MYSQL_PASSWORD" ] || [ -z "$MYSQL_DATABASE" ]; then
    echo "Missing required environment variables."
    exit 1
  fi
}

import_sql_file() {
  local file="$1"
  echo "Importing $file into $MYSQL_DATABASE"
  mysql --protocol=tcp \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --port="$MYSQL_PORT" \
    --default-character-set=utf8 \
    --comments \
    --database="$MYSQL_DATABASE" <"$file"
  if [ $? -ne 0 ]; then
    echo "Failed to import $file into MySQL."
    exit 3
  fi
}

MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-skywin}"
SKYWIN_RENAME_SCRIPT="${SKYWIN_RENAME_SCRIPT:-MySQL.Rename_all_tables.sql}"
