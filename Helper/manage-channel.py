#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Martin Korbel <mkorbel@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples:
#   Each of this examples must have  user, password and server
#   manage-channel.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api <Option>
# Options:
#   CREATE_CHANNEL my-channel i386
#   CREATE_CHANNEL sha512-channel i386 sha512
#   CLONE_CHANNEL True my-channel parent-channel
#   CLONE_CHANNEL True my-channel source-channel parent-channel
#   DELETE_CHANNEL my-channel
#   DELETE_CHANNEL my-channel True
#   DELETE_CONTENT my-channel
#   DELETE_CONTENT my-channel True
#   DELETE_PACKAGES_WITHOUT_CHANNEL
#   LIST_SYST_CHANNELS
#   LIST_PACKAGES_WITHOUT_CHANNEL
#   LIST_CHILD_CHANNELS my-channel
#   LIST_PACKAGES_FOR_CHANNEL my-channel
#   LIST_PACKAGES_FOR_CHANNEL_DETAILED my-channel
#   LIST_FILES_OF_PACKAGES_FOR_CHANNEL_DETAILED my-channel
#   SUBSCRIBE_SYST my-channel
#   GEN_REACT_KEY
#   GET_SYSTEM_ID
#   GET_CHANNEL_ID my-channel
#   GET_CHANNEL_INFO my-channel
#   GET_CHANNEL_SHARING my-channel
#   SET_CHANNEL_SHARING my-channel public
#   REGENERATE_YUM_CACHE my-channel
#   STATUS_YUM_CACHE my-channel
#   ADD_PACKAGE my-channel 1

import sys
import xmlrpclib
import re
import time
from spacewalk_api import Spacewalk
try:
    from smqa_misc import read_system_id
except ImportError:
    # When we are using this utility directly from GIT on our workstation,
    # we do not have this and it should be enough if we fail only if we need
    # this functionality, so it should be safe to ignore
    print >> sys.stderr, "WARNING: Failed to import smqa_misc - assuming manual mode"


