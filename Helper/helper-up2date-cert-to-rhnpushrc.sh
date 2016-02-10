#!/bin/sh

# From Satellite 5.6.0 rhnpush was fixed and now
# do not ignores Satellite's CA certificate so you
# have to have correct one.
#
# This script is meant to:
#  * when started without option: use certificate
#    set in up2date config in rhnpush config
#  * when started with option: consider the option
#    as a hostname of a Satellite, download its
#    certificate and configure in rhnpush config
#
# When using this helper, pake sure you backup (and
# restore) rhnpushrc (done by rhn_helper_rhn_backup
# function). Like this:
#
#   backup=$( rhn_helper_rhn_backup | tail -n 1 )
#   helper-up2date-cert-to-rhnpushrc.sh "$RHN_SERVER"
#   rhnpush ...
#   rhn_helper_rhn_restore "$backup"
#
# Note that if you have used helper-rhn-register.sh
# helper to register, you do not have to call this
# script as it is called automatically in
# the mentioned register script.

set -x

# Make sure rhnpush is installed
if ! rpm -q --quiet rhnpush; then
  echo "WARN: rhnpush is not installed, not doing any changes"
  exit 0
fi

# If rhnpush is installed, show what we have configured in rhnpushrc
if [ ! -e /etc/sysconfig/rhn/rhnpushrc ]; then
  echo "WARN: rhnpushrc file is not present"
  echo "DEBUG: some test deleted rhnpushrc, so recreate it empty"
  touch /etc/sysconfig/rhn/rhnpushrc
  echo "[rhnpush]" >> /etc/sysconfig/rhn/rhnpushrc
fi
grep "ca_chain" /etc/sysconfig/rhn/rhnpushrc

if [ -n "$1" ]; then
  # We have hostname of Satellite provided => use its cert

  # Download Satellite's certificate
  cert=$( mktemp /usr/share/rhn/CERT.XXXXXX )
  wget -O $cert "http://$1/pub/RHN-ORG-TRUSTED-SSL-CERT" || exit 1
else
  # We have no commandline option, just copy cert from up2date config

  # Make sure required files are available
  [ -e /etc/sysconfig/rhn/up2date ] || exit 1
  grep "sslCACert" /etc/sysconfig/rhn/up2date

  # Determine CA certificate path from up2date config
  cert=$( grep '^[^#]*sslCACert\s*=' /etc/sysconfig/rhn/up2date | tail -n 1 | cut -d '=' -f 2 )
fi

# Verify cert exists
[ -e "$cert" ] || exit 1

# Comment out ca_chain directives
sed -i 's/\(^\s*ca_chain\s*=.*$\)/###\1/' /etc/sysconfig/rhn/rhnpushrc

# Add correct ca_chain directive
echo "ca_chain = $cert" >> /etc/sysconfig/rhn/rhnpushrc || exit 1
