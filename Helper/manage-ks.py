#!/usr/bin/python
# -*- coding: UTF-8 -*-

# author: Patrik Segedy <psegedy@redhat.com>
# year: 2016

# EXAMPLE RUN for CREATEDISTRO:
# 1. rlRun "manage-channel.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api CREATE $MYCHANNEL i386"
#    ^^^ you need channel
# 2. tempdir=`mktemp -d`
# 2. mkdir $tempdir/images/pxeboot -p
# 2. touch $tempdir/images/pxeboot/initrd.img
# 2. touch $tempdir/images/pxeboot/vmlinuz
# 2. chmod 777 $tempdir -R
#    ^^^ you needd special files readable by apache and tomcat
# 3. rlRun "manage-ks.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api CREATEDISTRO ks-$MYCHANNEL $tempdir $MYCHANNEL"
#    ^^^ finnaly create distro
# 4. rlRun "manage-ks.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api DELETEDISTRO ks-$MYCHANNEL"
#    ^^^ and delete that distro

# CLONE your profile (you need ks profile)
# manage-ks.py admin admin https://`hostname`/rpc/api CLONE
# original-profile clone-of-original

# SET and GET ks.cfg preservation (same functionality as checkbox in webui)
# manage-ks.py admin admin https://`hostname`/rpc/api GETPRESERVATION kslabel
# manage-ks.py admin admin https://`hostname`/rpc/api SETPRESERVATION
# kslabel <boolean>

import sys
from spacewalk_api import Spacewalk


class Kickstart(Spacewalk):
    """
    Class Kickstart provides methods to create kickstart files

    Namespace: kickstart
    """

    def createdistro(self, ks_label, ks_path, ks_channel, type="rhel_5"):
        return self.call("kickstart.tree.create", ks_label, ks_path,
                         ks_channel, type)

    def deletedistro(self, ks_label):
        return self.call("kickstart.tree.delete", ks_label)

    def list(self):
        for channel in self.call("channel.listAllChannels"):
            for tree in self.call("kickstart.tree.list", channel["label"]):
                getDetails = self.call("kickstart.tree.getDetails", tree["label"])
                print "------------------------------"
                print "tree[label] %s" % tree["label"]
                print "getDetails - all %s" % getDetails
                print "getDetails[id] %s" % getDetails["id"]
                print "getDetails[label] %s" % getDetails["label"]
                print "getDetails[abs_path] %s" % getDetails["abs_path"]
                print "getDetails[channel_id] %s" % getDetails["channel_id"]
                print "install_type.id: %s" % getDetails["install_type"]["id"]
                print "install_type.label: %s" % getDetails["install_type"]["label"]
                print "install_type.name: %s" % getDetails["install_type"]["name"]
        return True

    def list_distro_for_channel(self, channel):
        ks_trees = self.call("kickstart.tree.list", channel)
        for ks in ks_trees:
            print ks['label']
        return True

    def list_for_channel_detailed(self, channel):
        ks_trees = self.call("kickstart.tree.list", channel)
        for ks in ks_trees:
            details = self.call("kickstart.tree.getDetails", ks["label"])
            out = ""
            for k in sorted(details.keys()):
                out = out + \
                    "%s: %s|" % (k, unicode(details[k]).replace(
                        '\n', '').encode('ascii', 'xmlcharrefreplace'))
            print out
        return True

    def clone(self, ks_label, ks_path):
        return self.call("kickstart.cloneProfile", str(ks_label), str(ks_path))

    def createprofile(self, ks_label, virt, tree_label, ks_host, ks_pass):
        return self.call("kickstart.createProfile", ks_label, virt, tree_label,
                         ks_host, ks_pass)

    def importprofile(self, ks_label, virt, tree_label, ks_host, ks_file):
        ks_file = open(ks_file).read()
        return self.call("kickstart.importFile", ks_label, virt, tree_label,
                         ks_host, ks_file)

    def deleteprofile(self, ks_label):
        ret = self.call("kickstart.deleteProfile", str(ks_label))
        if ret == 0:
            raise Exception(
                "Kickstart profile wasn't found or couldn't be deleted")
        return ret

    def listprofile(self):
        for profile in self.call("kickstart.listKickstarts"):
            print profile
        return True

    def getpreservation(self, ks_label):
        print self.call("kickstart.profile.getCfgPreservation", str(ks_label))
        return True

    def setpreservation(self, ks_label, value):
        ret = self.call("kickstart.profile.setCfgPreservation", str(ks_label),
                        value)
        if ret == 0:
            raise Exception("Kickstart setCfgPreservation failed.")
        return ret

    def addscript(self, ks_label, name, contents, interpreter, stype, chroot):
        if not stype in ("pre", "post"):
            raise Exception("Parameter 'type of script' must be pre or post.")

        print self.call("kickstart.profile.addScript", str(ks_label), name,
                        contents, interpreter, stype, chroot)
        return True

    def addactivationkey(self, ks_label, ak):
        print ak, ks_label
        return self.call("kickstart.profile.keys.addActivationKey",
                         str(ks_label), ak)

    def enableconfigmanage(self, ks_label):
        return self.call("kickstart.profile.system.enableConfigManagement",
                         str(ks_label))

    def enableremotecommands(self, ks_label):
        return self.call("kickstart.profile.system.enableRemoteCommands",
                         str(ks_label))

    def disableconfigmanage(self, ks_label):
        return self.call("kickstart.profile.system.disableConfigManagement",
                         str(ks_label))

    def disableremotecommands(self, ks_label):
        return self.call("kickstart.profile.system.disableRemoteCommands",
                         str(ks_label))

    def setadvancedoptions(self, ks_label, contents):
        """
        Args:
            ks_label: Kickstart profile label
            contents: Advanced options in string format
                     "keyboard=us;...;..."
        """
        lines = contents.split(";")
        array = self.call("kickstart.profile.getAdvancedOptions", ks_label)
        for it in lines:
            data = it.split("=")
            if len(data) == 1:
                array.append({"name": data[0]})
            elif len(data) == 2:
                array.append({"name": data[0], 'arguments': data[1]})
            else:
                raise Exception('Incorrect number of fields.')
        return self.call("kickstart.profile.setAdvancedOptions", ks_label,
                         array)

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = Kickstart(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
