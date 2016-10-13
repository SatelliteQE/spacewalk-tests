#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Petr Sklenar <psklenar@redhat.com>
#          Dimitar Yordanov <dyordano@redhat.com>
#          Lukas Hellebrandt <lhellebr@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples:
# specific system-ID into base-channel:
# manage-system.py admin admin https://`hostname`/rpc/api set_base_channel
# 10001000 base-channel
# set auto errata update for system:
# manage-system.py admin admin https://`hostname`/rpc/api
# SET_AUTO_ERRATA_UPDATE whoami TRUE|FALSE

# whoami string means local system-ID
# more child channels add into quotes 'onechild secondchild':
# manage-system.py admin admin https://`hostname`/rpc/api set_child_channels
# whoami 'child-channel another-child-channel'
# manage-system.py admin admin https://`hostname`/rpc/api DELETE_SYSTEM
# 'whoami'
# manage-system.py admin admin https://`hostname`/rpc/api GET_GROUP_MEMBERSHIP
#  'whoami' 'test_group_1'
# manage-system.py admin admin https://`hostname`/rpc/api REM_GROUP_MEMBERSHIP
# 'whoami' 'test_group_1'
# manage-system.py admin admin https://`hostname`/rpc/api HW_REFRESH
# 'whoami' now
# manage-system.py admin admin https://`hostname`/rpc/api list_packages
# 'whoami'
# manage-system.py admin admin https://`hostname`/rpc/api is_package_installed
# 'whoami' $pkg $release $version
# manage-system.py admin admin https://`hostname`/rpc/api PKG_REFRESH
# 'whoami' now
# manage-system.py admin admin https://`hostname`/rpc/api PKG_INSTALL
# 'whoami' now PKG_ID
# manage-system.py admin admin https://`hostname`/rpc/api PKG_REMOVE
# 'whoami' now PKG_ID
# manage-system.py admin admin https://`hostname`/rpc/api SET_LOCK_STATUS
# 1000010000 LOCKED
# manage-system.py admin admin https://`hostname`/rpc/api GET_LOCK_STATUS
# 1000010000
# manage-system.py admin admin https://`hostname`/rpc/api SEARCH
# 'query_string'
# manage-system.py admin admin https://`hostname`/rpc/api UPGRADE_ENTITLEMENT
# 1000010000 [monitoring_entitled|provisioning_entitled|virtualization_host|
# virtualization_host_platform]
# manage-system.py admin admin https://`hostname`/rpc/api LIST_ACTIVE_SYSTEMS
# manage-system.py admin nimda https://`hostname`/rpc/api LIST_INACTIVE_SYSTEMS
# 10
# manage-system.py admin nimda https://`hostname`/rpc/api LIST_INACTIVE_SYSTEMS
# # default 1
# manage-system.py "$RHN_USER" "$RHN_PASS" "$SERVER"
# addChannels whoami "channel_label" false

# Schedule Remote script run.
# manage-system.py admin nimda https://`hostname`/rpc/api 'SCHEDULE_SCRIPT_RUN'
# '#!/bin/sh\nls\npwd' 'whoami' 'now'
# Get Result  from the script
# manage-system.py admin nimda https://${RHN_SERVER}/rpc/api
# 'GET_SCRIPT_RESULTS' ${ACTION_ID}

import sys
import time
from smqa_misc import read_system_id
import xmlrpclib
from spacewalk_api import Spacewalk


