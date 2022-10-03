#!/bin/bash

# update this servers array based on your needs
minio_servers_dev=("my-server-alias1" "my-server-alias2")

calculate_minio_usage() {
  minioserver=${1}
  echo "Bucket usage on: ${minioserver}"
  buckets=$(echo mc du ${minioserver}/{`mc ls ${minioserver} | awk '{print $5}' | sed 's/\///g' | sed ':a;N;$!ba;s/\n/,/g'`})
  echo ${buckets} | sh | awk '{print $4" "$1}'
  echo "##########################################################################"
}

for server in ${minio_servers_dev[@]}; do
  calculate_minio_usage ${server}
done
