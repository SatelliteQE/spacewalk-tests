
dnf install -y virt-install 
virt-install \
   --name=fedora-spacewalk \
   --disk path=/var/lib/libvirt/images/fedora-guest-1.dsk,size=8,sparse=false,cache=none \
   --graphics spice \
   --vcpus=2 --ram=2048 \
   --location=http://download.eng.brq.redhat.com/pub/fedora/linux/releases/24/Server/x86_64/os/ \
   --network network:default \
    -x "ks=http://elisha.brq.redhat.com/cblr/svc/op/ks/profile/example-2:1:RedHatSatTeamQA" \
   --os-type=linux \
   --os-variant=rhel6
