#!/bin/bash
# performs a pg_dump on the docker container and writes the output a file on
# the docker host
cd `dirname "$0"`

outFile=${1:?the first param must be the dump output file (on the docker host)}

docker exec \
  -it \
  inat_db \
  sh -c 'pg_dump \
    --format=c \
    -U $POSTGRES_USER \
    -d inaturalist' > $outFile

echo "[INFO] wrote custom format Postgres dump to $outFile"
ls -lh $outFile
