#!/bin/bash

find_latest_file() {
  local path="$1"
  gsutil ls -l $path | sort -k2 -nr | head -n1 | awk '{print $3}'
}

download_file() {
  local remote_file="$1"
  local local_file="$2"
  if ! gsutil cp "$remote_file" "$local_file"; then
    echo "Failed to download file from GCS."
    exit 2
  fi
  echo "Successfully downloaded file into $local_file."
}

gcloud auth activate-service-account --key-file=/usr/src/credentials/application-credentials.json
if [ $? -ne 0 ]; then
  echo "Failed to authenticate service account."
  exit 3
fi
echo "Successfully authenticated to gcloud."
