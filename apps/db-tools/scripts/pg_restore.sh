#!/bin/bash

. lib_gcloud.sh
. lib_pgsql.sh

DATABASES_CONFIG="${PG_DATABASES_CONFIG:-${PG_DATABASE:-shared}:shared}"
IFS=',' read -r -a db_configs <<<"$DATABASES_CONFIG"

for config in "${db_configs[@]}"; do
  db="${config%%:*}"
  db_user="${config##*:}"
  db=$(echo "$db" | xargs)
  db_user=$(echo "$db_user" | xargs)
  if [ -z "$db" ]; then continue; fi

  # Look up the specific password for this database
  db_upper=$(echo "$db" | tr 'a-z' 'A-Z' | tr '-' '_')
  pass_var="DB_PASSWORD_${db_upper}"
  # If DB_PASSWORD_... is not set, fallback to global PG_PASSWORD
  db_password="${!pass_var:-$PG_PASSWORD}"

  echo "Processing database: $db (user: $db_user)"

  # Find latest backup for this DB
  latest_file=$(find_latest_file $PG_BACKUP_LOCATION/${db}-*.sql)
  if [ -z "$latest_file" ]; then
    echo "No files found for $db in $PG_BACKUP_LOCATION. Skipping."
    continue
  fi

  file="${db}.sql"
  download_file $latest_file $file

  recreate_database "$db" "$db_user" "$db_password"
  if [ $? -ne 0 ]; then
    echo "Failed to recreate database $db."
    continue
  fi
  echo "Database $db recreated successfully."

  export PG_DATABASE="$db"
  import_sql_file $file
  if [ $? -ne 0 ]; then
    echo "Failed to import $file into $db."
    continue
  fi
  echo "Successfully imported $file into $db"

  rm "$file"
done

echo "Restore process completed."
