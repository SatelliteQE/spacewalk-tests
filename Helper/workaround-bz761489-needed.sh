#!/bin/sh

# WORKAROUND for bug 761489
#   Returns exit code equal to what tests should expect from
#     rhnreg_ks
#   When 'rhn-profile-sync' is given as an option, returns
#     exit code equal to what tests should expect from
#     rhn-profile-sync
if ( rpm --quiet -q redhat-release-5Server || rpm --quiet -q redhat-release-5Client ) \
   && rpm --quiet -q rhn-virtualization-host \
   && rpm --quiet -q libvirt \
   && rpm -qi rhn-client-tools | grep 'Packager' | grep -v 'Koji' \
   && ! service libvirtd status; then
  if rpm -q rhn-virtualization-host | grep "5\.\(4\.[4-9][0-9]\|[5-9]\.[0-9]\+\)"; then
    if [ "$1" = "rhn-profile-sync" ]; then
      exit 1
    fi
  else
    echo "INFO: Using workaround for bug 761489"
    exit 1
  fi
elif [ "$1" = "rhn-profile-sync" ] \
   && rpm -q --whatprovides redhat-release | grep --quiet -e '6Server' -e '6Workstation' -e '6Client' -e '6ComputeNode' \
   && rpm --quiet -q rhn-virtualization-host \
   && rpm --quiet -q libvirt \
   && rpm -qi rhn-client-tools | grep 'Packager' | grep -v 'Koji' \
   && ! service libvirtd status; then
  if rpm -q rhn-virtualization-host | grep "5\.\(4\.[4-9][0-9]\|[5-9]\.[0-9]\+\)"; then
    echo "INFO: Using workaround for bug 761489 (on RHEL6 we now behave same)"
    exit 1
  fi
fi

exit 0
