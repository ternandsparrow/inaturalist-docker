#!/bin/bash
# entrypoint for the iNat app docker container
set -euxo pipefail
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd `dirname "$0"`/..

siteUrl=${PUBLIC_URL} # will be inlined into HTML for the client so must be publicly resolvable
isDisableDevAssetsDebug=${DISABLE_DEV_ASSETS_DEBUG:-0}
dbHost=${DB_HOST:?}
dbUser=${DB_USER:?}
dbPass=${DB_PASS:?}
esHost=${ES_HOST:?}
esPort=${ES_PORT:-9200}
inatApiUrl=${PUBLIC_INAT_API_URL}
# FIXME get these files, build them into the Docker image, update path
tilestacheFilesPath=/Users/kueda/projects/TileStache/data
# note RAILS_ENV will affect all rake and rails commands (in a good way)

# FIXME it would be nice to have a single database that this app uses. Rails
# doesn't like that and you need to define a separate DB for each env (they
# can't be the same). We might be able to work around this by branching based
# on the env name and settings 'inaturalist' as our main DB name and generating
# something else for the unused envs. This would let us swap between dev and
# prod modes but keep connecting to the same DB.
inatDbName=inaturalist

# set any of these env vars to 'true' to enable
[ "${IS_ENABLE_GOOGLE_ANALYTICS:-false}" = true ] && enableGA='' || enableGA='#'

cat <<EOF > $CONFIG_VOL_DIR/database.yml
login: &login
  host: db
  encoding: utf8
  adapter: postgis
  username: $dbUser
  password: $dbPass
  template: template_postgis

development: &dev
  <<: *login
  database: $inatDbName

test:
  <<: *dev

prod_dev:
  <<: *dev

production:
  <<: *dev
EOF

