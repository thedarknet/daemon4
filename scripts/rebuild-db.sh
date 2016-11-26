source ./scripts/env.sh
./bin/dbmigrate -h $POSTGRESQL_SERVICE_HOST -d $POSTGRESQL_SERVICE_DB -u daemon_admin -P password -f daemon/db/dbfiles.json -c

