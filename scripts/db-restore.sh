#!/bin/bash
# performs a pg_restore on the docker container and reads the input from a file
# on the docker host
cd `dirname "$0"`

inFile=${1:?the first param must be the dump file (on the docker host)}
shift
otherArgs="$@"

cat $inFile | docker exec \
  -i \
  inat_db \
  sh -c "cat - | pg_restore \
     --format=c \
    -U \$POSTGRES_USER \
    -d inaturalist $otherArgs"

RC=$?
[ "$RC" = "0" ] \
  && echo "[INFO] restored custom format Postgres dump from $inFile" \
  || echo '[ERROR] failed to perform restore'
