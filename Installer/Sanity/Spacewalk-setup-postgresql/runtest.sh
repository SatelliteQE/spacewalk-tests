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
# Author:  Simon Lukasik
#

. /usr/bin/rhts-environment.sh
echo "rhts-env sourced, status = $?"
. /usr/share/beakerlib/beakerlib.sh
echo "beakerlib sourced, status = $?"

rlJournalStart


rlPhaseStartSetup "Setup for spacewalk-setup"

    export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
    # Source our spacewalk library
    . /mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh
    rlAssert0 "File '/mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh' sourced" $?
    # Variables transfer to the test
    . /mnt/tests/CoreOS/Spacewalk/Helper/helper-source-config.sh
    rlAssert0 "File '/mnt/tests/CoreOS/Spacewalk/Helper/helper-source-config.sh' sourced" $?
    # Run tcpdump in the background so we can check for communication
    # with external world
    rlRun "helper-tcpdump-external.sh start"

rlPhaseEnd


rlPhaseStartTest "spacewalk-setup for PostgreSQL"

    if ! rpm -q spacewalk-setup-postgresql &>/dev/null;then

       # External DB installation
       DB_TYPE_OPTION=--external-postgresql

       # In case PG with SSL, force the installer to check the cert
       # The cert is set in test Sanity/spacewalk-ext-pg-ssl/enable_ssl_db_pg
       [[ -e ~/.postgresql/root.crt ]] && rlRun "export PGSSLMODE=verify-full"

    fi

    DB_CLEAR_OPTION='--clear-db'
    if rpm -q spacewalk-setup-postgresql &>/dev/null; then
        # On embedded PostgreSQL variant, --clear-db makes installer
        # to skip DB setup
        DB_CLEAR_OPTION=''
    fi

    rlLogInfo "DEBUG: PGSSLMODE=$PGSSLMODE"
    rlLogInfo "DEBUG: DB_TYPE_OPTION=$DB_TYPE_OPTION"

    rlRun "spacewalk-setup --non-interactive --answer-file=answer-file $DB_CLEAR_OPTION $DB_TYPE_OPTION"
    if [ $? -ne 0 ]; then
        rlRun "tail /var/log/rhn/install_db.log || :"
        rlRun "tail /var/log/rhn/populate_db.log || :"
        rlRun "tail /var/log/rhn/rhn?installation.log"
    fi
    if rlIsFedora && rpm -q --quiet firewalld \
       && systemctl status firewalld.service; then
        # This is set in cobbler-issue test as well, but this is to be sure
        # See /CoreOS/Spacewalk/Installer/Workaround/cobbler-issue/runtest.sh
        rlRun "firewall-cmd --permanent --add-service=http"
        rlRun "firewall-cmd --permanent --add-service=https"
        rlRun "systemctl restart firewalld.service"
    fi
rlPhaseEnd


rlPhaseStartTest "create admin user"
    rlRun "create_first_user.sh"
rlPhaseEnd


rlPhaseStartTest "download RHN-ORG-TRUSTED-SSL-CERT"
    rlRun "wget -O /usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT http://$( hostname )/pub/RHN-ORG-TRUSTED-SSL-CERT"
    rlRun "grep 'sslCACert=' /etc/sysconfig/rhn/up2date"
rlPhaseEnd


rlPhaseStart WARN 'no external communication'
    rlRun "helper-tcpdump-external.sh stop"
    log=$( helper-tcpdump-external.sh log )
    size=$( wc -l $log | cut -d ' ' -f 1 )
    rlAssert0 "There should be no external communication during SW configuration" "$size"
    [ "$size" -gt 0 ] && rlFileSubmit "$log"
rlPhaseEnd


rlPhaseStartCleanup "upload logs"
    spacewalk_upload_logs
rlPhaseEnd


rlJournalEnd
rlJournalPrintText
