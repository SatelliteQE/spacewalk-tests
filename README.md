# spacewalk-tests

Tests for Spacewalk. Let's do open source tests for open source software!

For creating testing envroment you can run prepared script create-kvm.sh as root that create KVM guest with Fedora Os on your system. It is better and safe solution to run tests in virtual environment. 

```
sudo sh create-kvm-guest.sh
```

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

Example structure of test you find in dir /mnt/tests/CoreOS/Spacewalk/Others/Example
and for command for run chosed test looks folowing:

```
make -C /mnt/tests/CoreOS/Spacewalk/Others/Example
```

[1] https://beaker-project.org/docs/user-guide/example-task.html
