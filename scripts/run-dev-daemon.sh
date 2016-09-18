#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
source $ROOT_DIR/scripts/env.sh

echo "Building daemon"
docker run -t -v $(pwd):/go/src/$GO_PATH -w /go/src/$GO_PATH $GO_CONTAINER /go/src/$GO_PATH/scripts/build-daemon.sh

echo "Building daemon container"
docker build -t daemon .

echo "Running daemon"
docker stop daemon > /dev/null 2>&1 || true
docker kill daemon > /dev/null 2>&1 || true
docker rm -v daemon > /dev/null 2>&1 || true
docker run \
  -p 8080:8080 \
  -e POSTGRESQL_SERVICE_PASSWORD=$POSTGRESQL_SERVICE_PASSWORD \
  -e POSTGRESQL_SERVICE_USER=$POSTGRESQL_SERVICE_USER \
  -e POSTGRESQL_SERVICE_DB=$POSTGRESQL_SERVICE_DB \
  -e POSTGRESQL_SERVICE_HOST=$POSTGRESQL_SERVICE_HOST \
  -e DAEMON_ENFORCE_AUTH=$DAEMON_ENFORCE_AUTH \
  -e DAEMON_HMAC_KEY=$DAEMON_HMAC_KEY \
  -d \
   --name daemon \
  daemon

echo "Daemon running on port 8080"


