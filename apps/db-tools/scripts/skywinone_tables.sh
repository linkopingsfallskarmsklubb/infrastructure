#!/bin/bash

. gcloud.sh
. mysql.sh

file="sql/01_create_skywinone_custom.sql"

import_sql_file "$file"
if [ $? -ne 0 ]; then
  echo "Failed to import $file into MySQL."
  exit 3
fi
echo "Successfully imported $file into $MYSQL_DATABASE"

rm "$file"
