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
# Author: Pavel Studenik <pstudeni@redhat.com>

. /usr/bin/rhts-environment.sh
echo "rhts-env sourced, status = $?"
. /usr/share/beakerlib/beakerlib.sh
echo "beakerlib sourced, status = $?"


rlJournalStart

rlPhaseStartSetup "Initial setup"
    export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
    # Source rhn-satellite-install.sh
    . /mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh
    rlAssert0 "Import 'spacewalk-install.sh'" $?
rlPhaseEnd


# Installation is divided to some part
# Inspiration by https://fedorahosted.org/spacewalk/wiki/HowToInstall
tests="/CoreOS/Spacewadk/Installer/Sanity/SW-setup-firewall
/CoreOS/Spacewalk/Installer/setup-repos/SWnightly
/CoreOS/Spacewalk/PostgreSQL/setup-server-and-user
/CoreOS/Spacewalk/Installer/Sanity/Yum-install/spacewalk-postgresql
/CoreOS/Spacewalk/Installer/Sanity/Spacewalk-setup-postgresql
"

export FIPS_MODE_ENABLED=${FIPS_MODE_ENABLED_PARAM:-false}
for i in $tests; do
    make -C /mnt/tests/$i run
done

rlPhaseStartTest "Check logs"
    rlRun "spacewalk_logs.sh assert_clean"
    rhn_helper_check_server_status "$RHN_SERVER"
rlPhaseEnd

rlJournalEnd

rlJournalPrintText
