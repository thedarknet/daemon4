#!/bin/bash

if [ ! -f target/DBSetup-1.0.1-jar-with-dependencies.jar ]
then
	mvn clean
	mvn install
fi


export TOOLSPATH=/src/tools 
export DBPATH=/db 
/db/purge_migrate_db.sh


