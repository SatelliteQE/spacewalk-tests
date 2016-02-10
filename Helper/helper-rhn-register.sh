#!/bin/bash
#
# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author:      Dimitar Yordanov <dyordano@redhat.com>
# Description: General helper to register system to RHN Satellite or Hosted

# Documentation in POD format
: <<=cut
=pod

=head1 rhn_register_rhts

Register system to RHN Hosted or Satellite by some of below means.

=head2 SYNOPSYS:

    helper-rhn-register.sh -u RHN_USER -p RHN_PASS -s RHN_SERVER -n PROFILE

or

    helper-rhn-register.sh -a ACTIV_KEY -s RHN_SERVER -n PROFILE

or

    helper-rhn-register.sh -s RHN_SERVER -n PROFILE

=head2 DESCRIPTION:

=over

=item -u RHN_USER

Username to use for registration

=item -p RHN_PASS

Password

=item -a AK

Activation key to use for registration

=item -s RHN_SERVER

Server

=item -n PROFILE

Profile label

=back

=head2 EXAMPLES:

Satellite and Hosted with User & Pass : helper-rhn-register.sh -u $RHN_USER -p  $RHN_PASS -s $RHN_SERVER -n $PROFILE

Satellite or Hosted  with AK          : helper-rhn-register.sh -a $ACTIV_KEY -s $RHN_SERVER -n $PROFILE

Hosted with AK                        : helper-rhn-register.sh -s xmlrpc.rhn.redhat.com -n $PROFILE

Satellite  with default user/pass     : helper-rhn-register.sh -s $RHN_SERVER -n $PROFILE

=cut

set -e
set -o pipefail

. /usr/share/beakerlib/beakerlib.sh
export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"

#DATE=$(date +%Y_%m_%d_%H_%M_%S)

USER=''
PASS=''
SERVER=''
AK=''
PROFILE=''

PARAMS=":s:u:p:a:n:x:"
while getopts $PARAMS opt; do
   case $opt in
     u) USER=$OPTARG;
        ;;
     p) PASS=$OPTARG
        ;;
     s) SERVER=$OPTARG;
        ;;
     a) AK=$OPTARG;
        ;;
     n) PROFILE=$OPTARG;
        ;;
     \?)
        echo "ERROR: Invalid option: -$OPTARG"
        exit 1
        ;;
     :)
        echo "ERROR: Option -$OPTARG requires an argument"
        exit 1
        ;;
   esac
done

unset PARAMS
unset OPTIND

echo "DEBUG: SERVER = $SERVER"
echo "DEBUG: USER = $USER"
echo "DEBUG: PASS = $PASS"
echo "DEBUG: AK = $AK"
echo "DEBUG: PROFILE = $PROFILE"
#echo "DEBUG: DATE = $DATE"
echo "DEBUG: VARIANT = $VARIANT"

if rlIsRHEL 7 && [ $SERVER == '' ] ; then # RHEL7

	helper-sm-reg.sh

else # non-RHEL7

