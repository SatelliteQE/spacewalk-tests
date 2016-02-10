#!/bin/sh

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
# Author: Jan Hutar <jhutar@redhat.com>

set -e
set -o pipefail

# INFO
# ----
# 
# Install package $1 with supporting repos enabled.
# 
# These repos are setup before SW instalation and after
# it they are moved to /etc/yum.repos.d.SW_INSTALL_REPOS
# (because we do not want e.g. EPEL repo issues - like
# repo not available temporarily - to spoil other testing
# and yum ussage) so we can re-enable them when we need them.
# 
# Tipical use here is to install spacewalk-utils package
# as it comes from spacewalk-nightly repo and needs EPEL
# enabled.
# 
# $1 ... name of a package or some packages provides

# Make sure param was provided
if [ -z "$1" ]; then
  echo "ERROR: No package name provided"
  exit 1
fi

function is_installed() {
  # We are looking for:
  #   exact package name - like "sendmail"
  #   provides stuff - like "MTA" for "sendmail"
  #   versioned provides - like "sendmail > 8.14" for sendmail-8.14.4-8.el6
  if rpm --quiet -q "$1" \
     || rpm --quiet -q --whatprovides "$1" \
     || yum --disablerepo='*' whatprovides "$1" | grep 'Matched from:'; then
    return 0
  fi
  return 1
}

# If requested package is already installed, do not
# attempt to do so again
if is_installed "$1"; then
  echo "INFO: Package '$1' already installed"
  exit 0
fi

SCORE=0

# If we have supporting repos backed-up, re-enable them
YUM_REPOS_MOVED=false
if [ -d /etc/yum.repos.d.SW_INSTALL_REPOS ]; then
  echo "INFO: Enabling repos we had to support Spacewalk installation."
  rm -rf /etc/yum.repos.d.SW_POSTINSTALL_REPOS
  mv /etc/yum.repos.d /etc/yum.repos.d.SW_POSTINSTALL_REPOS
  cp -pr /etc/yum.repos.d.SW_INSTALL_REPOS /etc/yum.repos.d
  # As spacewalk-client repo is set after Spacewalk installation,
  # we want it here as well if it is available. If not, no worries.
  cp /etc/yum.repos.d.SW_POSTINSTALL_REPOS/spacewalk-client*.repo /etc/yum.repos.d/ || true
  YUM_REPOS_MOVED=true
else
  echo "WARNING: Supporting repos not available."
fi

# Do the installation
yum repolist || let SCORE+=1
yum install -y "$1" || let SCORE+=1

# Disable supporting repos if we have enabled them before
if $YUM_REPOS_MOVED; then
  echo "INFO: Remove repos we have set for dependencies"
  rm -rf /etc/yum.repos.d
  cp -pr /etc/yum.repos.d.SW_POSTINSTALL_REPOS /etc/yum.repos.d
fi

# Show what we have
is_installed "$1" || let SCORE+=1

[ "$SCORE" -gt 0 ] && echo "ERROR: Error occured"
exit $SCORE
