#!/bin/bash

. mysql.sh

file="import.sql"
curl https://www.skywinner.se/skywin/_files/sql_ddl/MySQL.Rename_all_tables.sql | sed 's/<my_skywin>/skywin/' >$file

import_sql_file "$file"
if [ $? -ne 0 ]; then
  echo "Failed to import $file into MySQL."
  exit 3
fi
echo "Successfully imported $file into $MYSQL_DATABASE"

rm "$file"
