#!/bin/bash

. gcloud.sh
. mysql.sh

file="import.sql"
curl https://www.skywinner.se/skywin/_files/skywinone/sql/SkyWinOne_tables.sql | sed 's/<my_skywin>/skywin/' >$file
import_sql_file "$file"
rm "$file"
