#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
cd $ROOT_DIR

go test github.com/thedarknet/daemon4/daemon/main
go test github.com/thedarknet/daemon4/daemon/service
go test github.com/thedarknet/daemon4/daemon/service/internal/data
go test github.com/thedarknet/daemon4/daemon/service/internal/msg
go test github.com/thedarknet/daemon4/daemon/service/internal/player
go test github.com/thedarknet/daemon4/daemon/service/internal/v1/content
go test github.com/thedarknet/daemon4/daemon/service/internal/v1/player
go test github.com/thedarknet/daemon4/daemon/service/internal/v1/test

