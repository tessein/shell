#!/bin/bash

# Hunts down replication statements that cannot be eaten
# The work is done here
function checkBinlogs () {
  # no parameter, no work to be done
  [[ -z "$1" ]] && return
  [[ -z "$2" ]] && return

  echo STARTING SERVER CHECKS
  echo ----------------------
  echo "--> Look for log files preceded with an asterisk - they might"
  echo contain statements from dead servers.
  echo
  # check each slave
  for SLAVE in ${SLAVE_NAMES[@]}
  do
    echo $SLAVE && echo '---------------------------'
    ssh $SLAVE 'for LOG in /usr/local/mysql/log/binary_log.??????;do sudo $MYSQL/bin/mysqlbinlog -uxxxxxxxx -pxxxxxxxx $LOG|grep "server id "| egrep -v "server id ($1)" > /dev/null; if [ $? = 0 ]; then echo -n \*\ ;else echo -n '  ';fi;echo $LOG;done'
  done
}

MASTER_IDS=$(mysql -ssB -uxxxxxxxx -pxxxxxxxx -hxxxxxxxx sysadmin -e"SELECT server_id FROM repl_status WHERE active = 'true' AND role = 'master'")
MASTER_IDS=$(echo $MASTER_IDS|sed 's/ /|/g')
SLAVE_IDS=$(mysql -ssB -uxxxxxxxx -pxxxxxxxx -hlocalhost sysadmin -e"SELECT server_id FROM repl_status WHERE active = 'true' AND role = 'slave'")
SLAVE_IDS=$(echo $SLAVE_IDS|sed -e 's/ /,/g' -e "s/,/','/g"  -e "s/^/'/" -e "s/$/'/")
SLAVE_NAMES=$(mysql -ssB -uxxxxxxxx -pxxxxxxxx -hlocalhost sysadmin -e"SELECT host FROM repl_status WHERE server_id IN ($SLAVE_IDS)")

checkBinlogs $MASTER_IDS $SLAVE_NAMES
