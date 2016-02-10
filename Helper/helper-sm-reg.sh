#!/bin/bash

# Lukas Hellebrandt
# <lhellebr@redhat.com>

. /usr/share/beakerlib/beakerlib.sh

export RHN_USER=${RHN_USER:-"$DEFAULT_USER"}
export RHN_PASS=${RHN_PASS:-"$DEFAULT_PASS"}

rlJournalStart
rlPhaseStartSetup "Register to RHN using Subscription Manager, auto-attach, disable unnecessary repos"
    if [[ $CODESTAGE == 'true' ]] ; then
        rlRun "subscription-manager config --server.hostname=$DEFAULT_CODESTAGE"
    fi
    # If this fails with "'exceptions.ValueError' object has no attribute 'msg'" you are hitting bug 1110271
    # WORKAROUND for bug 1104246 - we have seen timeouts sometimes
    attempt=0
    attempt_max=10
    attempt_log=$( mktemp )
    while ! rlRun "subscription-manager register --auto-attach --force --username '$RHN_USER' --password '$RHN_PASS' &>$attempt_log" 0,1,70,255; do
      rlRun "cat $attempt_log"
      if [ $attempt -ge $attempt_max ]; then
        rlFail "Failed to register - out of attempts"
        break
      fi
      if grep -q "Unable to verify server's identity: timed out" $attempt_log; then
        rlLogWarning "WORKAROUND for bug 1104246 applied. Trying again."
        rlRun "sleep 30"
        let attempt+=1
        continue
      elif grep -q "The proxy server received an invalid response from an upstream server" $attempt_log; then
        rlLogWarning "WORKAROUND for issue INC0252065 applied. Trying again."
        rlRun "sleep 30"
        let attempt+=1
        continue
      else
        rlFail "Failed to register - unknown error reached"
        rlFileSubmit /var/log/rhsm/rhsm.log
        break
      fi
    done

    rlRun "subscription-manager repos --disable 'rh*' >/dev/null"
    rlIsRHEL 6 \
      && rlRun "subscription-manager repos --enable rhel-6-server-rpms --enable rhel-6-server-optional-rpms"
    rlIsRHEL 7 \
      && rlRun "subscription-manager repos --enable rhel-7-server-rpms --enable rhel-7-server-optional-rpms"

rlPhaseEnd
rlJournalEnd
rlJournalPrintText
