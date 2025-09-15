#!/bin/bash

. shared.sh

gcloud_auth
check_env

rename_tables() {
  local file="import.sql"
  curl https://www.skywinner.se/skywin/_files/sql_ddl/MySQL.Rename_all_tables.sql | sed 's/<my_skywin>/skywin/' >$file
  import_sql_file "$file"
}

rename_tables
