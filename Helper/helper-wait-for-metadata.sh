#!/bin/sh

# Waits untill repodata are available for the channel
# 
#   $1 ... user to use during XMLRPC API calls
#   $2 ... pass
#   $3 ... server in the form https://<fqdn>/rpc/api
#   $4 ... channel you want to check for metadata readiness
#   [$5] ... timeout after which we should report an error
#            and exit [default is -1 = indefinitely]
# 
# Returns 0 if repodata ready, 1 if TIMEOUT happened or same error

function show_info_sql {
   rpm -q spacewalk-schema && \
echo "select * from RHNREPOREGENQUEUE;
select status,count(*) from RHNTASKORUN group by status;
select * from RHNTASKORUN where status in ('FAILED', 'RUNNING') order by modified;" \
   | spacewalk-sql -i
}

# Show options
user="$1"
echo "USER: $user"
pass="$2"
echo "PASS: $pass"
server="$3"
echo "SERVER: $server"
channel="$4"
echo "CHANNEL: $channel"
timeout="${5:--1}"
echo "TIMEOUT: $timeout"
step=10
if [ -z "$user" -o -z "$pass" -o -z "$server" -o -z "$channel" -o -z "$timeout" ]; then
  echo "ERROR: Not all required options correctly provided"
  exit 1
fi
server_host=$server
server="https://$server_host/rpc/api"
date_start=$( date +%s )   # when we were started

show_info_sql

# Check if we have what we need
if ! type 'manage-channel.py'; then
  echo "ERROR: 'manage-channel.py' utility is missing in the PATH"
  exit 1
fi
if ! manage-channel.py $user $pass $server TEST; then
  echo "ERROR: servers '/rpc/api' interface not responding"
  exit 1
fi

# Provoke metadata generation just to be sure
log=$( mktemp )
manage-channel.py $user $pass $server REGENERATE_YUM_CACHE $channel >$log 2>&1
rc=$?
cat $log
if [ $rc -ne 0 ] && tail -n 1 $log | grep --quiet 'Could not find method regenerateYumCache'; then
  # If it failed but because method do not exist, we do assume we are on
  # Satellite which just do not have such a call
  if manage-channel.py $user $pass $server TEST | grep --quiet -e '5\.2\.' -e '5\.3\.'; then
    # Yes, we are on old Satellite so we will provoke using system
    suffix="regenerateYumCache-replacement-$RANDOM"
    ak=$( manage-ak.py $user $pass $server CREATE $channel False False | tail -n 1 )
    cp -r /etc/sysconfig/rhn{,.$suffix}
    sed -i "s|^\(serverURL=\).*|\1https://$server_host/XMLRPC|g" /etc/sysconfig/rhn/up2date
    cert="/etc/sysconfig/rhn/RHN-ORG-TRUSTED-SSL-CERT.$suffix"
    wget http://$server_host/pub/RHN-ORG-TRUSTED-SSL-CERT -O $cert
    sed -i "s|^\(sslCACert=\).*|\1$cert|g" /etc/sysconfig/rhn/up2date
    # If this passed, it is probable we were able to request repodata
    # so they will be generated
    rhnreg_ks --force --activationkey "$ak" \
      && yum repolist \
      && rc=0
    mv /etc/sysconfig/rhn{,.$suffix-BACKUP}
    cp -r /etc/sysconfig/rhn.$suffix /etc/sysconfig/rhn
    rm -rf /etc/sysconfig/rhn.$suffix
    manage-ak.py $user $pass $server DELETE "$ak"
  else
    echo "ERROR: Method regenerateYumCache do not exist on this satellite version? What?"
    exit 1
  fi
fi
if [ $rc -ne 0 ]; then
  echo "ERROR: initiating metadata generation failed"
  exit 1
fi

