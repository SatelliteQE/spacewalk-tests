#!/bin/sh

# This helper is meant to be used where you are syncing from hosted and you
# are NOT testing satellite-sync - you just want the content and do not care
# about some usual issues we frequently see on hosted (timeounts, incomplete
# reads, connection resets...) and which are still not resolved (and I doubt
# they will).

attempt_max=3
attempt_sleep=$(( ( RANDOM % 30 )  + 15 ))   # random number from 15 to 45
attempt=0
attempt_rc=100
log=$( mktemp )

set -o pipefail

while true; do
  satellite-sync $@ 2>&1 | tee $log
  attempt_rc=$?
  # Exit if we were successful or we are out of tries
  if [ "$attempt_rc" -eq 0 -o "$attempt" -ge "$attempt_max" ]; then
    break
  fi
  # If we have failed for some other than expected reason, exit with error
  if tail -n 15 $log | grep --quiet \
    -e 'Connection reset by peer' \
    -e 'Timeout Exception$' \
    -e 'Unable to connect to the host and port specified' \
    -e '^IncompleteRead: IncompleteRead' \
    -e '^IOError: CRC check failed$' \
    -e '/SAT-DUMP: 502 Proxy Error' \
    -e 'decryption failed or bad record mac' \
    -e 'Temporary failure in name resolution' \
    ; then
    echo "INFO: Expected Hosted error. Going to try again in a while."
    # Report error to recorder, so we have statistic. First determine error
    # we have observed. Then report it and then check if that is a frequent.
    # If it is, send an email report.
    tail -n 15 $log | grep --quiet -e 'Connection reset by peer' && err='Connection reset by peer'
    tail -n 15 $log | grep --quiet -e 'Timeout Exception' && err='Timeout Exception'
    tail -n 15 $log | grep --quiet -e 'Unable to connect to the host and port specified' && err='Unable to connect to the host and port specified'
    tail -n 15 $log | grep --quiet -e '^IncompleteRead: IncompleteRead' && err='IncompleteRead: IncompleteRead'
    tail -n 15 $log | grep --quiet -e '^IOError: CRC check failed$' && err='IOError: CRC check failed'
    tail -n 15 $log | grep --quiet -e '/SAT-DUMP: 502 Proxy Error' && err='SAT-DUMP: 502 Proxy Error'
    tail -n 15 $log | grep --quiet -e 'decryption failed or bad record mac' && err='decryption failed or bad record mac'
    tail -n 15 $log | grep --quiet -e 'Temporary failure in name resolution' && err='Temporary failure in name resolution'
    [ -n $DEFAULT_RECORDER ] && curl -X PUT "http://$DEFAULT_RECORDER/HelperSatelliteSyncKnownErrors/$JOBID/$TASKID/$( echo "$err" | sed 's/\s\+/+/g' )"
    log=$( mktemp )
    [ -n $DEFAULT_RECORDER ] && curl -X GET -H 'Accept: application/json' "http://$DEFAULT_RECORDER/HelperSatelliteSyncKnownErrors/RecentlyFailsOften/5/10" >$log
    if grep --quiet '^<title>412 Precondition Failed</title>$' $log; then
      echo "INFO: Looks like this is recently not too often issue. Good. Ignoring it and not sending email."
    else
      echo "ERROR: Looks like this is recently quite often issue. Bad. Sending email about that." >&2
      cat $log
      echo "
This is $( hostname ) speaking.

HelperSatelliteSyncKnownErrors recently failed quite often.

Failed runs:

$( cat $log )

This is my env:

$( env )" | mail -s HelperSatelliteSyncKnownErrors jhutar@redhat.com
      if [ $? -eq 0 ]; then
        echo "INFO: Email to jhutar@redhat.com sent"
      else
        echo "ERROR: Failed to send email" >&2
      fi
      exit 5
    fi
  else
    echo "ERROR: Unexpected Hosted error. Not going to try again." >&2
    exit 10
  fi
  # Wait a bit till next attempt
  sleep $attempt_sleep
  let attempt+=1
done

exit $attempt_rc
