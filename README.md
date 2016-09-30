# spacewalk-tests

Tests for Spacewalk. Let's do open source tests for open source software!

## Creating VM to run the tests

To create testing envroment just create following script as root. Script creates KVM guest with Fedora OS on your system so tests can run in oredefined environment and would not disturb your workstation setup.

```
sudo ./create-kvm-guest.sh
```

## How the Beaker test looks like

Example how to test looks[1]:

```
# cat runtest.sh
#!/bin/bash
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

For an example test see Spacewalk/Others/Example directory. To run the test, you can:

```
make -C Spacewalk/Others/Example
```

[1] https://beaker-project.org/docs/user-guide/example-task.html
