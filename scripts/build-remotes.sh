#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
cd $ROOT_DIR

for r in $(find remotes -mindepth 1 -maxdepth 1 -type d -not -path "*/db")
do
	name=$(basename $r)
	echo Building $name
	CGO_ENABLED=0 go build -a -installsuffix cgo -o bin/$name remotes/$name/main/*.go
done
