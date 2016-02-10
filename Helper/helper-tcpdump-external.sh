#!/bin/bash
#
# Copyright (c) 2013 Red Hat, Inc. All rights reserved. This copyrighted material 
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
# Author:      Jan Hutar <jhutar@redhat.com>
# Description: This is basically just a wrapper around tcpdump so we do not
#              have to write this full long commandline to all the tests where
#              we will use that. This is far from being exact.
#              This will also ignore first two rows with header tcpdump prints.
# Usage:       # helper-tcpdump-external.sh start
#                Starts tcpdumping communication to external IPs in
#                the background. Returns non-0 when something fails here.
#              # helper-tcpdump-external.sh stop
#                Stops tcpdumping. Returns non-0 when something fails here.
#              # helper-tcpdump-external.sh log
#                Prints name of the log file holding what was tcpdumped.
# Files:       /etc/helper-tcpdump-external.pid
#                Format:
#                  [running|stopped] PID LOGFILE

function _ignore_general() {
  grep -v -e '^tcpdump: WARNING: Promiscuous mode not supported on the ".*" device$' \
          -e '^tcpdump: verbose output suppressed,' \
          -e '^listening on any,'
}

function _ignore_nonlocal() {
  local H=$( hostname | sed 's/\./\\./g' )
  grep -e "^[0-9:.]\+ [A-Z]\+ $H\.[0-9a-z]\+ > [a-zA-Z0-9._-]\+\.[0-9a-z]\+: .*$" \
       -e "^[0-9:.]\+ [A-Z]\+ [a-zA-Z0-9._-]\+\.[0-9a-z]\+ > $H\+\.[0-9a-z]\+: .*$"
}

function __send_host_email() {
  # $1 ... 'good' or 'bad'
  # $2 ... host or IP
  # Send email we have found host
  [ -e /tmp/tcpdump-mail-$2.lock ] \
    || echo $2 | mail -s "[helper-tcpdump-external.sh] $1 host detected: $2" jhutar@redhat.com
  # Create lock so we will send it only once
  touch /tmp/tcpdump-mail-$2.lock
}

function _ignore_akami() {
  touch /tmp/tcpdump-safe.list
  echo "whois.arin.net" >> /tmp/tcpdump-safe.list   # talking to whois server is OK as it might be produced by this script
  echo "2.18.252.218" >> /tmp/tcpdump-safe.list   # one of akamai IPs (2014-02-24)
  echo "2.20.24.218" >> /tmp/tcpdump-safe.list   # another of akamai IPs (2014-07-03)
  echo "2.17.123.86" >> /tmp/tcpdump-safe.list   # another of akamai IPs (2014-09-09)
  touch /tmp/tcpdump-known-bad.list
  hostname=$(hostname )
  ip_addr_show=$( ip addr show )
  while read row; do
    # Determine what was source and destination of the communication
    local src=$( echo "$row" | sed 's/^.\+ IP6\? \([^ ]\+\)\.[^ ]\+ > [^ ]\+\.[^ ]\+ .*$/\1/' )
    [ "$row" = "$src" ] && echo "$row" && continue
    local dst=$( echo "$row" | sed 's/^.\+ IP6\? [^ ]\+\.[^ ]\+ > \([^ ]\+\)\.[^ ]\+ .*$/\1/' )
    [ "$row" = "$dst" ] && echo "$row" && continue
    # If this was not communication from or to us, it is strange
    if [[ "$src" = "$hostname" || "$ip_addr_show" == *$src* ]]; then
      local host="$dst"
    elif [[ "$dst" = "$hostname" || "$ip_addr_show" == *$dst* ]]; then
      local host="$src"
    else
      echo "$row"
      continue
    fi
    # Check if we have already marked that host as Akamai owned in our cache
    grep --quiet "^$host\$" /tmp/tcpdump-safe.list && continue
    # Check if we have already marked that host as evil in our cache
    if grep --quiet "^$host\$" /tmp/tcpdump-known-bad.list; then
      echo $row
      continue
    fi
    # Determine if we have communicated with akamai system either based on
    # hostname or by IP
    if echo "$host" | grep --quiet '[a-zA-Z]'; then
      # If the hostname seems to be part of Akamai network, do not output it
      if echo "$host" | grep --quiet 'akamaitechnologies.com$'; then
        # Add host to the list of known-to-be-good hosts
        echo $host >> /tmp/tcpdump-safe.list
        continue
      else
        echo "$row"
        # Add the host to the list of known-to-be-bad hosts (kinda cache file)
        echo $host >> /tmp/tcpdump-known-bad.list
        continue
      fi
    else
      # If hostname for given IP seems to be part of Akamai network,
      # do not output it
      if host "$host" | grep --quiet 'akamaitechnologies.com\.$'; then
        # Add host to the list of known-to-be-good hosts
        echo $host >> /tmp/tcpdump-safe.list
        continue
      fi
      # Now (maybe no reverseDNS for the IP) try whois database
      if whois "$host" | grep --quiet '^descr:\s\+Akamai Technologies$'; then
        echo "$host" >> /tmp/tcpdump-safe.list
        # Send email we have found another Akamai IP adress
        __send_host_email 'good' "$host"
        # Add the host to the list of known-to-be-OK hosts (kinda cache file)
        echo $host >> /tmp/tcpdump-safe.list
        continue
      else
        echo "$row"
        # Send email we have found strange IP adress
        __send_host_email 'bad' "$host"
        # Add the IP to the list of known-to-be-bad hosts (kinda cache file)
        echo $host >> /tmp/tcpdump-known-bad.list
        continue
      fi
    fi
  done
}

