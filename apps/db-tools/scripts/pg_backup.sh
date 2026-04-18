#!/bin/bash

. lib_gcloud.sh
. lib_pgsql.sh

DATABASES_CONFIG="${PG_DATABASES_CONFIG:-${PG_DATABASE:-shared}:shared}"
IFS=',' read -r -a db_configs <<< "$DATABASES_CONFIG"

for config in "${db_configs[@]}"; do
  db="${config%%:*}"
  db=$(echo "$db" | xargs)
  if [ -z "$db" ]; then continue; fi

  export PG_DATABASE="$db"
  file="${db}_backup.sql"
  export_database $file
  upload_file $file ${PG_BACKUP_LOCATION}/${db}-$(date +%Y%m%d-%H%M%S).sql
done
