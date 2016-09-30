# author: Pavel Studenik <pstudeni@redhat.com>
# year: 2016

install
text

# Use network installation
url --url="https://download.fedoraproject.org/pub/fedora/linux/releases/24/Server/x86_64/os"
repo --name="beaker-client" --baseurl="https://beaker-project.org/yum/client/Fedora24"

keyboard us
network --device=eth0 --bootproto=dhcp
timezone --utc Etc/UTC
firstboot --disabled

# System authorization information
auth --enableshadow --passalgo=sha512
# Root password
rootpw --iscrypted $1$gD1cZs4Q$DatrBjmob.xgo.0MzypMu.

# System services
services --enabled=NetworkManager,sshd,chronyd

# System bootloader configuration
bootloader --location=mbr
autopart --type=lvm
zerombr
# Partition clearing information
clearpart --all

# Selinux State
selinux --enforcing

# Enable ssh server
firewall --service=ssh

reboot

%packages
wget
make
vim
%end

%addon com_redhat_kdump --disable
%end

%post  --log=/root/post-script.log

# Install Beaker client tools
rpm --import https://beaker-project.org/gpg/RPM-GPG-KEY-beaker-project
dnf config-manager --add-repo https://beaker-project.org/yum/client/Fedora24
dnf install -y git rhts-test-env beakerlib --nogpgcheck

# Clone git with tests
mkdir -p /mnt/tests/CoreOS
cd /mnt/tests/CoreOS && git clone https://github.com/SatelliteQE/spacewalk-tests.git Spacewalk

# Configure ssh key
mkdir /root/.ssh
curl https://raw.githubusercontent.com/SatelliteQE/spacewalk-tests/master/config/id_rsa.pub > /root/.ssh/authorized_keys
chown root:root -R /root/.ssh/
chmod 700 -R /root/.ssh/
%end
