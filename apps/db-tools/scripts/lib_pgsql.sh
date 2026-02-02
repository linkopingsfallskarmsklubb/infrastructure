#!/bin/bash

import_sql_file() {
  local file="$1"
  echo "Importing $file into $PG_DATABASE."
  PGPASSWORD="$PG_PASSWORD" psql \
    --host="$PG_HOST" \
    --username="$PG_USER" \
    --port="$PG_PORT" \
    --dbname="$PG_DATABASE" \
    --file="$file"
}

run_query() {
  local query="$1"
  local db="${2:-$PG_DATABASE}"
  PGPASSWORD="$PG_PASSWORD" psql \
    --host="$PG_HOST" \
    --username="$PG_USER" \
    --port="$PG_PORT" \
    --dbname="$db" \
    --command="$query"
}

drop_database() {
  local database="$1"
  echo "Dropping database $database."
  run_query "DROP DATABASE IF EXISTS \"$database\";" "postgres"
}

create_database() {
  local database="$1"
  echo "Creating database $database if not exists."
  # Postgres doesn't support CREATE DATABASE IF NOT EXISTS easily in SQL block without PL/pgSQL or check.
  # But since we use psql -c, we can ignore error or check first.
  # Simplest is to try create and ignore specific error, or use logic.
  # Actually, "DROP IF EXISTS" + "CREATE" is what recreate does.
  # For create_database idempotent:
  local exists=$(run_query "SELECT 1 FROM pg_database WHERE datname = '$database'" "postgres" | grep -c 1)
  if [ "$exists" -eq 0 ]; then
    run_query "CREATE DATABASE \"$database\";" "postgres"
  else
    echo "Database $database already exists."
  fi
}

create_user() {
  local database="$1"
  local user="$2"
  local password="$3"
  echo "Creating user $user with access to database $database."
  # Create role if not exists
  local exists=$(run_query "SELECT 1 FROM pg_roles WHERE rolname = '$user'" "postgres" | grep -c 1)
  if [ "$exists" -eq 0 ]; then
    run_query "CREATE USER \"$user\" WITH PASSWORD '$password';" "postgres"
  else
    run_query "ALTER USER \"$user\" WITH PASSWORD '$password';" "postgres"
  fi
  run_query "GRANT ALL PRIVILEGES ON DATABASE \"$database\" TO \"$user\";" "postgres"
  # Note: In PG, you also need to grant schema usage/privileges often, but DB level grant is a start.
  # For public schema:
  # run_query "\c $database; GRANT ALL ON SCHEMA public TO \"$user\";" # This is hard with -c to different DB.
  # We assume standard setup.
}

recreate_database() {
  local database="$1"
  local user="$2"
  local password="$3"
  echo "Recreating database $database and user $user."
  # Terminate connections first?
  run_query "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$database';" "postgres"
  drop_database "$database"
  create_database "$database"
  create_user "$database" "$user" "$password"
}

export_database() {
  local file="$1"
  echo "Exporting database $PG_DATABASE into $file."
  PGPASSWORD="$PG_PASSWORD" pg_dump \
    --host="$PG_HOST" \
    --username="$PG_USER" \
    --port="$PG_PORT" \
    --file="$file" \
    "$PG_DATABASE"
}

PG_HOST="${PG_HOST:-postgres.core.svc}"
PG_PORT="${PG_PORT:-5432}"
PG_USER="${PG_USER:-shared}"
PG_PASSWORD="${PG_PASSWORD}"
PG_DATABASE="${PG_DATABASE:-shared}"

if [ -z "$PG_HOST" ]; then
  echo "Missing required environment variable: PG_HOST"
  exit 1
fi

if [ -z "$PG_PORT" ]; then
  echo "Missing required environment variable: PG_PORT"
  exit 1
fi

if [ -z "$PG_USER" ]; then
  echo "Missing required environment variable: PG_USER"
  exit 1
fi

if [ -z "$PG_PASSWORD" ]; then
  echo "Missing required environment variable: PG_PASSWORD"
  exit 1
fi

if [ -z "$PG_DATABASE" ]; then
  echo "Missing required environment variable: PG_DATABASE"
  exit 1
fi