[[ $# == 8 ]] && [[ -n $USER ]] && [[ -n $PASS ]] && [[ -n $SERVER ]] && [[ -n $PROFILE ]]  && VARIANT=1 # Satellite  or Hosted with user and pass
[[ $# == 6 ]] && [[ -n $AK ]] && [[ -n $SERVER ]] && [[ -n $PROFILE ]]  && VARIANT=2 # Satellite or Hosted with AK
[[ $# == 4 ]] && [[ -n $SERVER ]]  && [[ -n $PROFILE ]]  && VARIANT=3  # Hosted with AK

# WORKAROUND for bug 761489 >>>
bz761489=false
if ! workaround-bz761489-needed.sh; then
  bz761489=true
  echo "WARNING: Using workaround for bug 761489 (will disable 'exit immediately' for registration)"
fi
# <<<

function download() {
  # $1 ... from url
  # $2 ... to file
  local wget_log=$( mktemp )
  if ! wget "$1" -O "$2" &>$wget_log; then
    echo "ERROR: Failed to download '$1', error message was:"
    cat $wget_log
    exit 1
  fi
  rm $wget_log
}

case $VARIANT in
  1|2)
    # Set RHN server in /etc/sysconfig/rhn/up2date
    sed -i "s|^\(serverURL=\).*|\1https://$SERVER/XMLRPC|g" /etc/sysconfig/rhn/up2date
    # In case we are running against Satellite, get certificate
    # TODO: This should also consider TAGS once we wil be able to use them
    if ! echo $SERVER | grep -q '^xmlrpc\.rhn\..*$'; then
         SSL_CERT="/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT.$SERVER"
         download http://$SERVER/pub/RHN-ORG-TRUSTED-SSL-CERT $SSL_CERT
         sed -i "s|^\(sslCACert=\).*|\1$SSL_CERT|g" /etc/sysconfig/rhn/up2date
         echo "DEBUG: SSL_CERT = $SSL_CERT"
    fi
    # Prepare options we will use for registration
    if [ -z ${AK} ]; then
         rhnreg_ks_options="--force --username=${USER} --password=${PASS}  --profilename=${PROFILE}"
    else
         rhnreg_ks_options="--force --activationkey=${AK} --profilename=${PROFILE}"
    fi
  ;;
  3)
     sed -i "s|^\(serverURL=\).*|\1https://$SERVER/XMLRPC|g" /etc/sysconfig/rhn/up2date
     SSL_CERT="/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT.$SERVER"
     download http://$SERVER/pub/RHN-ORG-TRUSTED-SSL-CERT $SSL_CERT
     sed -i "s|^\(sslCACert=\).*|\1$SSL_CERT|g" /etc/sysconfig/rhn/up2date
     echo "DEBUG: SSL_CERT = $SSL_CERT"
     rhnreg_ks_options="--force --username=$DEFAULT_USER --password=$DEFAULT_PASS  --profilename=${PROFILE}"
  ;;
  *)
    echo "ERROR: Unrecognized set of options"
    pod2text $0
    exit 1
  ;;
esac

attempt=0
attempt_max=10
attempt_log=$( mktemp )
set +e
echo "INFO: Running registration (output in $attempt_log)"
while true; do

  echo "RUN: rhnreg_ks $rhnreg_ks_options"
  rhnreg_ks $rhnreg_ks_options &>$attempt_log
  exit_code=$?
  [[ ${exit_code} -eq 0 ]] && break

 if ( echo $SERVER | grep -q '^xmlrpc\.rhn\..*$'  || \
     [[ -n ${PROXY_2_HOSTED} ]] ) \
     && tail -n 3 $attempt_log | grep \
       -e 'Connection timed out on readline' \
       -e '^Proxy Error$'; then
    echo "WARNING: Registration against Hosted failed, but we expect this kind of error, so trying again"
  elif $bz761489; then
    echo "INFO: Registration failed but without safe error message. But workaround for bug 761489 is enabled, so most probably it was OK and we can just go on."
    break
  else
    echo "ERROR: Registration failed with unexpected error"
    echo "DEBUG: Showing output of rhnreg_ks:"
    cat $attempt_log
    echo "DEBUG(jhutar): ip a"
    ip a
    echo "DEBUG(jhutar): traceroute $SERVER"
    traceroute $SERVER
    echo "DEBUG(jhutar): hostname"
    hostname
    echo "DEBUG(jhutar): iptables-save"
    iptables-save
    # Record this failure for possible further analysis
    [ -n $DEFAULT_RECORDER ] && curl -X PUT "http://$DEFAULT_RECORDER/HelperRhnRegisterUnexpectedError/$JOBID/$TASKID/$( tail -n 4 $attempt_log | sed 's/[^0-9a-zA-Z -:,]/./g' | sed ':a;N;$!ba;s/\n/%0A/g' | sed 's/\s\+/ /g' | sed 's/ /%20/g' )"
    exit ${exit_code}
  fi
  if [ $attempt -ge $attempt_max ]; then
    echo "ERROR: We are out of tries when registering"
    echo "DEBUG: Showing output of rhnreg_ks:"
    cat $attempt_log
    break
  fi
  let attempt+=1
  sleep 10
done

echo "INFO: Sync CA cert setting to rhnpushrc"
helper-up2date-cert-to-rhnpushrc.sh
echo "INFO: Show our systemID"
grep 'ID-' /etc/sysconfig/rhn/systemid
echo "INFO: Test our registration - listing channels"
if rpm --quiet -q up2date; then
     rpm --import /usr/share/rhn/RPM-GPG-KEY
     up2date --show-channels
else
     if rpm --quiet -q yum; then
         yum repolist
     else
         dnf repolist
     fi
fi
echo "INFO: Test our registration - checking to RHN"
rhn_check -vv

fi # non-RHEL7
