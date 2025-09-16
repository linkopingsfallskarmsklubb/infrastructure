#!/bin/bash

import_sql_file() {
  local file="$1"
  echo "Importing $file into $MYSQL_DATABASE."
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
  echo "Successfully imported $file into $MYSQL_DATABASE"
}

run_query() {
  local query="$1"
  mysql --protocol=tcp \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_USER" \
    --password="$MYSQL_PASSWORD" \
    --port="$MYSQL_PORT" \
    --default-character-set=utf8 \
    --comments \
    --database="$MYSQL_DATABASE" \
    -e "$query"
  if [ $? -ne 0 ]; then
    echo "Failed to run query: $query"
    exit 4
  fi
}

MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-skywin}"

if [ -z "$MYSQL_HOST" ]; then
  echo "Missing required environment variable: MYSQL_HOST"
  exit 1
fi

if [ -z "$MYSQL_PORT" ]; then
  echo "Missing required environment variable: MYSQL_PORT"
  exit 1
fi

if [ -z "$MYSQL_USER" ]; then
  echo "Missing required environment variable: MYSQL_USER"
  exit 1
fi

if [ -z "$MYSQL_PASSWORD" ]; then
  echo "Missing required environment variable: MYSQL_PASSWORD"
  exit 1
fi

if [ -z "$MYSQL_DATABASE" ]; then
  echo "Missing required environment variable: MYSQL_DATABASE"
  exit 1
fi
