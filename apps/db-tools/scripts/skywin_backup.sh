#!/bin/bash

. lib_gcloud.sh
. lib_mysql.sh

file="skywin_backup.sql"
export_database $file
upload_file $file $SKYWIN_BACKUP_LOCATION/skywin-$(date +%Y%m%d-%H%M%S).sql
