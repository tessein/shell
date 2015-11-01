#!/bin/bash
DB_USER='xxxxxxxx'
DB_PASSWORD='xxxxxxxx'
DISCLAIMER="The following SQL was executed concurrently by dbScriptRunner. Please check the log for errors."
MAIL_FROM='root@xxx.com'
MAIL_TO='bugman@zzz.com'
MAX_MAIL_BODY_SIZE=100000
SCRIPTRUNNER="dbScriptRunner"
SERVERS=$(mysql -ssB -hxxxxxxxx -pyyyyyyyy sysadmin -e"SELECT host from repl_status WHERE active = 'true'")
#SERVERS="wslavedb1 slavedb1"

#mysql -tvvv -hxxxxxxxx -u$DB_USER -p$DB_PASSWORD sysadmin -e"UPDATE dbScriptRunner SET isRunning = 'true'"

# first verify number of parameters
if [ $# -eq 1 ]
then
  LOGFILE=$1/$SCRIPTRUNNER-`basename $PWD`-`date +\%Y\%m\%d-\%H\%M`-$RANDOM.log
else
  [[ $1 != "-d" ]] && echo If > 1 parameter, first must be -d && exit 255
  LOGFILE=$2/$SCRIPTRUNNER-`basename $PWD`-`date +\%Y\%m\%d-\%H\%M`-$RANDOM.log
  DELETE_FILES=1
fi

# set up I/O redirection
touch $LOGFILE
exec 6>&1
exec > $LOGFILE # stdout redirected to $LOGFILE

echo "Starting dbScriptRunner $(date -R)"

concur () {
  MAXJOBS=100
  AFILE=$1
  shift
  THIS_DB=${AFILE%.*}
  while [ $# -gt 0 ]
  do
    NUM_JOBS=(`jobs -p`)
    if [ ${#NUM_JOBS[@]} -lt $MAXJOBS ]
    then
      JOBLOG="/tmp/$THIS_DB.$$"
      echo "mysql -tvvv -h$1 -p$DB_PASSWORD -u$DB_USER $THIS_DB --show-warnings  < $AFILE >> $JOBLOG &"
      mysql -tvvv -h$1 -p$DB_PASSWORD -u$DB_USER $THIS_DB --show-warnings  < $AFILE >> $JOBLOG &
      shift
    fi
  done
  wait
}

FILES=$(ls -1 *.sql 2>/dev/null)
[[ $? -ne 0 ]] && echo NO FILES TO PROCESS
for AFILE in $FILES
do
  # clean up old 'SET SQL_LOG_BIN...
  sed 's/SET SQL_LOG_BIN = 0;//g' $AFILE > /tmp/work.tmp.$$ && mv /tmp/work.tmp.$$ $AFILE
  $(cat - $AFILE <<<'SET SQL_LOG_BIN = 0;' > /tmp/work.$$ && mv /tmp/work.$$ $AFILE)
  concur $AFILE $SERVERS
  THIS_SUBJ="   "$(hostname -s)": concurrentDbScriptRunner results: $AFILE"
  THIS_BODY=$(cat $JOBLOG)
  THIS_BODY=${THIS_BODY:0:$MAX_MAIL_BODY_SIZE}
  echo "$DISCLAIMER: $THIS_BODY" | mail -s "$THIS_SUBJ" $MAIL_TO
  [[ $DELETE_FILES -eq 1 ]] && rm -fv $AFILE
done

#mysql -tvvv -hlocalhost -u$DB_USER -p$DB_PASSWORD sysadmin -e"UPDATE dbScriptRunner SET isRunning = 'false'"

# Clean up redirects
exec 1>&6 6>&-
