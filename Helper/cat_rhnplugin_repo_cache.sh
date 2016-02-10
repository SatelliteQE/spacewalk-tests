#!/bin/bash
#
# Simon Lukasik

set -e
set -o pipefail

is_fedora(){
    [ `rpm -q --qf '%{NAME}' --whatprovides redhat-release` == 'fedora-release' ]
}

yum_cache='/var/cache/yum'
file='rhnplugin.repos'
version=`rpm -q --qf '%{VERSION}' --whatprovides redhat-release`
num=`echo $version | sed "s/^\([0-9]\+\)[^0-9]\+.*$/\1/"`

if ! is_fedora && [ $num == 5 ]; then
    path=$yum_cache/$file
else
    path=$yum_cache/`uname -i`/$version/$file
fi

if [ -f $path ]; then
  cat $path
else
  echo "Note: $path does not exists"
fi

