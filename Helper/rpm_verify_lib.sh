#!/bin/bash
#
# Testing rpm verification library
#
# Bash library which aims to make the rpm verification of a workstation a bit
# easier. It usefull to verify packages before and after some other task/test
# to determine what has been changed during the task.
#
# Author:   Simon Lukasik <slukasik@redhat.com>
# Requires: bash >= 3
# Usage:    rpm_verify_save [destination]
#           rpm_verify_compare [whitelist_file [previous_result [current_result]]]
# Example:
#           rpm_verify_save
#           -- same taks goes here --
#           rpm_verify_compare /tmp/my_whitelist
#
#


function rpm_verify_save() {
  local storage=${1:-/tmp/rpm_verify}
  rpm -Va > $storage || [ $? -eq 1 ]
}


function rpm_verify_compare() {
  # Parse the command line first, it's always fun
  local score=0
  local whitelist=${1:-/dev/null}
  local old=${2:-/tmp/rpm_verify}
  local new=$3
  if [ $# -ne 3 ]; then
      new=`mktemp`
      rpm -Va > $new || [ $? -eq 1 ] || let score+=1
  fi
  for file in "$whitelist" "$old" "$new"; do
    if [ ! -f "$file" ]; then
      echo "Cannot found $file"
      return 1
    fi
  done

  # Check that each line in new report exists in previous (old) report
  # or matches the regular expression in given whitelist
  while read line; do
    if grep -v "$line" $old > /dev/null; then
      # line was not found within the old file
      local found=""
      while read pattern; do
        if [ ! "$pattern" ]; then
          continue # ignore blank lines
        fi
        if [[ "$line" =~ "$pattern" ]]; then
          found=1
          break
        fi
      done < $whitelist
      if [ ! "$found" ]; then
        echo $line
        let score+=1
      fi
    fi 
  done < $new
  return $score
}

