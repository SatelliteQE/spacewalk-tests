#!/bin/sh

# This helper is meant to be used where you are activating against hosted and
# you are NOT testing the activation (or rhn-satellite-activate) itself - you
# just want activation to succeed and do not care about some usual issues we
# frequently see on hosted (ISE...).
#
# When adding more ignored issues, please make sure you have ticket reported
# and you link it from some comment bellow.
#
# USAGE:
#   # helper-rhn-satellite-activate.sh <any rhn-satellite-activate options>

attempt_max=3
attempt_sleep=$(( ( RANDOM % 30 )  + 15 ))   # random number from 15 to 45
attempt=0
attempt_rc=100
log=$( mktemp )

# Needed because we are using the tee below and want exit value of
# rhn-satellite-activate command before it
set -o pipefail

while true; do
  rhn-satellite-activate $@ 2>&1 | tee $log
  attempt_rc=$?
  # Exit if we were successful or we are out of tries
  if [ "$attempt_rc" -eq 0 -o "$attempt" -ge "$attempt_max" ]; then
    break
  fi
  # If we have failed for some other than expected reason, exit with error
  # Issues workarounded here:
  #   ISE from Hosted when activating Red Hat Satellite (INC0220266)
  #     xmlrpclib.ProtocolError: <ProtocolError for satellite.rhn.redhat.com /rpc/api: 500 Internal Server Error>
  #   Networking issues:
  #     RhnSyncException("ERROR: server.dump.channel_families('<the systemid>',): (104, 'Connection reset by peer')",)
  if tail -n 15 $log | grep --quiet \
    -e 'xmlrpclib\.ProtocolError: <ProtocolError for satellite\.rhn\.redhat\.com /rpc/api: 500 Internal Server Error>' \
    -e "RhnSyncException(\"ERROR: server\.dump\.channel_families('<the systemid>',): (104, 'Connection reset by peer')\",)" \
    ; then
    echo "INFO: Expected Hosted error. Going to try again in a while."
  else
    echo "ERROR: Unexpected Hosted error. Not going to try again."
    exit 10
  fi
  # Wait a bit till next attempt
  sleep $attempt_sleep
  let attempt+=1
done

exit $attempt_rc
