#!/bin/sh

# Waits untill errata-cache Taskomatic bunch is run => all applicable erratas
# are scheduled to be applied.
#
#   $1 ... user to use during Taskomatic API calls
#   $2 ... pass
#   $3 ... server fqdn
#   [$4] ... systemID of a system you want to schedule for. Can be 'whoami'
#            for current system's systemID or empty for general errata-cache
#            run for all systems.
#   [$5] ... timeout in seconds after which we should report an error and exit
#            [default is -1 = indefinitely]
#
# Returns 0 if errata-cache was run, non0 if TIMEOUT happened or same error.

function show_info_sql {
   rpm --quiet -q spacewalk-schema && \
echo "select * from RHNREPOREGENQUEUE;
select status,count(*) from RHNTASKORUN group by status;
select * from RHNTASKORUN where status in ('FAILED', 'RUNNING') order by modified;" \
   | spacewalk-sql -i
}

set -o pipefail

# Show options
user="$1"
echo "USER: $user"
pass="$2"
echo "PASS: $pass"
server="$3"
echo "SERVER: $server"
systemid="${4:-*}"
echo "SYSTEMID: $systemid"
timeout="${5:--1}"
echo "TIMEOUT: $timeout"
step=5
if [ -z "$user" -o -z "$pass" -o -z "$server" -o -z "$systemid" -o -z "$timeout" ]; then
  echo "ERROR: Not all required options correctly provided" >&2
  exit 1
fi
server_host=$server
server="https://$server_host/rpc/api"
date_start=$( date )   # when we were started
exit_code=0
show_info_sql
# Check if we have what we need
if type 'manage-taskomatic.py'; then
  echo "DEBUG: 'manage-taskomatic.py' utility is available"
else
  echo "ERROR: 'manage-taskomatic.py' utility is missing in the PATH" >&2
  exit 1
fi
if manage-taskomatic.py $user $pass $server TEST; then
  echo "DEBUG: Servers '/rpc/api' interface works"
else
  echo "ERROR: Servers '/rpc/api' interface not responding" >&2
  exit 1
fi
# Check systemid parameter is configured correctly
if [ "$systemid" = "whoami" ]; then
  if ! [ -f  /etc/sysconfig/rhn/systemid ]; then
    echo "ERROR: You have requested to run the bunch for 'whoami' system, but this system is not registered so we do not know what 'whoami' stands for"
    exit 1
  fi
fi

function get_highest_field_from_lines() {
  # Return highest bunch field content from multiple bunch lines
  sed "s/^.*'$1': \([0-9]\+\)[^0-9]\+.*$/\1/" | sort -n | tail -n 1
}
function get_highest_id_from_lines() {
  # Return highest bunch ID from multiple bunch lines
  get_highest_field_from_lines 'id'
}
function get_highest_end_time_from_lines() {
  # Return highest end_time from multiple bunch lines
  get_highest_field_from_lines 'end_time'
}
function get_highest_start_time_from_lines() {
  # Return highest start_time from multiple bunch lines
  get_highest_field_from_lines 'start_time'
}
function mydateobj_to_timestamp() {
  # Reads __repr__ of python's date object from stdin formatted like
  # "<DateTime '20151023T00:51:14' at 22d2368>" and returns timestamp
  # for that date
  cut -d "'" -f 2 \
    | sed 's/^\([0-9]\{4\}\)\([0-9]\{2\}\)\([0-9]\{2\}\)T\([0-9:]\+\)$/\1-\2-\3 \4/' \
    | while read d; do
    date -d "$d" +%s
  done
}
function list_all_runs() {
  # Just list all tasks and if listing fails, exit the sctipt
  manage-taskomatic.py $user $pass $server LIST_BUNCH_SAT_RUN errata-cache-bunch
  local rc=$?
  if [ $rc -ne 0 ]; then
    echo "ERROR: Invalid exit code $rc when listing runs" >&2
    exit 1
  fi
}

# Record bunch runs before we schedule our
log_pre=$( mktemp )
list_all_runs | sed 's/ at [0-9a-f]\+/.../g' >$log_pre

# Schedule errata-cache-bunch taskomatic run
echo "INFO: Schedule errata-cache-bunch taskomatic run"
log=$( mktemp )
if [ "$systemid" = '*' ]; then
  manage-taskomatic.py $user $pass $server SCHEDULE_SINGLE_SAT_BUNCH_RUN errata-cache-bunch >$log
else
  manage-taskomatic.py $user $pass $server SCHEDULE_SINGLE_SAT_BUNCH_RUN errata-cache-bunch $systemid >$log
