#! /bin/sh

set -euo pipefail

export GO_PATH=github.com/thedarknet/daemon4
export GO_CONTAINER=golang:1.6

export POSTGRESQL_SERVICE_PASSWORD=darknet_user
export POSTGRESQL_SERVICE_USER=darknet_user
export POSTGRESQL_SERVICE_DB=daemon
export POSTGRESQL_SERVICE_HOST=172.17.100.101

export POSTGRESQL_REMOTE_PASSWORD=badge_user
export POSTGRESQL_REMOTE_USER=badge_user
export POSTGRESQL_REMOTE_DB=remotes
export POSTGRESQL_REMOTE_HOST=172.17.100.101

export DAEMON_ENFORCE_AUTH="false"
export DAEMON_HMAC_KEY=abcdef