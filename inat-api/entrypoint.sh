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

cat <<EOF > config.js
let environment = "development";
if ( global && global.config && global.config.environment ) {
  environment = global.config.environment; // eslint-disable-line prefer-destructuring
}
if ( process && process.env && process.env.NODE_ENV ) {
  environment = process.env.NODE_ENV;
}
module.exports = {
  environment,
  // Host running the iNaturalist Rails app
  apiURL: "$inatAppUrl",
  // Base URL for the current version of *this* app
  currentVersionURL: "$thisApiPublicUrl",
  // Whether the Rails app supports SSL requests. For local dev assume it does not
  apiHostSSL: false,
  writeHostSSL: false,
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
