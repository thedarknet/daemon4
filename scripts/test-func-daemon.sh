#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
cd $ROOT_DIR

go test github.com/thedarknet/daemon4/daemon/functional
