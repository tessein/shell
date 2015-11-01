for SRVR in $(mysql -hxxxxxx -ssB -uxxxxxxxx -pxxxxxx sysadmin -e"SELECT hostname FROM IsAlive WHERE database_server = 1  AND has_fusion = 1")
do
  ssh -l tomcat $SRVR "sudo fio-status 2>/dev/null|grep 'Media status'|egrep -q '*Healthy*'"
  RC=$?
  echo $(date)": "$RC > /tmp/fio_status.$SRVR.$$
  [[ $RC -ne 0 ]] && echo "$SRVR's fusion-io is reporting unhealthy status" | mail -s"ALERT  fusion-io  $SRVR" xxx@xxx.com
done
