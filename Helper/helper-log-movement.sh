#!/bin/sh

# Works with given file and creates backups of it or reports latest backups
# 
#   $1 ... action (--backup, --get-latest)
#   $2 ... full file path
# 
# Returns 0 if action suceeded

# Load and show options
option="$1"
file="$2"
if [ $# -eq 1 ]; then
  file="$option"
  option="--backup"   # use default action
fi
echo "ACTION: $option"
echo "FILE: $file"

# Check options are sane
if [ ! -f "$file" -a "$option" != '--get-latest' ]; then
  echo "ERROR: File does not exist."
  exit 1
fi
if [ "$option" != "--backup" -a "$option" != "--get-latest" ]; then
  echo "ERROR: Unsupported action choosen"
  exit 1
fi

# Determine version of file
backup_version=$( find $file.* 2>/dev/null | sed s/\.checked$//g \
    | awk 'BEGIN{FS="."} /[0-9]+$/{print $NF}' | sort -n | tail -n1 )

case $option in
  --backup)
    if [ -f "$file" ]; then
      [ -z "$backup_version" ] && backup_version=0
      let backup_version+=1
      echo "Moving file to '$file.$backup_version'"
      mv $file $file.$backup_version || exit 1
      : > $file || exit 1
    else
      echo "No such file or directory: $file"
    fi
  ;;
  --get-latest)
    [ -n "$backup_version" ] && backup_version=".$backup_version"
    [ -e "$file$backup_version" ] || exit 1
    echo "$file$backup_version"
    exit 0
  ;;
esac

exit 0
