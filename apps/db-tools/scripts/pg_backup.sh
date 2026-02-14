#!/bin/bash

. lib_gcloud.sh
. lib_pgsql.sh

file="${PG_DATABASE}_backup.sql"
export_database $file
upload_file $file ${PG_BACKUP_LOCATION}/${PG_DATABASE}-$(date +%Y%m%d-%H%M%S).sql
