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
    -e "$query"
}

drop_database() {
  local database="$1"
  echo "Dropping database $database."
  run_query "DROP DATABASE IF EXISTS \`$database\`;"
}

create_database() {
  local database="$1"
  echo "Creating database $database if not exists."
  run_query "CREATE DATABASE IF NOT EXISTS \`$database\`;"
}

create_user() {
  local database="$1"
  local user="$2"
  local password="$3"
  echo "Creating user $user with access to database $database."
  run_query "CREATE USER IF NOT EXISTS '$user'@'%' IDENTIFIED BY '$password';"
  run_query "GRANT ALL ON $database.* TO '$user'@'%';"
}

recreate_database() {
  local database="$1"
  local user="$2"
  local password="$3"
  echo "Recreating database $database and user $user."
  drop_database "$database"
  create_database "$database"
  create_user "$database" "$user" "$password"
}

MYSQL_HOST="${MYSQL_HOST:-mysql.core.svc}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_ROOT_USER="${MYSQL_ROOT_USER:-root}"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD}"
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
