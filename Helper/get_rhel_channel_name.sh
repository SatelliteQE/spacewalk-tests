#!/bin/bash
#
# Get the name of deafult rhel base channel for local machine.
#
# Disclaimer: Many of our tests make a use of rhel
# default channel. Each of them uses its way to obtain
# its name. This is the supported way.
# 
# Author: Simon Lukasik
#
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_channel_name.sh )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_channel_name.sh tools )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_channel_name.sh proxy 5.3 )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_channel_name.sh proxy 5.4 )
# $( /mnt/tests/CoreOS/Spacewalk/Helper/get_rhel_channel_name.sh satellite 5.5 )

set -e
set -o pipefail

if rpm -q --quiet fedora-release; then
  # On Fedora xx don't build the channel name with Fedora version
  # use RHEL 6 channel instead
  echo "rhel-x86_64-server-6" && exit 0
fi

arch=`rpm -E '%{_arch}'`
distro_version=`rpm -q --qf="%{VERSION}" --whatprovides redhat-release`
distro_variant=`echo $distro_version | sed "s/^[0-9]\+\(.*\)$/\L\1/"`
distro_release=`echo $distro_version | sed "s/^\([0-9]\+\)[^0-9]\+.*$/\1/"`
version=${2}

[[ $distro_release = '7' ]] && distro_variant=$(rpm -q --whatprovides redhat-release | cut -d "-" -f 3)

[[ $# -eq 0 ]] && echo "rhel-${arch}-${distro_variant}-${distro_release}" && exit 0

[[ ${1} == tools ]] && echo "rhn-tools-rhel-${arch}-${distro_variant}-${distro_release}" && exit 0

#tools-sm is used to generate the name for rhn-tools repo using the subscription-manager. Repos/channels there use different naming convention than Satellite/RHN
# rhel-7-server-rhn-tools-rpms #x86_64 server
# rhel-7-workstation-rhn-tools-rpms #x86_64 workstation
# rhel-7-for-power-rhn-tools-rpms #ppc64
# rhel-7-for-system-z-rhn-tools-rpms #s390x

[[ ${1} == tools-sm ]] && echo "rhel-${distro_release}-${distro_variant}-${arch}-rhn-tools-rpms" | sed -e "s/workstation-x86_64/workstation/"\
                                                                                                       -e "s/server-x86_64/server/"\
                                                                                                       -e "s/server-s390x/for-system-z/"\
                                                                                                       -e "s/server-ppc64/for-power/" && exit 0

[[ ${1} == proxy ]] && echo "redhat-rhn-proxy-${2}-${distro_variant}-${arch}-${distro_release}"

[[ ${1} == satellite ]] && echo "redhat-rhn-satellite-${version}-${distro_variant}-${arch}-${distro_release}"

# Only for RHEL5, and even there not for s390x
[[ ${1} == vt && ${distro_release} -eq 5 && "${arch}" != 's390x' ]]  && echo "rhel-${arch}-server-vt-5"
