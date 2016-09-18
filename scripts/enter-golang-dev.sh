#! /bin/bash

set -euo pipefail

ROOT_DIR=$(realpath $(dirname $0)/..)
source $ROOT_DIR/scripts/env.sh

docker run -it -v $(pwd):/go/src/$GO_PATH -w /go/src/$GO_PATH $GO_CONTAINER /bin/bash

