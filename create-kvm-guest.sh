#!/bin/sh

release=${release:="24"}
echo $release
dnf install -y virt-install virt-viewer
virt-install \
   --name="fedora-${release}-spacewalk" \
   --disk path="/var/lib/libvirt/images/fedora-${release}-guest-1.dsk",size=8,sparse=false,cache=none \
   --graphics spice \
   --vcpus=2 --ram=2048 \
   --location="http://download.eng.brq.redhat.com/pub/fedora/linux/releases/${release}/Server/x86_64/os" \
   --network network:default \
    -x "ks=https://raw.githubusercontent.com/SatelliteQE/spacewalk-tests/master/config/fedora.ks" \
   --os-type=linux \
   --os-variant=fedora23 \
   --noautoconsole

# Now wait for installation to finish and start the host
while true; do
  virsh list | grep 'fedora-spacewalk.*running' && break
  sleep 5
done
while true; do
  virsh list --all | grep 'fedora-spacewalk.*shut off' && break
  sleep 15
done
virsh start fedora-spacewalk

# Populate Ansible inventory
mac=$( virsh dumpxml fedora-spacewalk | grep 'mac\s\+address=' | cut -d "'" -f 2 )
ip=$( arp -n | grep -i "$mac" | cut -d " " -f 1 )
echo "$ip" >config/hosts.ini
