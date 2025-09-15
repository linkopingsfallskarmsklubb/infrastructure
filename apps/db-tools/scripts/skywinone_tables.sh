#!/bin/bash

. shared.sh

gcloud_auth
check_env

create_skywinone_tables() {
  local file="import.sql"
  curl https://www.skywinner.se/skywin/_files/skywinone/sql/SkyWinOne_tables.sql | sed 's/<my_skywin>/skywin/' >$file
  import_sql_file "$file"
}

create_skywinone_tables