fi
rc=$?
start_time=$( tail -n 1 $log )
if [ $rc -ne 0 ]; then
  echo "ERROR: Invalid exit code $rc when scheduling" >&2
  exit 1
fi

# Record bunch runs after we schedule our
log_post=$( mktemp )
list_all_runs | sed 's/ at [0-9a-f]\+/.../g' >$log_post

show_info_sql

# Extract id of bunch run we have scheduled while back
runs=$( expr $( wc -l $log_post | cut -d ' ' -f 1 ) - $( wc -l $log_pre | cut -d ' ' -f 1 ) )
if [ "$runs" -eq 0 ]; then
  echo "ERROR: Looks like scheduling of our run failed although exit vales seem OK." >&2
  [ -n $DEFAULT_RECORDER ] && curl -X PUT "http://$DEFAULT_RECORDER/Sat5ErrataCacheNotScheduled/$JOBID/$TASKID/$( rpm -q spacewalk-taskomatic )"
  exit 1
fi
id=$( diff -u $log_pre $log_post | grep '^+{' | get_highest_id_from_lines )
echo "INFO: Run of errata-cache-bunch scheduled with exit code $rc, output in $log and start time $start_time and id $id"

# Wait till errata-cache-bunch taskomatic run finished
echo "INFO: Wait till errata-cache-bunch taskomatic run finished"
attempt=0
attempt_step=5
attempt_max=$( expr $timeout / $attempt_step )
echo "DEBUG: Running while loop with timeout=$timeout, attempt_step=$attempt_step, attempt_max=$attempt_max"
while true; do
  # List all the runs
  log=$( mktemp )
  list_all_runs >$log
  echo "INFO: Gathered list of errata-cache-bunch runs with exit code $rc and output in $log, our task is:"
  grep "'id': $id\>" $log
  # Make sure our run is in the list marked as FINISHED
  if grep --quiet "'status': 'FINISHED'.*'id': $id\>" $log; then
    echo "INFO: Run of errata-cache-bunch finished"
    break
  fi
  # If our run is skipped, but there is another RUNNING one, that another will
  # pick our task before it finishes, so although our run is in SKIPPED, we
  # are most probably fine
  if grep --quiet "'status': 'SKIPPED'.*'id': $id\>" $log; then
    echo "INFO: Our run was skipped, lets check if we have some other run which is in running state and thou would pick up our work"
    log_skipped=$( mktemp )
    list_all_runs >$log_skipped
    if [ $( grep "'status': 'RUNNING'" $log_skipped | wc -l | cut -d ' ' -f 1 ) -gt 0 ]; then
      echo "INFO: RUNNING bunch found. There is still hope."
      id=$( grep "'status': 'RUNNING'" $log_skipped | get_highest_id_from_lines )
      echo "INFO: New ID we are going to track now is $id."
      let attempt+=1
      sleep $attempt_step
      continue
    fi
    if [ $( grep "'status': 'FINISHED'" $log_skipped | wc -l | cut -d ' ' -f 1 ) -gt 0 ]; then
      echo "INFO: FINISHED bunch found. If it finished after we started, we should be OK."
      their_end_time_raw=$( grep "'status': 'FINISHED'" $log_skipped | get_highest_end_time_from_lines )
      their_end_time=$( echo "$their_end_time_raw" | mydateobj_to_timestamp )
      our_start_time_raw=$( grep "'id': $id\>" $log | get_highest_start_time_from_lines )
      our_start_time=$( echo "$our_start_time_raw" | mydateobj_to_timestamp )
      if [ $their_end_time -gt $our_start_time ]; then
        echo "INFO: We have found FINISHED bunch which finished ($their_end_time_raw, i.e. $their_end_time) after we have started ($our_start_time_raw, i.e. $our_start_time), so we should be OK."
        break
      fi
    fi
    echo "DEBUG: Showing head of $log_skipped"
    head $log_skipped
    echo "ERROR: Bunch in appropriate state not found. There is no hope now."
    exit 1
  fi
  if ! grep --quiet "'status': '\(READY\|RUNNING\)'.*'id': $id\>" $log; then
    echo "DEBUG: Showing head of $log"
    head $log   # show what might be wrong
    echo "ERROR: Our run is in invalid state"
    exit 1
  fi
  if [ $timeout -ne '-1' -a $attempt -ge $attempt_max ]; then
    echo "DEBUG: Showing head of $log"
    head $log   # show what might be wrong
    echo "TIMEOUT: Bunch did not completed in time" >&2
    exit 1
  fi
  echo "INFO: One more attempt at $( date )"
  let attempt+=1
  sleep $attempt_step
done

# Finish
date_end=$( date )
echo "INFO: We have started at $date_start and finished at $date_end"
echo "PASS"
exit $exit_code
