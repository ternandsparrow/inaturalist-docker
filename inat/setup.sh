#!/bin/bash
set -euxo pipefail
cd `dirname "$0"`/..

theHack='--no-check-certificate' # old wget doesn't trust LetsEncrypt
# allow us to install postgres 11 client (9.6 is latest in Debian Stretch base)
wget $theHack --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | apt-key add -
RELEASE=stretch # lsb_release isn't available at this point
grep $RELEASE /etc/apt/sources.list || {
  echo "[ERROR] expected release to be '$RELEASE' but it doesn't seem to be,
  cannot continue" > /dev/stderr
  exit 1
}
echo "deb http://apt.postgresql.org/pub/repos/apt/ ${RELEASE}-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

# ruby stuff
bundle install --jobs=3 &

curl -sL https://deb.nodesource.com/setup_10.x | bash -
# GEOS is for the tools/import_natural_earth_countries.rb rake task
apt-get install --no-install-recommends --assume-yes \
  git \
  nodejs \
  postgresql-client-11 \
  libimage-exiftool-perl \
  libgeos-dev

# node stuff
npm install

wait # for bundle

# tidy up
apt-get --assume-yes autoremove
apt-get --assume-yes clean
rm -rf \
 /var/lib/apt/lists/* \
 /tmp/* \
 /var/tmp/*
