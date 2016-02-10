#!/bin/bash
# vim: dict=/usr/share/beakerlib/dictionary.vim cpt=.,w,b,u,t,i,k
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   runtest of /CoreOS/Spacewalk/Helper
#   Description: Helper utilities for Spacewalk tests
#   Author: Simon Lukasik <slukasik@redhat.com>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   Copyright (c) 2010 Red Hat, Inc. All rights reserved.
#
#   This copyrighted material is made available to anyone wishing
#   to use, modify, copy, or redistribute it subject to the terms
#   and conditions of the GNU General Public License version 2.
#
#   This program is distributed in the hope that it will be
#   useful, but WITHOUT ANY WARRANTY; without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
#   PURPOSE. See the GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public
#   License along with this program; if not, write to the Free
#   Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
#   Boston, MA 02110-1301, USA.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


#
# This is not standalone test, it will only create symlinks from helper
# scripts to your test folder. Insert following line into your test:
# 
#   export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
#
#

HELPER_DIR=/mnt/tests/CoreOS/Spacewalk/Helper


. /usr/bin/rhts-environment.sh
. /usr/share/beakerlib/beakerlib.sh

if [ ! -d $HELPER_DIR ]; then
  rlLogError "$HELPER_DIR doesn't exists."
  exit 1;
fi

if [ "`pwd`" == "$HELPER_DIR" ]; then
  rlLogError "You are trying to source content of directory A to directory A ... This action does not make a sense."
  exit 1;
fi

#enjoy:
chmod a+x $HELPER_DIR/*

for file in `ls $HELPER_DIR/*.{py,sh}`; do
  filename=`basename $file`
  if [ "$filename" != "runtest.sh" ]; then
    rm -rf $filename    # update obsoleted files with the latest version
    ln -s $file $filename
    if [ "$?" != "0" ]; then
      rlLogError "$file cannot be sourced!"
    fi
  fi
done


