#!/bin/bash
#
# Author: Simon Lukasik
#
set -e
set -o pipefail

default_reports="channel-packages channels entitlements errata-list
errata-list-all errata-systems inventory system-history system-history-channels
system-history-configuration system-history-entitlements system-history-errata
system-history-kickstart system-history-packages users users-systems"

function Print_help(){
  echo "$0 - tool for asserting the output of spacewalk-report"
  echo "Usage:"
  echo "  $1 init [report-name [report-name...]]   - Note the output of reports"
  echo "  $1 append report-name line               - Add new expected line"
  echo "  $1 modify report-name line               - Modify a single line of output"
  echo "  $1 remove report-name line               - Remove specified line from report"
  echo "  $1 sort report-name colums-range         - Sort expexted output by"
  echo "  $1 assert [report-name [report-name...]] - Compare noted+expected == output"
  echo "  $1 assert_unsorted [...]                 - Same as 'assert', but when comparing, ignore reports sorting"
  echo "  $1 help"
  echo
  echo "Example of the line:"
  echo "  %system_id%,%sequence%,%data-today%,Done,Subsribed to channel,test"
  echo
  echo "Escape sequences:"
  echo "  %organization_id(user)% - ID of the organization of given user"
  echo "  %organization(user)%    - Name of the organization of given user"
  echo "  %system_id%             - current system_id of the system"
  echo "  %rhn_brand%             - branding info (either RHN or Spacewalk)"
  echo "  %ip%                    - current system's ip address"
  echo "  %ipv6%                  - current system's ipv6 address"
  echo "  %date%                  - match the date format"
  echo "  %date_today%            - match the date format, assert for a day"
  echo "  %sequence%              - collumn should equal to previous+1"
  echo "  %plus(x)%               - increment the column (only for modify option)"
  echo "  %minus(x)%              - decrement the column (only for modify option)"
  echo "  %same%                  - do not modify column (only for modify option)"
  echo "  %replace(old,new)%      - replace old value with a new (only for modify option)"
  echo
  echo "Example:"
  echo "  $1 modify entitlements '%organization_id($DEFAULT_USER)%,%organization($DEFAULT_USER)%,system,RHN Management Entitled Servers,%plus(1)%,%same%,,'"
  echo "  $1 append system-history '%system_id%,%sequence%,%date_today%,Done,Added system entitlement,Monitoring'"
}

function Init_exists(){
  if [ ! -f $dir/$1.init ]; then
    echo "The report $1 was not initialized"
    exit 1
  fi
}

function _determine_ipv6(){
  # Last row of output of this function is IPv6 address which satellite
  # would recognize as this systems IPv6 address.
  # It caches what it determines in /tmp/reporting_ipv6_determined file.
  local ipv6=''
  if [ -r /tmp/reporting_ipv6_determined ]; then
    local ipv6=$( cat /tmp/reporting_ipv6_determined )
    return 0
  else
    local ipv6=`ifconfig | grep 'inet6 addr:.*Scope:Global' \
        | grep -v '::1/128' \
        | sed 's/^.*inet6 addr: \([0-9a-zA-Z:]\+\)\/.*$/\1/g' \
        | tail -n 1`
    if ping6 -c 3 $ipv6; then
      echo "DEBUG: ping6 to $ipv6 worked"
      if host -t AAAA $ipv6 | grep " $( hostname )\.$"; then
        echo "DEBUG: host -t AAAA on $ipv6 returned hostname"
        echo $ipv6 > /tmp/reporting_ipv6_determined
        echo $ipv6
        return 0
      fi
    fi
  fi
  echo "DEBUG: Not satellite recognized IPv6 adress found"
  echo
  # Although you can expect `return 1` here, we have `set -e` here
  # and we returned empty last line which should be sufficient to
  # notice there was some problem
  return 0
}

function Escape_primary(){
  local line="$@"
  local result=''
  local old_IFS="$IFS"
  IFS="%"
  for item in $line; do
    local keyword="${item%(*}"
    local param=${item#*(}
    local param=${param%*)}
    case "$keyword" in
      'system_id')
        result="$result`python -c "from smqa_misc import read_system_id;print read_system_id()"`"
        ;;

      'organization_id')
        local org=`spacewalk-report users | /mnt/tests/CoreOS/Spacewalk/Helper/helper-csv-if-x-is-y-print-z.py 3 "$param" 0`
        result="$result$org"
        ;;

      'organization')
        local org=`spacewalk-report users | /mnt/tests/CoreOS/Spacewalk/Helper/helper-csv-if-x-is-y-print-z.py 3 "$param" 1`
        result="$result$org"
        ;;

      'user_id')
        local id=`spacewalk-report users | /mnt/tests/CoreOS/Spacewalk/Helper/helper-csv-if-x-is-y-print-z.py 3 "$param" 2`
        result="$result$id"
        ;;

      'rhn_brand')
        if rpm --quiet -q spacewalk-branding; then
          result="${result}Spacewalk"
        else
          result="${result}RHN"
        fi
        ;;

      'ip')
        local ip=`ifconfig | grep 'inet addr:' | grep -v '127.0.0.1' \
            | cut -d: -f2 | awk '{ print $1}' | head -n1`
        result="${result}$ip"
        ;;

      'ipv6')
        result="${result}$( _determine_ipv6 | tail -n 1 )"
        ;;

      'date')
        result="${result}[0-9]{4}-[0-9]{2}-[0-9]{2} %HH:MM:SS%"
        ;;

      'date_today')
        result="$result$(date +%Y-%m-%d) %HH:MM:SS%"
        ;;

      'sequence'|'plus'|'same'|'replace')
        result="$result%$item%"
        ;;

      *)
        result="$result$item"
        ;;
    esac
  done
  IFS="$old_IFS"
  echo $result
}

