#!/bin/bash

# Get the directory of the current script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$DIR/lib_mysql.sh"

SQL_DIR="$DIR/sql"

if [ ! -d "$SQL_DIR" ]; then
  echo "SQL directory not found: $SQL_DIR"
  exit 0
fi

# Iterate through SQL files in alphabetical order
for file in "$SQL_DIR"/*.sql; do
  [ -e "$file" ] || continue
  echo "Processing $(basename "$file")..."

  # Extract version from the INSERT INTO intDbupdate line
  # Matches pattern: VALUES ('version', ...
  version=$(grep -i "INSERT INTO .*intDbupdate" "$file" | head -n 1 | sed -n "s/.*VALUES[[:space:]]*('\([^']*\)'.*/\1/p")

  if [ -z "$version" ]; then
    echo "Warning: Could not find version in $(basename "$file"). Skipping."
    continue
  fi

  echo "Detected version: $version"

  # Check if version is already applied
  count=$(run_query_silent "SELECT count(*) FROM intDbupdate WHERE Dbversion = '$version';")

  if [ "$count" -gt 0 ]; then
    echo "Version $version already applied. Skipping."
    continue
  fi

  echo "Applying version $version..."

  # Create a temporary file with the replaced database name
  tmp_file=$(mktemp)
  sed "s/<my_db_name>/$MYSQL_DATABASE/g" "$file" > "$tmp_file"

  # Import the updated SQL file
  import_sql_file "$tmp_file"
  
  if [ $? -eq 0 ]; then
    echo "Successfully applied $version."
  else
    echo "Error applying $version. Aborting."
    rm "$tmp_file"
    exit 1
  fi

  rm "$tmp_file"
done

echo "All updates processed."