function do_start() {
  if rpm -q --quiet tcpdump; then
    echo "INFO: Installed $( rpm -q tcpdump )"
  else
    echo "ERROR: tcpdump not installed"
    exit 1
  fi
  tcpdump_log=$( mktemp /tmp/tcpdump.XXXXXX )
  echo "INFO: Log will be '$tcpdump_log'"
  echo "DEBUG: Starting tcpdump"
  set -o pipefail
  tcpdump -i any "tcp and not src and dst net \
          ( \
            127.0.0.0/8 or \
            ::1 or \
            10.0.0.0/9 or \
            10.255.0.0/16 or \
            172.16.0.0/17 or \
            172.17.0.0/16 or \
            172.30.0.0/16 or \
            10.192.0.0/11 or \
            10.254.0.0/16 or \
            66.187.224.0/20 or \
            209.132.176.0/20 or \
            2620:0052:0000:0000:0000:0000:0000:0000/46 \
          )" 2>&1 \
    | _ignore_general \
    | _ignore_nonlocal \
    | _ignore_akami \
    >$tcpdump_log &
  tcpdump_rc=$?
  tcpdump_pid=$!
  if [ $tcpdump_rc -ne 0 ]; then
    echo "ERROR: tcpdump returned $tcpdump_pid"
    exit 1
  fi
  echo "DEBUG: Updating /etc/helper-tcpdump-external.pid"
  echo "running $tcpdump_pid $tcpdump_log" >> /etc/helper-tcpdump-external.pid
}

function do_stop() {
  score=0
  tcpdump_pid=$( grep '^running ' /etc/helper-tcpdump-external.pid | tail -n 1 | cut -d ' ' -f 2 )
  echo "DEBUG: Determined tcpdump pid $tcpdump_pid"
  kill "$tcpdump_pid"
  if [ $? -ne 0 ]; then
    let score+=1
    echo "ERROR: Failed to kill tcpdump pid $tcpdump_pid"
  else
    echo "INFO: tcpdump pid $tcpdump_pid killed"
  fi
  sed -i "s/^running $tcpdump_pid /stopped $tcpdump_pid /" /etc/helper-tcpdump-external.pid
  if [ $? -ne 0 ]; then
    let score+=1
    echo "ERROR: Failed to set tcpdump as stopped"
  else
    echo "INFO: tcpdump pid $tcpdump_pid set as stopped"
  fi
  return $score
}

function do_log() {
  tail -n 1 /etc/helper-tcpdump-external.pid | cut -d ' ' -f 3
}

case "$1" in
  start)
    do_start
    ;;
  stop)
    do_stop
    ;;
  log)
    do_log
    ;;
  *)
    echo "ERROR: No or unknown action specified"
    exit 1
    ;;
esac
