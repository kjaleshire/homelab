#!/usr/bin/env bash

set -euo pipefail

cd /tmp

# echo Waiting a few seconds for network stability
# sleep 5

echo Making backup
DUMPFILE=mysqldump-$(date +"%Y%m%d%H%M%S").sql
mysqldump --defaults-extra-file=/etc/mysql/mysqlpassword.cnf --host=mysql --user=root --result-file=/tmp/$DUMPFILE --all-databases --verbose

echo Finished backup
echo Compressing

bzip2 --verbose --verbose $DUMPFILE

echo Finished compressing
echo Uploading

rclone copy --progress $DUMPFILE.bz2 $REMOTE_DEST

echo Done
