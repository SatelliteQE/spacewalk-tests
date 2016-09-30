#!/bin/bash

# Copyright (c) 2016 Red Hat, Inc. All rights reserved. This copyrighted material 
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
# Author: Jan Hutar <jhutar@redhat.com>

. /usr/bin/rhts-environment.sh
echo "rhts-env sourced, status = $?"

. /usr/share/beakerlib/beakerlib.sh
echo "beakerlib sourced, status = $?"


rlJournalStart


rlPhaseStartTest "Init environment"

    export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
    # Source the our spacewalk library
    . /mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh
    rlAssert0 "File 'spacewalk-install' sourced" $?

rlPhaseEnd


rlPhaseStartTest "Setup repos"

    # Setup SW nightly server repos as advised in HowToInstall
    # https://fedorahosted.org/spacewalk/wiki/HowToInstall
    base_uri="http://yum.spacewalkproject.org/nightly"
    os_name=`/mnt/tests/CoreOS/Spacewalk/Helper/helper-get-distro-name.sh | tail -n 1`
    os_short="el"
    rlIsFedora && os_short="fc"
    os_version=`rlGetDistroRelease | tail -n 1`
    base_arch=`rlGetArch | tail -n 1`
    repo_nvr=$( curl $base_uri/$os_name/$os_version/$base_arch/ 2>/dev/null | sed -n 's/.*\(spacewalk-repo-[.0-9-]\+\)\.[fcel0-9]\+\.noarch\.rpm.*/\1/p' )
    if [ -z $repo_nvr ]; then
      rlDie "Could not find spacewalk-repo version (repo_nvr = '$repo_nvr')"
    fi
    rlRun "rpm -Uvh $base_uri/$os_name/$os_version/$base_arch/$repo_nvr.${os_short}${os_version}.noarch.rpm"
    rlRun "sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/spacewalk-nightly.repo"
    rlRun "sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/spacewalk.repo"

    # WORKAROUND to handle upgraded package and replaced repo configs
    type dnf && rlRun "dnf -y upgrade spacewalk-repo" || rlRun "yum -y upgrade spacewalk-repo"
    rlRun "sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/spacewalk-nightly.repo"
    rlRun "sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/spacewalk.repo"

    # On RHEL setup EPEL repo as well
    rlIsRHEL && rhn_helper_install_repo_EPEL
    rlIsRHEL 6 && rhn_helper_install_repo RHEL6-optional.repo

    # For all system we need set up jpackage repo
    rhn_helper_install_repo jpackage-generic.repo

    # On RHEL7 I do see dependency problem with cglib upgrade
    # Also see http://post-office.corp.redhat.com/archives/satellite-dept-list/2014-October/msg00018.html
    rlIsRHEL 7 && rlRun "rm -f /etc/yum.repos.d/beaker-Server-optional*"
    # BUT we NEED optional channel,(having no deps issues opposite to beaker optional repo)
    rlIsRHEL 7 && rlRun "yum-config-manager --enable rhel-7-server-optional-rpms"
    # Show repos we have
    type dnf && rlRun "dnf repolist" || rlRun "yum repolist"
    type dnf && rlRun "dnf update -y" || rlRun "yum update -y"

rlPhaseEnd


rlJournalEnd
