# spacewalk-tests

Tests for Spacewalk. Let's do open source tests for open source software!



Example how to test looks[1]:

```
#!/bin/bash
# File: runtest.sh
# Include Beaker environment
. /usr/bin/rhts-environment.sh || exit 1
. /usr/share/beakerlib/beakerlib.sh || exit 1

rlJournalStart
    rlPhaseStartTest
        rlRun "cat /proc/filesystems | grep 'ext4'" 0 "Check if ext4 is supported"
    rlPhaseEnd
rlJournalPrintText
rlJournalEnd
```


[1] https://beaker-project.org/docs/user-guide/example-task.html
