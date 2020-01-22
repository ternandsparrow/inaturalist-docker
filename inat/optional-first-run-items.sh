#!/bin/bash
# executes rake tasks that populate a fresh iNat instance with useful data
set -euxo pipefail
cd `dirname "$0"`/..

rails runner tools/load_sources.rb
rails runner tools/load_iconic_taxa.rb
rails runner tools/build_observations_mapnik_xml.rb
rails runner tools/import_natural_earth_countries.rb

# includes what es:index does, which is good because es:index refuses to run
# without the elasticsearch binary being present. It's in a different container
# for us
rake es:rebuild
