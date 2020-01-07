#!/bin/bash
bpath=/builds/backups/sonarqube
fname="sonar-postgres-"`date +%m-%d-%Y`".sql"
echo "backing up $fname to $bpath"
cd $bpath
#remove backups older than 30 days
find $bpath -type f -name "sonar-postgres*" -mtime +30 -exec rm -f {} \;

pg_dump sonar > $fname
