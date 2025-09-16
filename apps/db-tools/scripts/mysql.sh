#!/bin/bash

import_sql_file() {
  local file="$1"
  echo "Importing $file into $MYSQL_DATABASE."
  mysql --protocol=tcp \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_ROOT_USER" \
    --password="$MYSQL_ROOT_PASSWORD" \
    --port="$MYSQL_PORT" \
    --default-character-set=utf8 \
    --comments \
    --database="$MYSQL_DATABASE" <"$file"
}

run_query() {
  local query="$1"
  mysql --protocol=tcp \
    --host="$MYSQL_HOST" \
    --user="$MYSQL_ROOT_USER" \
    --password="$MYSQL_ROOT_PASSWORD" \
    --port="$MYSQL_PORT" \
    --default-character-set=utf8 \
    --comments \
    --database="$MYSQL_DATABASE" \
    -e "$query"
}

drop_database() {
  run_query "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`;"
}

create_database() {
  run_query "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\`;"
}

create_user() {
  run_query "CREATE USER IF NOT EXISTS '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';"
  run_query "GRANT ALL ON $MYSQL_DATABASE.* TO '$MYSQL_USER'@'%';"
}

recreate_database() {
  drop_database
  create_database
  create_user
}

MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_ROOT_USER="${MYSQL_USER:-root}"
MYSQL_ROOT_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_USER="${MYSQL_USER:-skywin}"
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
