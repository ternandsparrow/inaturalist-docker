#!/bin/bash
# entrypoint for the iNat API docker container
set -euxo pipefail
cd $TARGET_DIR # defined in Dockerfile

inatAppUrl=${PUBLIC_INAT_APP_URL:?}
thisApiPublicUrl=${PUBLIC_URL:?}
dbHost=${DB_HOST:?}
dbUser=${DB_USER:?}
dbPass=${DB_PASS:?}
dbName=inaturalist
esHost=${ES_HOST:?}
esPort=${ES_PORT:-9200}
srid=4326
tempDirPath=${TEMP_DIR_PATH:-/tmp}

# copy the logic in ../inat/inaturalist/lib/elastic_model/acts_as_elastic_model.rb
# this is required for the API to hit the same ES indexes as Rails
if [ "$NODE_ENV" == "prod_dev" ]; then
  # FIXME it would be nice if this logic also affected `docker exec` shells
  export NODE_ENV=production
fi

cat <<EOF > config.js
const environment = "${NODE_ENV:-development}"
module.exports = {
  environment,
  // Host running the iNaturalist Rails app
  apiURL: "$inatAppUrl",
  // Base URL for the current version of *this* app
  currentVersionURL: "$thisApiPublicUrl",
  // Whether the Rails app supports SSL requests. For local dev assume it does not
  apiHostSSL: false,
  writeHostSSL: false,
  jwtSecret: '${JWT_SECRET:-secret}',            // must match config on Rails
  jwtApplicationSecret: '${JWT_SECRET:-secret}', // must match config on Rails
  elasticsearch: {
    host: "$esHost:$esPort",
    geoPointField: "location",
    searchIndex: \`\${environment}_observations\`,
    placeIndex: \`\${environment}_places\`
  },
  database: {
    user: "$dbUser",
    host: "$dbHost",
    port: 5432,
    geometry_field: "geom",
    srid: $srid,
    dbname: "$dbName",
    password: "$dbPass",
    ssl: false
  },
  tileSize: 512,
  debug: ${API_DEBUG:-true},
  imageProcesing: {
    taxaFilePath: "",
    uploadsDir: "${tempDirPath}",
    tensorappURL: ""
  }
}
EOF

# FIXME do we need to use PM2?
node app.js
