#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
source $ROOT_DIR/scripts/env.sh

echo "Building remotes"
docker run -t -v $(pwd):/go/src/$GO_PATH -w /go/src/$GO_PATH $GO_CONTAINER /go/src/$GO_PATH/scripts/build-remotes.sh

PORT=9001
for r in $(find remotes -mindepth 1 -maxdepth 1 -type d -not -path "*/db")
do
	name=$(basename $r)

	DOCKERFILE=$(sed -b "s/{{NAME}}/$name/gp" RemoteDockerfile)
	echo "$DOCKERFILE" > Dockerfile.tmp

	echo Building $name container
	docker build -t $name -f "Dockerfile.tmp" .

	echo Running $name
	docker stop $name > /dev/null 2>&1 || true
	docker kill $name > /dev/null 2>&1 || true
	docker rm -v $name > /dev/null 2>&1 || true
	docker run \
	  -p $PORT:8080 \
	  -e POSTGRESQL_SERVICE_PASSWORD=$POSTGRESQL_REMOTE_PASSWORD \
	  -e POSTGRESQL_SERVICE_USER=$POSTGRESQL_REMOTE_USER \
	  -e POSTGRESQL_SERVICE_DB=$POSTGRESQL_REMOTE_DB \
	  -e POSTGRESQL_SERVICE_HOST=$POSTGRESQL_REMOTE_HOST \
	  -d \
	   --name $name \
	  $name

	echo "$name running on port $PORT"
	PORT=$((PORT+1))
done