# Wait till we have metadata or we timeout
count=0
while ! manage-channel.py $user $pass $server STATUS_YUM_CACHE $channel; do
  date=$( date "+%X %x" )
  echo "INFO: $date: metadata still not ready, waiting $step seconds"
  sleep $step
  let count+=$step
  if [ $timeout -ne '-1' ]; then
    if [ $count -ge $timeout ]; then
      echo "ERROR: TIMEOUT"
      echo "DEBUG: >>>>>>>>>>"
      echo "### Date"
      echo "Started: $( date -d @$date_start )"
      echo "Now: $( date )"
      echo "### Taskomatic log"
      tail -n 20 /var/log/rhn/rhn_taskomatic_daemon.log
      echo "### Catalina log"
      tail -n 20 /var/log/tomcat*/catalina.out
      echo "### Channels"
      ls -al /var/cache/rhn/repodata/
      echo "### Channel repo"
      ls -al /var/cache/rhn/repodata/$channel
      echo "### Taskomatic schedules"
      manage-taskomatic.py $user $pass $server LIST_ALL_SCHEDULE
      echo "### Load of the system"
      top -b -n 1 | head -n 20
      echo "### Probably Taskomatic is dead?"
      rhn-satellite status
      rhn-satellite restart
      echo "### Try to provoke repodata generation again"
      echo "Now: $( date )"
      manage-channel.py $user $pass $server REGENERATE_YUM_CACHE $channel >$log 2>&1
      echo "### Wait 60 seconds and tail Taskomatic log again"
      sleep 60
      tail -n 50 /var/log/rhn/rhn_taskomatic_daemon.log
      echo "### Channels again"
      ls -al /var/cache/rhn/repodata/
      echo "### Channel repo again"
      ls -al /var/cache/rhn/repodata/$channel
      echo "### Load of the system again"
      top -b -n 1 | head -n 20
      echo "### Show queue of repo task"
      show_info_sql
      echo "DEBUG: <<<<<<<<<<"
      exit 1
    fi
  fi
done

# Record how long did it take to generate repodata for this channel
date_end=$( date +%s )
# ... get info about channel (maybe we synced empty channel?
packages=$( manage-channel.py $user $pass $server LIST_PACKAGES_FOR_CHANNEL $channel | wc -l | cut -d ' ' -f 1 )
if [ $packages -gt 1500 ]; then   # do not bother to record synces of small channels
  erratas=$( manage-errata.py $user $pass $server LIST_FOR_CHANNEL $channel | wc -l | cut -d ' ' -f 1 )
  # ... get info about system
  hostname=$( hostname )
  satellite=$server_host   # Satellite do not have to be on localhost
  cpu_bogomips=$( grep ^bogomips /proc/cpuinfo | head -n 1 | sed -e 's/^.*: //' -e 's/\.[0-9]\+//' )
  cpu_count=$( grep ^processor /proc/cpuinfo | wc -l | cut -d ' ' -f 1 )
  cpu_model=$( grep '^model name' /proc/cpuinfo | head -n 1 | sed "s/^.*: //" | sed "s/\s\+/%20/g" )
  ram=$( free | grep ^Mem | sed -e "s/^Mem:\s\+\([0-9]\+\)\s\+.*$/\1/" )
  # ... get info about packages
  if rpm -q --quiet spacewalk-taskomatic; then
    taskomatic=$( rpm -q spacewalk-taskomatic )
  else
    taskomatic='NONE'
  fi
  # ... determine DB option
  db_host=$( spacewalk-cfg-get db_host )
  if [ -z "$db_host" \
       -o "$db_host" = "$( hostname )" \
       -o "$db_host" = "localhost" \
       -o "$db_host" = "127.0.0.1" \
       -o "$db_host" = "$( hostname -i )" ]; then
    db_loc='Emb'
  else
    db_loc='Ext'
  fi
  if spacewalk-cfg-get db_backend | grep -q postgresql; then
    db_backend='PostgreSQL'
  elif spacewalk-cfg-get db_backend | grep -q oracle; then
    db_backend='Oracle'
  else
    db_backend='FIXME'
  fi
  if [ "$db_loc" = 'Emb' -a "$db_backend" = 'PostgreSQL' ]; then
    if rpm --quiet -q postgresql-server; then
      db_ver='8'
    elif rpm --quiet -q postgresql84-server; then
      db_ver='8'
    elif rpm --quiet -q postgresql92-postgresql-server; then
      db_ver='9'
    else
      db_ver='FIXME'
    fi
  else
    db_ver=''
  fi
  # And finally record it
  [ -n $DEFAULT_RECORDER ] && echo "INFO: Recording $DEFAULT_RECORDER/HelperWaitForMetadataBenchmark/$JOBID/$TASKID/$( expr $date_end - $date_start )/$channel/$packages/$erratas/$hostname/$cpu_count/$cpu_bogomips/$cpu_model/$ram/$taskomatic/$satellite/$db_loc$db_backend$db_ver"
  [ -n $DEFAULT_RECORDER ] && curl -X PUT "http://$DEFAULT_RECORDER/HelperWaitForMetadataBenchmark/$JOBID/$TASKID/$( expr $date_end - $date_start )/$channel/$packages/$erratas/$hostname/$cpu_count/$cpu_bogomips/$cpu_model/$ram/$taskomatic/$satellite/$db_loc$db_backend$db_ver"
fi

# Final result
echo "PASS"
exit 0