function Escape_futher(){
  local line="$@"
  local result=''
  local old_IFS="$IFS"
  IFS="%"
  for item in $line; do
    case "$item" in
      'sequence')
        result="$result[1-9][0-9]*"
        ;;

      'HH:MM:SS')
        result="$result [0-9][0-9]:[0-9][0-9]:[0-9][0-9]"
        ;;

      *)
        result="$result$item"
    esac
  done
  IFS="$old_IFS"
  echo $result
}

function Diff_files_unsorted(){
  # $1 ... init report with changes added by functions like 'append'
  # $2 ... pure report gathered right before this
  local FD=7
  local score=0
  exec 7<$1
  # Prepare variables and data file so we can modify it
  local data_orig=$2
  local data=$( mktemp )
  local data_tmp=$( mktemp )
  cp $data_orig $data
  # Check that all patterns in file $2 are available in file $1
  while read pattern <&$FD; do
    local matched=false
    if ! $matched && grep -q -F "$pattern" $data; then
      { grep -F -v "$pattern" $data || true; } > $data_tmp
      grep -F "$pattern" $data | tail -n +2 >> $data_tmp   # ignore only first occurance of pattern
      matched=true
    fi
    if ! $matched && grep -q "$pattern" $data; then
      { grep -v "$pattern" $data || true; } > $data_tmp
      grep "$pattern" $data | tail -n +2 >> $data_tmp   # ignore only first occurance of pattern
      matched=true
    fi
    if ! $matched && grep -q "^`Escape_futher $pattern`\$" $data; then
      { grep -v "^`Escape_futher $pattern`\$" $data || true; } > $data_tmp
      grep "^`Escape_futher $pattern`\$" $data | tail -n +2 >> $data_tmp   # ignore only first occurance of pattern
      matched=true
    fi
    if $matched; then
      cp $data_tmp $data
    else
      echo "> $pattern"
      let score+=1
    fi
  done
  # Check that there are no extra lines in file $1
  local data_lines_left="$( wc -l $data | sed 's/^[^0-9]*\([0-9]\+\)[^0-9]*.*$/\1/' )"
  if [ $data_lines_left -ne 0 ]; then
    sed 's/^/< /' $data
    let score+=$data_lines_left
  fi
  # Return score (if this is >255, 212 will be returned)
  return $score
}

function Diff_files(){
  local FD1=6
  local FD2=7
  local eof1=0
  local eof2=0
  local score=0
  exec 6<$1
  exec 7<$2

  while [ $eof1 -eq 0 -o  $eof2 -eq 0 ]; do
    read data1 <&$FD1 || eof1=1
    read data2 <&$FD2 || eof2=1

    if [ "$data1" != "$data2" ]; then
      local escaped="^`Escape_futher $data1`\$"
      # escape parenthesis for regexp match (=~)
      escaped=${escaped//)/\\)}
      escaped=${escaped//(/\\(}
      if ! [[ $data2 =~ $escaped ]]; then
        echo "> $escaped"
        echo "< $data2"
        let score+=1
      fi
    fi
  done
  return $score
}

dir=/tmp/sw_reporting/
mkdir -p $dir

command='help'
[ -n "$1" ] && command="$1" && shift

assert_unsorted='false'
if [ "$command" = "assert_unsorted" ]; then
  command='assert'
  assert_unsorted='true'
fi

case $command in
  help)
    Print_help "$0"
    ;;

  init)
    reports="$@"
    [ -n "$reports" ] || reports=$default_reports
    for report in $reports; do
      spacewalk-report $report > $dir/$report.init
    done
    ;;

  append)
    report="$1"; shift
    line="$@"
    Init_exists $report
    Escape_primary "$line" >> $dir/$report.init
    ;;

  modify)
    report="$1"; shift
    line="$@"
    line=`Escape_primary "$line"`
    echo $line
    reporting_helper.py patch $dir/$report.init "$line"
    ;;

  remove)
    report="$1"; shift
    line="$@"
    file="$dir/$report.init"
    line=`Escape_primary "$line"`
    count=0
    grep -q "$line" $file \
      && count=`grep "$line" $file | wc -l`
    if [ "$count" -eq "1" ]; then
      sed -i "/^$line\$/d" $file
    else
      echo "The $file contains specified line $count times."
      exit 7
    fi
    ;;

  sort)
    report="$1"; shift
    keys="$@"
    file="$dir/$report.init"
    temp=`mktemp`
    {
      head -n 1 $file
      tail -n +2 $file | sort -s -g -t , -k $keys
    } > $temp
    mv $temp $file
    ;;

  assert)
    reports="$@"
    [ -n "$reports" ] || reports=$default_reports
    for report in $reports; do
      Init_exists $report
      spacewalk-report $report > $dir/$report.assert

      if $assert_unsorted; then
        Diff_files_unsorted $dir/$report.init $dir/$report.assert
      else
        Diff_files $dir/$report.init $dir/$report.assert
      fi
      if [ $? -ne 0 ]; then
        echo "Diffing $report failed"
        exit 1
      fi
    done
    ;;


  *)
    echo "unknown command"
    exit 1
    ;;
esac



