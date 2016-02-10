#!/bin/bash

# Copyright (c) 2011 Red Hat, Inc. All rights reserved. This copyrighted material 
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
# Author: Dimitar Yordanov <dyordano@redhat.com>
#         Pavel Studenik <pstudeni@redhat.com>

. /usr/share/beakerlib/beakerlib.sh
. /mnt/tests/CoreOS/Spacewalk/Helper/rhn-satellite-install.sh

# default values
PARENT="prod"

function  rhn_wait_process_to_finish() {
  [[ $# -ne 1 ]] && echo 'Usage: wait-proces-to-start PROCESS_NAME' && return 1
  rlRun "ps -ef | egrep $1 | egrep -vc grep"
  counter=0;
  max_counter=100;
  while [[ $( ps -ef | egrep $1 | egrep -vc grep ) -ne 0 ]]; do
    counter=$(( counter + 1 ))
    rlLog "${counter} : Wait $1 to FINISH"
    rlRun "sleep 1"
    [[ $counrer == $max_counter ]] && break
  done
}

function get_or_sync_channel() {
    local CHANNEL=$1
    if ! spacewalk-remove-channel -l | grep $CHANNEL; then

       # Sync Base channel
       rlRun "helper-satellite-sync.sh -c $CHANNEL --no-rpms --no-packages  --no-errata --no-kickstarts"

       # Wait Satellite Sync to finish
       rhn_wait_process_to_finish satellite-sync
    fi
}

# __main__
get_or_sync_channel $1