class Channel(Spacewalk):
    """Provides methods to access and modify many aspects of a channel."""

    def channel_get_label(self, channel):
        if channel.get('label') is not None:
            return channel.get('label')
        else:
            return channel.get('channel_label')

    def package_get_id(self, package):
        if package.get('id') is not None:
            return package.get('id')
        else:
            return package.get('package_id')

    def packages_without_channel(self):
        packageids = []
        packages = self.call("channel.software.listPackagesWithoutChannel")
        for package in packages:
            packageids.append(self.package_get_id(package))
        return packageids

    def packages_in_specific_channel(self, channel):
        packageids = []
        packages = self.call("channel.software.listAllPackages", channel)
        for package in packages:
            packageids.append(self.package_get_id(package))
        return packageids

    def check_channel_exists(self, channel):
        # check if channel exists
        exists = False
        list = self.call("channel.listSoftwareChannels")
        for chann in list:
            if self.channel_get_label(chann) == channel:
                exists = True
        return exists

    def delete_free_package(self, packageids):
        # Delete free (package without channel) package from list
        if len(packageids) > 0:
            freeids = self.packages_without_channel()
            for packageid in packageids:
                if packageid in freeids:
                    self.call("packages.removePackage", packageid)

    def delete_free_errata(self, errata):
        # Delete free (errata without channel) errata from list
        if len(errata) > 0:
            for erratum in errata:
                if len(self.call("errata.applicableToChannels",
                       erratum['advisory_name'])) == 0:
                    self.call("errata.delete", erratum['advisory_name'])

    def list(self):
        # method listSoftwareChannels don't show all channels (without channels
        # that belong to the user's organization)
        try:
            list = self.call("channel.listAllChannels")
        except xmlrpclib.Fault, e:
            # On Hosted we do not have listAllChannels, so if we hit this
            # (and exactly this) exception, we should retry with listSoftwareChannels
            if str(e) == "<Fault -1: 'Could not find method listAllChannels in class class com.redhat.rhn.frontend.xmlrpc.channel.ChannelHandler'>":
                list = self.call("channel.listSoftwareChannels")
            else:
                raise
        for channel in list:
            print self.channel_get_label(channel)
        return True

    def clone_channel(self, original_state, channel, src_channel,
                      parent_channel=None):
        if not self.check_channel_exists(src_channel):
            return False
        # Clone channel, if we clone channel with erratas then we wait to event
        # will be done
        if self.check_channel_exists(channel):
            print "Channel already exists, aborting"
            return False
        clone = {'label': channel, 'name': 'Name of %s' %
                 channel, 'summary': 'Summary of %s' % channel}
        if parent_channel and self.check_channel_exists(parent_channel):
            clone['parent_label'] = parent_channel
        child = self.call("channel.software.clone",
                          src_channel, clone, original_state)
        if not original_state:
            src_errata_number = len(
                self.call("channel.software.listErrata", src_channel))
            errata_number = len(self.call("channel.software.listErrata",
                                channel))
            progress = "."
            sys.stdout.write(progress)
            sys.stdout.flush()
            while errata_number < src_errata_number:
                time.sleep(10)
                errata_number = len(
                    self.call("channel.software.listErrata", channel))
                progress += "."
                sys.stdout.write(".")
                sys.stdout.flush()
            sys.stdout.write(("\b" * len(progress)) + (
                " " * len(progress)) + ("\b" * len(progress)))
        print child
        return True

    def global_subcribable(self, channel):
        if not self.check_channel_exists(channel):
            print "Channel doesn't exist, aborting"
            return False
        print self.call("channel.software.isGloballySubscribable", channel)
        return True

    def set_globally_subscribable(self, channel, subsribable):
        if not self.check_channel_exists(channel):
            print "Channel doesn't exist, aborting"
            return False
        print self.call("channel.software.setGloballySubscribable",
                        channel, subsribable == 'True')
        return True

    def create_mapchannel(self, os, arch, release):
        if not self.check_channel_exists(os):
            print "Channel doesn't exists, aborting"
            return False
        return self.call("distchannel.setMapForOrg",
                         os, release, arch, os)

    def list_mapchannel(self):
        for it in self.call("distchannel.listMapsForOrg"):
            print "\t".join(it.values())
        return True

    def create_channel(self, channel, arch, parent_channel="", checksum=None,
                       gpgurl=None, gpgid=None, gpgfingerprint=None):
        if self.check_channel_exists(channel):
            print "Channel already exists, aborting"
            return False
        sysver = self.client.api.systemVersion()
        # strip ' Java' out of '5.2.0 Java'
        apiver = self.client.api.getVersion().split(None, 1)[0]
        apiver_parsed = (apiver + '.0').split('.', 2)
        # fill apiver with zeros for string comparissons like '10.8' < '10.11'
        apiver_formatted = "%02d.%02d" % (
            int(apiver_parsed[0]), int(apiver_parsed[1]))
        # checksum support is added for SAT5.4.0+ and SW0.9+
        # explicit inlcusion for sw0.8, its apiver==10.11
        if apiver_formatted < '10.11' or sysver == '0.8':
            checksum = None
        if checksum is None:
            # this is old call for sat530-
            ret = self.call("channel.software.create", channel,
                            'Name %s' % channel,
                            'Summary %s' % channel,
                            arch, parent_channel)
        elif gpgfingerprint is None:
            # this is new call for sw0.9+
            ret = self.call("channel.software.create", channel,
                            'Name %s' % channel,
                            'Summary %s' % channel,
                            arch, parent_channel, checksum)
        else:
            # this is new call for sat540+
            mystruct = {"url": str(gpgurl),
                        "id": str(gpgid),
                        "fingerprint": str(gpgfingerprint)
                        }
            ret = self.call("channel.software.create", channel,
                            'Name %s' % channel,
                            'Summary %s' % channel,
                            arch, parent_channel, checksum, mystruct)
        return ret

    def delete_channel(self, channel, only_detach=False):
        if not self.check_channel_exists(channel):
            return False
        packageids = self.packages_in_specific_channel(channel)
        errata = self.call("channel.software.listErrata", channel)
        self.call("channel.software.delete", channel)
        if not only_detach:
            self.delete_free_package(packageids)
            self.delete_free_errata(errata)
        return True

    def delete_content(self, channel, only_detach=False):
        if not self.check_channel_exists(channel):
            return False
        # remove errata and packages from channel and if they are free
        # (no other channel) then they are deleted
        packageids = self.packages_in_specific_channel(channel)
        errata = self.call("channel.software.listErrata", channel)
        self.call("channel.software.removePackages", channel, packageids)
        if not re.match(r"^5\.[01234].*", self.client.api.systemVersion()):
            # this do not work on Satellite 5.4.1 and older
            self.call("channel.software.removeErrata",
                      channel, [e['advisory_name'] for e in errata], False)
        if not only_detach:
            self.delete_free_package(packageids)
            self.delete_free_errata(errata)
        return True

    def delete_packages_without_channel(self):
        packageids = self.packages_without_channel()
        self.delete_free_package(packageids)
        return True

    def list_packages_without_channel(self):
        for pkg_id in self.packages_without_channel():
            print pkg_id
        return True

    def list_packages_for_channel(self, channel):
        if not self.check_channel_exists(channel):
            return False
        for pkg_id in self.packages_in_specific_channel(channel):
            print pkg_id
        return True

    def list_packages_for_channel_detailed(self, channel):
        if not self.check_channel_exists(channel):
            return False
        for pkg_id in self.packages_in_specific_channel(channel):
            details = self.call("packages.getDetails", pkg_id)
            out = ""
            for k in sorted(details.keys()):
                out = out + \
                    "%s: %s|" % (k, unicode(details[k]).replace(
                        '\n', '').encode('ascii', 'xmlcharrefreplace'))
            print out
        return True

    def list_files_of_packages_for_channel_detailed(self, channel):
        # This is supposed to list all files of all packages from channel
        # This was created for bug 652852
        # You probably want to sort output to be able to compare
        # Note that on 5.4.0 (bug 659364) this do not returns links
        # and directories
        packageids = self.packages_in_specific_channel(channel)
        for pkgid in packageids:
            files = self.call("packages.listFiles", pkgid)
            for details in files:
                out = ""
                for k in sorted(details.keys()):
                    out = out + \
                        "%s: %s|" % (k, unicode(details[k]).replace(
                            '\n', '').encode('ascii', 'xmlcharrefreplace'))
                print out
        return True

    def list_syst_channels(self):
        try:
            # taking into {try: exept} in order to return 0 when all
            # the operations below are successful. [gkhachik]
            # edit: we want to see potential API tracebacks, so API calls were
            # moved to else: block [pnovotny]
            system_id = read_system_id()
        except:
            return False
        else:
            for c in self.call("system.listSubscribableBaseChannels",
                               system_id):
                if c['current_base'] == 1:
                    print c['label']
            for c in self.call("system.listSubscribedChildChannels",
                               system_id):
                print c['label']
        return True

    def list_child_channels(self, channel):
        for child_channel in self.call("channel.software.listChildren",
                                       channel):
            print child_channel['label']
        return True

    def subscribe_syst(self, channel):
        if not self.check_channel_exists(channel):
            return False
        return self.call("channel.software.subscribeSystem", read_system_id(),
                         channel)

    def gen_react_key(self, system_id):
        if not isinstance(system_id, int):
            system_id = read_system_id()
        # Add provisioning entitlement
        if 'provisioning_entitled' not in self.call("system.getEntitlements",
                                                    system_id):
            self.call("system.addEntitlements",
                      system_id, ('provisioning_entitled',))
        # Print system with newest 'last_checkin'
        print self.call("system.obtainReactivationKey", system_id)
        return True

    def get_system_id(self):
        print read_system_id()
        return True

    def get_channel_id(self, channel):
        print self.call("channel.software.getDetails", channel)['id']
        return True

    def set_channel_sharing(self, channel, sharing_level):
        if not self.check_channel_exists(channel):
            return False
        self.call("channel.access.setOrgSharing", channel, sharing_level)
        return True

    def get_channel_sharing(self, channel):
        if not self.check_channel_exists(channel):
            return False
        self.call("channel.access.getOrgSharing", channel)
        return True

    def regenerate_yum_cache(self, channel):
        if not self.check_channel_exists(channel):
            return False
        self.call("channel.software.regenerateYumCache", channel)
        return True

    def status_yum_cache(self, channel):
        ver = self.client.api.systemVersion()
        # this functionality is available on sat540+ and sw13+
        if ver.find('nightly') == -1 \
           and int(ver[0]) != 2 \
           and int(ver[0]) <= 5 \
           and int(ver[2]) < 4:
            print "N/A: Function is not available on sw/sat version: '%s'" % ver
            return 4
        else:
            channelDetails = self.call("channel.software.getDetails", channel)
            lastModified = channelDetails['last_modified']
            lastModified = time.strptime(lastModified.value, "%Y%m%dT%H:%M:%S")
            lastBuild = self.call("channel.software.getChannelLastBuildById",
                                  channelDetails['id'])
            try:
                import re
                lastBuild = re.search("^(.*) [A-Z]+$", lastBuild)
                lastBuild = lastBuild.group(1)
                lastBuild = time.strptime(lastBuild, "%Y-%m-%d %H:%M:%S")
            except AttributeError:
                # probably because cache is not available, so '' was returned
                lastBuild = None
            if lastModified == lastBuild:
                print "FRESH (%s) == (%s)" % (time.strftime('%Y-%m-%d %H:%M:%S %Z', lastModified), time.strftime('%Y-%m-%d %H:%M:%S %Z', lastBuild))
                return True
            else:
                lastBuildStr = str(lastBuild)
                if lastBuild is not None:
                    lastBuildStr = time.strftime('%Y-%m-%d %H:%M:%S %Z', lastBuild)
                print "STALE (%s) != (%s)" % (time.strftime('%Y-%m-%d %H:%M:%S %Z', lastModified), lastBuildStr)
                return 2
        return True

    def get_channel_info(self, channel):
        if not self.check_channel_exists(channel):
            return False
        info = self.call("channel.software.getDetails", channel)
        for k in sorted(info.keys()):
            print "%s: %s" % (k, info[k])
        return True

    def add_package(self, channel, packageid):
        if not self.check_channel_exists(channel):
            return False
        return self.call("channel.software.addPackages",
                         channel, [int(packageid), ])

    def available_entitlements(self, channel):
        if not self.check_channel_exists(channel):
            return False
        print channel
        print self.call("channel.software.availableEntitlements", channel)
        return True

    def list_arches(self):
        for label in self.call("channel.software.listArches"):
            print label
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = Channel(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
