#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR/lib_mysql.sh"

delete_all_requests() {
  echo "Deleting all rows from $MYSQL_DATABASE.loadjumprequest..."
  run_query "DELETE FROM $MYSQL_DATABASE.loadjumprequest;"
  echo "Done."
}

randomize_and_reset_time() {
  echo "Randomizing order and resetting TimeForRequest starting at 07:00:00..."
  # Start time at 06:59:59 so the first increment results in 07:00:00
  local query="SET @t = TIMESTAMP(CURDATE(), '06:59:59'); UPDATE $MYSQL_DATABASE.loadjumprequest SET TimeForRequest = (@t := @t + INTERVAL 1 SECOND) ORDER BY RAND();"
  run_query "$query"
  echo "Done."
}

case "$1" in
  delete)
    delete_all_requests
    ;;
  shuffle)
    randomize_and_reset_time
    ;;
  *)
    echo "Usage: $0 {delete|shuffle}"
    exit 1
    ;;
esac