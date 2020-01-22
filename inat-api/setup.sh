#!/bin/bash
set -euxo pipefail
cd `dirname "$0"`/..

export NODE_ENV=production
# this will blow up with permission denied errors if we run as root (yeah, go
# figure). The `--unsafe-perm` flag doesn't seem to help. So we just run as
# a non-root user (done in Dockerfile), which is probably smart anyway.
npm ci
