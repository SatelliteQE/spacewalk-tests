# spacewalk-tests

Tests for Spacewalk. Let's do open source tests for open source software!

## Creating VM to run the tests

To create testing envroment just create following script as root. Script creates KVM guest with Fedora OS on your system so tests can run in oredefined environment and would not disturb your workstation setup.

```
sudo ./create-kvm-guest.sh
```

Resulting guest *fedora-spacewalk* should have 2GB RAM, its IP should be in `config/hosts.ini`, roots password should be *spacewalk* and system should have `config/id_rsa.pub` in `/root/.ssh/authorized_keys` (private key is `config/id_rsa`).

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

## Running tests in the VM

### Directly via ssh

TODO: Install test's requirements before running it.

```
ssh -i config/id_rsa root@$( cat config/hosts.ini ) -C "make run -C /mnt/tests/CoreOS/Spacewalk/Others/Example"
```

### Via Ansible

If you have Ansible installed, you can run:

```
ansible-playbook --private-key config/id_rsa -i config/hosts.ini tests.yaml --extra-vars="test=/CoreOS/Spacewalk/Others/Example"
```

[1] https://beaker-project.org/docs/user-guide/example-task.html
