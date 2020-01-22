set -euxo pipefail
psql -d template_postgis -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";'
