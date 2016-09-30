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
# Author: Jan Hutar <jhutar@redhat.com>, based on work of Petr Sklenar <psklenar@redhat.com>

. /usr/bin/rhts-environment.sh
echo "rhts-env sourced, status = $?"
. /usr/share/beakerlib/beakerlib.sh
echo "beakerlib sourced, status = $?"


rlJournalStart

rlPhaseStartSetup "Install spacewalk-postgresql"

    export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
    # Source the our libraryes
    . /mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh
    rlAssert0 "File 'spacewalk-install' sourced" $?

rlPhaseEnd


rlPhaseStartTest "Install spacewalk-postgresql"

    # Finally, install the package
    spacewalk_install_important_package spacewalk-postgresql
    spacewalk_install_important_package spacewalk-utils

rlPhaseEnd


rlJournalEnd
