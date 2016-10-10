#!/bin/sh

release=${release:="24"}
guest="fedora-${release}-spacewalk"
echo "==========================="
echo "    Install Fedora $release"
dnf install -y virt-install virt-viewer
virt-install \
   --name="${guest}" \
   --disk path="/var/lib/libvirt/images/${guest}-1.dsk",size=8,sparse=false,cache=none \
   --graphics spice \
   --vcpus=2 --ram=2048 \
   --location="https://download.fedoraproject.org/pub/fedora/linux/releases/${release}/Server/x86_64/os/" \
   --network network:default \
    -x "ks=https://raw.githubusercontent.com/SatelliteQE/spacewalk-tests/master/config/fedora.ks" \
   --os-type=linux \
   --os-variant=fedora23 \
   --noautoconsole
if [ $? -ne 0 ]; then
  echo "ERROR: Failed to install the virtual machine" >&2
  exit 1
fi

# Now wait for installation to finish and start the host
while true; do
  virsh list | grep "${guest}.*running" && break
  sleep 5
done
while true; do
  virsh list --all | grep "$guest.*shut off" && break
  sleep 15
done
virsh start fedora-spacewalk

# Populate Ansible inventory
mac=$( virsh dumpxml $guest | grep 'mac\s\+address=' | cut -d "'" -f 2 )
ip=$( arp -n | grep -i "$mac" | cut -d " " -f 1 )
echo "$ip" >config/hosts.ini
