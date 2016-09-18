#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
source $ROOT_DIR/scripts/env.sh

cd $ROOT_DIR

echo "Starting database"
docker stop daemon_postgresql > /dev/null 2>&1 || true
docker kill daemon_postgresql > /dev/null 2>&1 || true
docker rm -v daemon_postgresql > /dev/null 2>&1 || true
docker run \
  -p 5432:5432 \
  -d \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_USER=daemon_admin \
  -e POSTGRES_DB=daemon \
  -v /home/core/postgresql_daemon:/var/lib/postgresql/data \
  -v /home/core/dev/daemon:/home/postgres/daemon \
  -v /home/core/dev/remotes:/home/postgres/remotes \
  --name daemon_postgresql \
  postgres:9.5

# Wait for db to come up
until ncat -w1 -e /bin/true 127.0.0.1 5432
do
  echo "Waiting for database"
  sleep 1
done

sleep 10

#run script to create base users
docker exec -u postgres daemon_postgresql psql -d daemon -U daemon_admin -w password -f /home/postgres/daemon/db/dbusers.sql

#run script to create remotes badge users
docker exec -u postgres daemon_postgresql psql -f /home/postgres/remotes/db/dbusers.sql

echo "Building DBMigrate"
docker run -t -v $(pwd):/go/src/$GO_PATH -w /go/src/$GO_PATH $GO_CONTAINER /go/src/$GO_PATH/scripts/build-dbmigrate.sh

# Daemon db
./bin/dbmigrate -h $POSTGRESQL_SERVICE_HOST -d $POSTGRESQL_SERVICE_DB -u daemon_admin -P password -f daemon/db/dbfiles.json -c

# Remotes db
./bin/dbmigrate -h $POSTGRESQL_REMOTE_HOST -d $POSTGRESQL_REMOTE_DB -u remote_admin -P password -f remotes/db/dbfiles.json -c

# build and run daemon
./scripts/run-dev-daemon.sh

#build and run official remotes
./scripts/run-dev-remotes.sh
