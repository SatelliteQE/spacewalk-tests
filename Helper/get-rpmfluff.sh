#!/bin/sh

# This script is meant to provide easy way to obtain rpmfluff.py script
#
# Usage:
#   rm -f rpmfluff.py
#   ./get-rpmfluff.sh

SCORE=0

# Get rpmfluff.py
rm -f rpmfluff.py
count=10
atempt=0
while [ $atempt -lt $count ]; do
  wget  --quiet  --output-document=rpmfluff.py 'https://git.fedorahosted.org/cgit/rpmfluff.git/plain/rpmfluff.py?id=956609fdb7ffe539128f13dba80480728ea913fe'   # later commints brings RHEL5 incompability
  rc=$?
  head -n 1 rpmfluff.py | grep -q -- '-\*- coding: UTF-8 -\*-' \
    && python -c "import rpmfluff" \
    && break
  echo "# WARNING: Another attempt in getting rpmfluff.py"
  rm -f rpmfluff.py
  let atempt+=1
  sleep 10
done
SCORE=$( expr $SCORE + $rc )
chmod +x rpmfluff.py

# rpmfluff.py needs rpm-build package
rpm -q rpm-build > /dev/null
SCORE=$( expr $SCORE + $? )

exit $SCORE
