#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
source $ROOT_DIR/scripts/env.sh

docker run -t \
	-v $(pwd):/go/src/$GO_PATH \
	-w /go/src/$GO_PATH \
	-e POSTGRESQL_SERVICE_PASSWORD=$POSTGRESQL_SERVICE_PASSWORD \
  	-e POSTGRESQL_SERVICE_USER=$POSTGRESQL_SERVICE_USER \
  	-e POSTGRESQL_SERVICE_DB=$POSTGRESQL_SERVICE_DB \
  	-e POSTGRESQL_SERVICE_HOST=$POSTGRESQL_SERVICE_HOST \
    -e DAEMON_ENFORCE_AUTH=$DAEMON_ENFORCE_AUTH \
    -e DAEMON_HMAC_KEY=$DAEMON_HMAC_KEY \
  	$GO_CONTAINER /go/src/$GO_PATH/scripts/test-$1-daemon.sh;
