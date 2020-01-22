#!/bin/bash
# create all the symlinks to config files that live on our docker volume
set -euo pipefail
cd `dirname "$0"`/../config

for curr in $CONFIG_VOL_DIR/*.{yml,cfg}; do
  echo "[symlink config] creating symlink for $curr"
  ln --force --symbolic $curr
done
