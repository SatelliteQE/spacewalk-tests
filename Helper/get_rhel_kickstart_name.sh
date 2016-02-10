#!/bin/bash
#
# Get the name of kickstart tree.
#
# 
# Author: Simon Lukasik
#         Dimitar Yordanov
#
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_kickstart_name.sh )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_kickstart_name.sh i386 server 5 )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_kickstart_name.sh x86_64 server 6 )

set -e
set -o pipefail

if rpm -q --quiet fedora-release; then
  echo "FAIL: This might not work on Fedora" >&2
fi

# Custom
[[ $# -eq 3  ]] && echo "ks-rhel-${1}-${2}-${3}" && exit 0

arch=`rpm -E '%{_arch}'`
distro_version=`rpm -q --qf="%{VERSION}" --whatprovides redhat-release`
distro_variant=`echo $distro_version | sed "s/^[0-9]\+\(.*\)$/\L\1/"`
distro_release=`echo $distro_version | sed "s/^\([0-9]\+\)[^0-9]\+.*$/\1/"`

# RHEL6
[[ $# -eq 0  && ${distro_release} -eq 6 ]] && echo "ks-rhel-${arch}-${distro_variant}-6-6.0" && exit 0

# RHEL5
if [ "$arch" == 's390x' ]; then
  # WORKAROUND: We do not have GA kickstart on RHEL5@s390x
  [[ $# -eq 0  && ${distro_release} -eq 5 ]] && echo "ks-rhel-${arch}-${distro_variant}-5-u2" && exit 0
else
  [[ $# -eq 0  && ${distro_release} -eq 5 ]] && echo "ks-rhel-${arch}-${distro_variant}-5" && exit 0
fi

exit 1


