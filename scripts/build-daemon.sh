#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
cd $ROOT_DIR

CGO_ENABLED=0 go build -a -installsuffix cgo -o bin/daemon daemon/main/*.go
