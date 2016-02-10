#!/bin/sh

# Copyright (c) 2015 Red Hat, Inc. All rights reserved. This copyrighted material
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

# Description:
#
# On Fedora 22 and above we have dnf, on lower Fedoras and all
# RHELs we have yum. Print which updater we should use.
#
# You can use something like this in your tests:
#   rlRun "$( helper-get-updater.sh ) repolist"

# Save if we are on Fedora or not
rpm --quiet -q --whatprovides fedora-release && fedora=true || fedora=false

# Determine which one we should use
if $fedora && [ "$( rpm -q --whatprovides fedora-release --qf '%{VERSION}\n' )" -lt 22 ]; then
  # If we are on Fedora older than 22
  echo 'yum'
elif $fedora; then
  # If we are on any other Fedora (22 and newer)
  echo 'dnf'
else
  # Everywhere else (all RHELs)
  echo 'yum'
fi