cat <<EOF > $CONFIG_VOL_DIR/config.yml
base: &base

  priority_zones:
    - US
    - Arizona
    - Indiana
    - Hawaii
    - Alaska

  jwt_secret: ${JWT_SECRET:-secret}
  jwt_application_secret: ${JWT_APPLICATION_SECRET:-application_secret}

  rest_auth:
      # See vendor/plugins/restful_authentication/notes/Tradeoffs.txt for more info
      REST_AUTH_SITE_KEY: ${REST_AUTH_SITE_KEY:-09af09af09af09af09af09af09af09af09af09af}
      REST_AUTH_DIGEST_STRETCHES: ${REST_AUTH_DIGEST_STRETCHES:-10}

  rails:
      # Issue {rake secret} to get a new one
      session_key: ${RAILS_SESSION_KEY:-_yoursite_session}
      secret: ${RAILS_SECRET:-09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af09af}

  $enableGA google_analytics:
  $enableGA     # http://www.google.com/analytics/sign_up.html
  $enableGA     tracker_id: ${GOOGLE_ANALYTICS_TRACKER_ID:-UA-090909-9}
  $enableGA     domain_name: ${GOOGLE_ANALYTICS_DOMAIN_NAME:-yoursite.org}

  ubio:
      # http://www.ubio.org/index.php?pagename=form
      key: ${UBIO_KEY:-09af09af09af09af09af09af09af09af09af09af}

  yahoo_dev_network:
      # first need Yahoo account: https://edit.yahoo.com/registration
      # then need to sign up for Yahoo Developers Network app interface:
      # https://developer.apps.yahoo.com/wsregapp/
      app_id: ${YAHOO_DEV_NETWORK_APP_ID:-09azAZ09azAZ09azAZ09azAZ09azAZ09azAZ09az09azAZ09azAZ09azAZ09}

  airbrake:
      # https://airbrake.io/
      disable: ${AIRBRAKE_DISABLE:-false}
      api_key: ${AIRBRAKE_API_KEY:-09af09af09af09af09af09af09af09af09af09af}

  tile_servers:
      # EXPERIMENTAL: These endpoints should return map tiles when hit with
      # requests like /{Z}/{X}/{Y}.png.
      # See http://bitbucket.org/springmeyer/tilelite/
      observations: '${TILE_SERVER_OBSERVATIONS_URL:-http://localhost:8000}'
      tilestache: '${TILE_SERVER_TILESTACHE_URL:-http://localhost:8000}'
      elasticsearch: '$inatApiUrl'

  google_webmaster:
      verification: ${GOOGLE_WEBMASTER_VERIFICATION:-abiglongkey}

  s3_bucket: ${AWS_S3_BUCKET_NAME:-yourbucketname}
  s3_protocol: ${AWS_S3_BUCKET_PROTOCOL:-https}
  s3_region: ${AWS_S3_BUCKET_REGION:-us-east-1}

  memcached: ${MEMCACHED_HOST:?}

  # Key for spam filtering with akismet. See http://akismet.com/development/api/
  rakismet:
    key: ${RAKISMET_KEY:-abc123}
    site_url: ${RAKISMET_SITE_URL:-http://www.yoursite.com}

  # facebook:
  #     app_id: 00000000000
  #     app_secret: 09af09af09af09af09af09af09af09af09af09af
  #     # facebook user IDs of people who can admin pages on the site
  #     admin_ids: [1,2]
  #     namespace: appname # your facebook app's namespace, used for open graph tags

  # twitter:
  #     key: 09af09af09af09af09af09af09af09af09af09af
  #     secret: 09af09af09af09af09af09af09af09af09af09af
  #     username: your_twitter_username

  # cloudmade:
  #     key: 09af09af09af09af09af09af09af09af09af09af

  # bing:
  #     # http://www.bingmapsportal.com/
  #     key: 09af09af09af09af09af09af09af09af09af09af

  flickr:
      # http://www.flickr.com/services/api/keys/apply/
      key: 09af09af09af09af09af09af09af09af
      shared_secret: 09af09af09af09af

  soundcloud:
      # http://soundcloud.com/you/apps/new
      client_id: 09af09af09af09af09af09af09af09af
      secret: 09af09af09af09af09af09af09af09af

  google:
      # https://developers.google.com/maps/documentation/javascript/get-api-key#get-an-api-key
      browser_api_key: ${GOOGLE_MAPS_API_KEY:-09af09af09af09af09af09af09af09af}

  metadata_provider:

  creator:

  # natureserve:
  #     key: 0x0x0x0x0x0x0x0x

  # config.action_dispatch.x_sendfile_header. Most servers use X-Sendfile, but nginx prefers X-Accel-Redirect
  x_sendfile_header: 'X-Accel-Redirect'

  # # GBIF login credentials. Currently only used in
  # # tools/gbif_observation_links.rb, so only useful if you send data
  # # to GBIF
  # gbif:
  #     username: yourusername
  #     password: yourpassword
  #     notification_address: you@you.com

  # Elastic search for search indexing, other performance improvements
  # ES also runs a syncing service on port 9300 by default. You want to use
  # the API port. See
  # http://stackoverflow.com/questions/19510659/java-io-streamcorruptedexception-invalid-internal-transport-message-format
  # for more details
  elasticsearch_host: http://$esHost:$esPort

  # An instance of https://github.com/inaturalist/iNaturalistAPI, the
  # same code running at CONFIG.tile_servers.elasticsearch
  node_api_url: $inatApiUrl

development:
    <<: *base

test:
    <<: *base

prod_dev:
    <<: *base

production:
    <<: *base
EOF

cat <<EOF > $CONFIG_VOL_DIR/smtp.yml
:address: ${MAIL_HOST}
:port: ${MAIL_PORT:-587}
:user_name: ${MAIL_USER}
:domain: "${MAIL_DOMAIN:-}"
:password: ${MAIL_PASS}
:authentication: :${MAIL_AUTH_TYPE:-plain}
EOF

cat <<EOF > $CONFIG_VOL_DIR/secrets.yml
<% config = YAML.load(File.open("#{Rails.root}/config/config.yml")) %>
development: &dev
  secret_key_base: <%= config[Rails.env]['rails']['secret'] %>

test:
  <<: *dev

prod_dev:
  <<: *dev

production:
  <<: *dev
EOF

# FIXME do we even need memcached for non-prod deployments?
# FIXME do we need to configure the dbname?
cat <<EOF > $CONFIG_VOL_DIR/tilestache.cfg
{
  "cache": {
    "name": "Multi",
    "tiers": [
      {
        "name": "Memcache",
        "servers": ["memcached:11211"]
      },
      {
        "name": "Disk",
        "path": "/tmp/stache",
        "gzip": ["xml", "json", "geojson"]
      }
    ]
  },
  "layers": {
    "observations":
    {
      "provider": {
        "name": "vector",
        "driver": "PostgreSQL",
        "clipped": false,
        "parameters": {
          "dbname": "$inatDbName",
          "query": "SELECT id as observation_id, * FROM observations"
        },
        "properties": {"observation_id": "id", "taxon_id": "taxon_id", "quality_grade": "quality_grade"}
      },
      "cache lifespan": 86400,
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "counties": {
      "provider": {
        "name": "vector",
        "driver": "PostgreSQL",
        "clipped": "padded",
        "parameters": {
          "dbname": "$inatDbName",
          "query": "SELECT places.*, place_geometries.geom FROM places JOIN place_geometries ON places.id = place_geometries.place_id WHERE places.place_type = 9"
        }
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "counties_simplified_1": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/counties_simplified_1.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "counties_simplified_01": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/counties_simplified_01.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "states_simplified_1": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/states_simplified_1.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "states_simplified_01": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/states_simplified_01.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "countries_simplified_1": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/countries_simplified_1.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "countries_simplified_01": {
      "provider": {
        "name": "vector",
        "driver": "shapefile",
        "clipped": "padded",
        "parameters": {
          "file": "${tilestacheFilesPath}/countries_simplified_01.shp"
        },
        "properties": {"ID": "id"}
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    },
    "openspace": {
      "provider": {
        "name": "vector",
        "driver": "PostgreSQL",
        "parameters": {
          "dbname": "$inatDbName",
          "query": "SELECT places.*, place_geometries.geom FROM places JOIN place_geometries ON places.id = place_geometries.place_id WHERE places.place_type = 100"
        }
      },
      "preview": {"ext": "geojson"},
      "allowed origin": "*"
    }
  }
}
EOF

$scriptDir/symlink-config-files-from-volume.sh

# this file is on the DB data volume because that's the state we're assessing.
# this container might get recreated many times but the DB won't need init-ing.
initDoneFile=/pgdata/init.done

if [ ! -f "$initDoneFile" ]; then
  echo '[INFO] running one-time setup'
  rake db:setup
  echo `date` > $initDoneFile
  cat <<EORUBY | rails console
    s = Site.create(
      name: '${SITE_NAME:-iNat Docker Full Site Name}',
      url: '$siteUrl'
    )
    Preference.create(
      name: 'email_noreply',
      owner_id: s.id,
      owner_type: 'Site',
      value: '${EMAIL_NOREPLY:-noreply@changeme.local}'
    )
    Preference.create(
      name: 'site_name_short',
      owner_id: s.id,
      owner_type: 'Site',
      value: '${SITE_NAME_SHORT:-inat_dkr}'
    )
EORUBY
  ofriScript=$scriptDir/optional-first-run-items.sh
  [ "${FAST_START}" = false ] && {
    bash $ofriScript
  } || echo "[INFO] skipping optional first run items, 'docker exec' in and run
$ofriScript manually if needed"
else
  echo "[INFO] skipping one-time setup. To force re-run, delete the '$initDoneFile' file"
  rake db:migrate
  # FIXME can (should) we also run es:rebuild?
fi

if [ $isDisableDevAssetsDebug == 1 ]; then
  # provides a slight speed-up in dev mode by allowing assets to be cached
  echo "[INFO] disabling config.assets.debug for dev"
  sed -i 's/\(\s*config.assets.debug\).*/\1 = false/' config/environments/development.rb
fi

# avoid stale assets after config changes
rake assets:clobber

# FIXME is this a production-ish grade app server?
echo "[INFO] running with rails env=$RAILS_ENV"
rails server \
  --binding=0.0.0.0
