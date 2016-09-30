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

# Author: Jiri Mikulka

# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart

rlPhaseStartTest "Configure firewall"
    if rpm -q --quiet firewalld; then
        if rpm -q --quiet iptables && [ -n "$( iptables-save | grep -v -e '^#' -e '^\*' -e '^:' -e '^COMMIT' )" ]; then
            # Looks like we already have some iptables rules, so we probably
            # want to use iptables
            # http://post-office.corp.redhat.com/archives/satellite-dept-list/2014-October/msg00023.html
            choice='iptables'
        else
            choice='firewalld'
        fi
    elif rpm -q --quiet iptables; then
        choice='iptables'
    else
        choice='N/A'
    fi
    case $choice in
        firewalld)
            service $choice status || service $choice start
            rlServiceStart firewalld

            # 1) firewall - outbound open ports 80, 443, 4545
            # allowed by default
            # 2) firewall - inbound open ports 80/tcp, 443/tcp, 5222/tcp
            rlRun "firewall-cmd --permanent --add-port=80/tcp --add-port=443/tcp --add-port=5222/tcp"
            # 3) firewall - inbound open ports 5269/tcp, 69/udp
            rlRun "firewall-cmd --permanent --add-port=5269/tcp --add-port=69/udp"

            rlRun "firewall-cmd --reload"
        ;;
        iptables)
            touch /etc/sysconfig/iptables
            service $choice status || service $choice start
            rlServiceStart iptables

            # 1) firewall - outbound open ports 80, 443, 4545
            rlRun "iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT"
            rlRun "iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT"
            rlRun "iptables -A OUTPUT -p tcp --dport 4545 -j ACCEPT"
            # 2) firewall - inbound open ports 80/tcp, 443/tcp, 5222/tcp
            rlRun "iptables -A INPUT -p tcp --dport 80 -j ACCEPT"
            rlRun "iptables -A INPUT -p tcp --dport 443 -j ACCEPT"
            rlRun "iptables -A INPUT -p tcp --dport 5222 -j ACCEPT"
            # 3) firewall - inbound open ports 5269/tcp, 69/udp
            rlRun "iptables -A INPUT -p tcp --dport 5269 -j ACCEPT"
            rlRun "iptables -A INPUT -p udp --dport 69 -j ACCEPT"

            if rlIsRHEL 5 6; then
              rlRun "service iptables save"
            else
              # If you want to use this, make sure to have iptables-services
              # package installed (on RHEL7)
              if [ -x /usr/libexec/iptables/iptables.init ]; then
                rlRun "/usr/libexec/iptables/iptables.init save"
              else
                rlLogWarning "File /usr/libexec/iptables/iptables.init not available. Make sure you have iptables-services package installed. Firewall config was not saved."
              fi
            fi
        ;;
        *)
            rlLogInfo "No firewalling tool installed"
        ;;
    esac
rlPhaseEnd

rlJournalPrintText
rlJournalEnd
