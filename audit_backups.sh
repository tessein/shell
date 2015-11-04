#!/bin/bash

SRVR=$1
COMPARE_DIR=$(ssh $SRVR 'sudo ls -tr /data/database_backups/ | tail -n1')
echo -e "Auditing archives in directory $COMPARE_DIR on server $SRVR"

diff -x'^$' <(mysql -h$SRVR -ssB -u$2 -p$3 information_schema 
  -e"SELECT TABLE_NAME FROM TABLES WHERE TABLE_SCHEMA NOT IN ('lsnort0','wsnort0','information_schema','xxx')" | sed 's/\$/\@0024/g' | sort) 
    <(ssh $SRVR "sudo find /data/database_backups/$COMPARE_DIR -type f ! -name binary_log.?????? -exec basename {} \;" 
          | egrep -v 'lsnort0|wsnort0|information_schema|xxx' | cut -d- -f5 | cut -d. -f1 | sed "/^$/d"|sort)

echo -e "\tRC: $?"
