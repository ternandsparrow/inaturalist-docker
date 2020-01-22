#!/bin/bash
# drops you into a psql shell inside the docker container

docker exec \
  -it \
  inat_db \
  sh -c 'psql -U $POSTGRES_USER -d inaturalist'