class System(Spacewalk):
    """class System provides methods to access and modify registered system.

    Namespace: system
    """

    def _get_time(self, time):
        if time.upper() == 'NOW':
            return self.call("system.searchByName", '\w')[0]['last_checkin']
        elif len(time) > 0:
            return time
        else:
            raise Exception("Time not specified")

    def get_server_id(self, server_id):
        if server_id == 'whoami':
            server_id = read_system_id()
        else:
            server_id = int(server_id)
        return server_id

    def system_exists(self, server_id):
        for row in self.call("system.listUserSystems"):
            if row.get('id') == server_id:
                return True
        return False

    def system_exists_loop(self, server_id, timeout=60):
        """Block untill system exists or timeout is reached"""
        attempt_sleep = 1   # check every 1 second
        attempt_max = float(timeout) / attempt_sleep
        attempt = 0
        while self.system_exists(server_id):
            time.sleep(attempt_sleep)
            attempt += 1
            assert attempt <= attempt_max, \
                'ASSERT: Was not able to delete system profile in time'
        return True

    def set_base_channel(self, server_id, channel_label):
        server_id = self.get_server_id(server_id)
        return self.call("system.setBaseChannel", server_id, channel_label)

    def add_channels(self, server_id, channel_labels, add_to_top):
        server_id = self.get_server_id(server_id)
        if channel_labels is None:
            raise RuntimeError("Channel labels not specified")
        return self.call("system.config.addChannels",
                         server_id, channel_labels.split(), add_to_top)

    def add_config_file(self, server_id, path=None, commit_to_local=True,
                        contents="", is_dir=False, owner='root', group='root',
                        permissions='644', macro_start_delimiter='{|',
                        macro_end_delimiter='|}',
                        selinux_ctx='root:object_r:unconfined_t',
                        binary=False):
        server_id = self.get_server_id(server_id)
        conf_file = {'contents': contents, 'owner': owner, 'group': group,
                     'permissions': permissions,
                     'macro-start-delimiter': macro_start_delimiter,
                     'macro-end-delimiter': macro_end_delimiter,
                     'selinux_ctx': selinux_ctx, 'binary': binary}
        try:
            self.call("system.config.createOrUpdatePath", server_id, path,
                      is_dir, conf_file, commit_to_local)
        except xmlrpclib.Fault:
            return False
        return True

    def list_packages(self, server_id):
        server_id = self.get_server_id(server_id)
        pkg_list = self.call("system.listPackages", server_id)
        for i in range(len(pkg_list)):
            print "%s %s %s %s %s" % (pkg_list[i]['name'],
                                      pkg_list[i]['arch'],
                                      pkg_list[i]['release'],
                                      pkg_list[i]['version'],
                                      pkg_list[i]['installtime'])
        return True

    def list_packages_from_channel(self, server_id):
        server_id = self.get_server_id(server_id)
        channels = self.call("system.listSubscribedChildChannels", server_id)
        channels += self.call("system.listSubscribableBaseChannels", server_id)
        for it in channels:
            pkg_list = self.call("system.listPackagesFromChannel", server_id,
                                 it['label'])
            for i in range(len(pkg_list)):
                print "%s %s %s" % (pkg_list[i]['name'],
                                    pkg_list[i]['release'],
                                    pkg_list[i]['version'])
        return True

    def list_packages_extra(self, server_id):
        server_id = self.get_server_id(server_id)
        pkg_list = self.call("system.listExtraPackages", server_id)
        for i in range(len(pkg_list)):
            print "%s %s %s" % (pkg_list[i]['name'],
                                pkg_list[i]['release'],
                                pkg_list[i]['version'])
        return True

    def is_package_installed(self, server_id, package_name, pkg_rel, pkg_ver):
        server_id = self.get_server_id(server_id)
        pkg_list = self.call("system.listPackages", server_id)
        for i in range(len(pkg_list)):
            if package_name == pkg_list[i]['name'] \
                and pkg_rel == pkg_list[i]['release'] \
                    and pkg_ver == pkg_list[i]['version']:
                return True  # package found
        return False  # package not found

    def set_child_channels(self, server_id, child_channels):
        server_id = self.get_server_id(server_id)
        child_channels = child_channels.strip().split()
        return self.call("system.setChildChannels", server_id, child_channels)

    def list_active_systems(self):
        sys_list = self.call("system.listActiveSystems")
        for i in range(len(sys_list)):
            print "%s %s %s" % (sys_list[i]['id'], sys_list[i]['name'],
                                sys_list[i]['last_checkin'])
        return True

    def delete_system(self, server_id):
        """Removes system's profile from  Satellite"""
        server_id = self.get_server_id(server_id)
        arr_server_id = [server_id]
        # Check we still have the profile
        details = self.call("system.getDetails", server_id)
        assert len(details) > 0
        # Delete
        self.call("system.deleteSystems", arr_server_id)
        # Check system profile was really deleted (it is asynchronous)
        return self.system_exists_loop(server_id, 60)

    def wait_till_system_exists(self, server_id):
        server_id = self.get_server_id(server_id)
        return self.system_exists_loop(server_id, 60)

    def list_info(self, server_id):
        server_id = self.get_server_id(server_id)
        print 'client.system.getCpu(): ', \
            self.call("system.getCpu", server_id)
        print 'client.system.getCustomValues(): ', \
            self.call("system.getCustomValues", server_id)
        print 'client.system.getDetails(): ', \
            self.call("system.getDetails", server_id)
        print 'client.system.getDevices(): ', \
            self.call("system.getDevices", server_id)
        print 'client.system.getDmi(): ', \
            self.call("system.getDmi", server_id)
        print 'client.system.getEntitlements(): ', \
            self.call("system.getEntitlements", server_id)
        print 'client.system.getMemory(): ', \
            self.call("system.getMemory", server_id)
        print 'client.system.getName(): ', \
            self.call("system.getName", server_id)
        print 'client.system.getNetwork(): ', \
            self.call("system.getNetwork", server_id)
        print 'client.system.getNetworkDevices(): ', \
            self.call("system.getNetworkDevices", server_id)
        print 'client.system.getRunningKernel(): ', \
            self.call("system.getRunningKernel", server_id)
        return True

    def get_group_membership(self, server_id, group_name):
        server_id = self.get_server_id(server_id)
        gr_param = self.call("systemgroup.getDetails", group_name)
        return self.call("system.setGroupMembership",
                         server_id, gr_param['id'], 1)

    def rem_group_membership(self, server_id, group_name):
        server_id = self.get_server_id(server_id)
        gr_param = self.call("systemgroup.getDetails", group_name)
        return self.call("system.setGroupMembership",
                         server_id, gr_param['id'], 0)

    def guest_provisioning(self, server_id, guest_name, profile_name):
        """create virt guest"""
        server_id = self.get_server_id(server_id)
        return self.call("system.provisionVirtualGuest", server_id,
                         guest_name, profile_name, 1024, 1, 3)

    def system_provisioning(self, server_id, profile_name):
        """provision machine"""
        server_id = self.get_server_id(server_id)
        return self.call("system.provisionSystem", server_id, profile_name)

    def list_virtual_guests(self, server_id):
        server_id = self.get_server_id(server_id)
        sys_list = self.call("system.listVirtualGuests", server_id)
        for i in range(len(sys_list)):
            name = None
            if 'name' in sys_list[i]:
                name = sys_list[i]['name']
            last_checkin = None
            if 'last_checkin' in sys_list[i]:
                last_checkin = sys_list[i]['last_checkin']
            print "%s %s %s %s" % (sys_list[i]['id'], name,
                                   sys_list[i]['guest_name'], last_checkin)
        return True

    def set_auto_errata_update(self, server_id, errata_update):
        server_id = self.get_server_id(server_id)
        if errata_update.upper() == 'FALSE':
            value = False
        elif errata_update.upper() == 'TRUE':
            value = True
        else:
            raise RuntimeError("Not recognized value: " + errata_update)

        self.call("system.setDetails", server_id,
                  {'auto_errata_update': value})
        details = self.call("system.getDetails", server_id)
        if details['auto_update'] != value:
            print "ERROR: After attempt to set auto_update = %s, \value is %s"\
                % (value, details['auto_update'])
            return 43
        return True

    def get_relevant_errata(self, server_id):
        server_id = self.get_server_id(server_id)
        for errata in self.call("system.getRelevantErrata", server_id):
            print errata
        return True

    def hw_refresh(self, server_id, time):
        server_id = self.get_server_id(server_id)
        try:
            self.call("system.scheduleHardwareRefresh",
                      server_id, self._get_time(time))
        except xmlrpclib.Fault:
            return False
        return True

    def reboot(self, server_id, time):
        server_id = self.get_server_id(server_id)
        return self.call("system.scheduleReboot",
                         server_id, self._get_time(time))

    def pkg_refresh(self, server_id, time):
        server_id = self.get_server_id(server_id)
        try:
            self.call("system.schedulePackageRefresh",
                      server_id, self._get_time(time))
        except xmlrpclib.Fault:
            return False
        return True

    def pkg_install(self, server_id, time, pkg_id):
        server_id = self.get_server_id(server_id)
        return self.call("system.schedulePackageInstall",
                         server_id, [int(pkg_id)], self._get_time(time))

    def pkg_remove(self, server_id, time, pkg_id):
        server_id = self.get_server_id(server_id)
        return self.call("system.schedulePackageRemove",
                         server_id, [int(pkg_id)], self._get_time(time))

    def schedule_script_run(self, script, server_id, time):
        server_id = self.get_server_id(server_id)
        print self.call("system.scheduleScriptRun", server_id, 'root', 'root',
                        60, script, self._get_time(time))
        return True

    def get_script_results(self, action_id):
        # Carefull here: if "rhn-action-control --disable-run" the result is []
        # (empty array)
        print self.call("system.getScriptResults", action_id)[0]['returnCode']
        return True

    def set_lock_status(self, server_id, lock_status):
        server_id = self.get_server_id(server_id)
        if lock_status.upper() == 'UNLOCKED':
            lock_status = True
        elif lock_status.upper() == 'LOCKED':
            lock_status = False
        else:
            raise Exception(
                'Lock status not set correctly, use LOCKED or UNLOCKED')
        return self.call("system.setLockStatus", server_id, lock_status)

    def search(self, server_id):
        server_id = self.get_server_id(server_id)
        syst = self.call("system.search.nameAndDescription", server_id)
        for p in range(len(syst)):
            print syst[p]['hostname']
        return True

    def get_lock_status(self, server_id):
        server_id = self.get_server_id(server_id)
        details = self.call("system.getDetails", server_id)
        if details['lock_status'] is True:
            print 'LOCKED'
        elif details['lock_status'] is False:
            print 'UNLOCKED'
        else:
            raise Exception('Returned lock status (%s) incorrect' %
                            details['lock_status'])
        return True

    def upgrade_entitlement(self, server_id, entitlement_name):
        server_id = self.get_server_id(server_id)
        return self.call("system.upgradeEntitlement",
                         server_id, entitlement_name)

    def create_system_record(self, server_id, ks_label):
        server_id = self.get_server_id(server_id)
        # Creates a cobbler system record with the specified kickstart label
        return self.call("system.createSystemRecord", server_id, ks_label)

    def create_package_profile(self, server_id, profile_label, description):
        server_id = self.get_server_id(server_id)
        return self.call("system.createPackageProfile", server_id,
                         profile_label, description)

    def compare_package_profile(self, server_id, profile_label):
        ret = 1
        for pm in self.call("system.comparePackageProfile",
                            server_id, profile_label):
            ret += 1
            print "%6s\t%-25s\t%-6s\t%-18s\t%-18s\t%s" % (
                pm['package_name_id'], pm['package_name'], pm['package_arch'],
                pm.get('this_system', 'none'), pm.get(
                  'other_system', 'none'), pm['comparison']
            )
        return ret

    def delete_package_profile(self, profile_id):
        return self.call("system.deletePackageProfile", profile_id)

    def list_package_profiles(self):
        print "%6s\t%-25s\t%s" % ('id', 'name', 'channel')
        for pp in self.call("system.listPackageProfiles"):
            print "%6s\t%-25s\t%s" % (pp['id'], pp['name'], pp['channel'])
        return True

    def get_custom_values(self, server_id):
        server_id = self.get_server_id(server_id)
        for cv in self.call("system.getCustomValues", server_id).iteritems():
            print "%s=%s" % cv
        return True

    def set_custom_value(self, server_id, custom_label, custom_value):
        server_id = self.get_server_id(server_id)
        return self.call("system.setCustomValues",
                         server_id, {custom_label: custom_value})

    def delete_custom_value(self, server_id, custom_label):
        server_id = self.get_server_id(server_id)
        return self.call("system.deleteCustomValues",
                         server_id, [custom_label])

    def list_inactive_systems(self, inactive_days=1):
        sys_list = self.call("system.listInactiveSystems", int(inactive_days))
        for i in range(len(sys_list)):
            print "%s %s %s" % (sys_list[i]['id'], sys_list[i]['name'],
                                sys_list[i]['last_checkin'])
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = System(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
