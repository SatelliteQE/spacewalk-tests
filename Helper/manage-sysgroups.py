#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Dimitar Yordanov <dyordano@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  CREATE test_group_1 'Test Group'
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  UPDATE test_group_1 "Update test"
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  GET_GROUP_ID test_group_1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  DELETE test_group_1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  GETDETAILS test_group_1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTALLGROUPS
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTSYSTEMS test_group
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTADMINISTRATORS test_group
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTACTIVESYSTEMS test_group
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTinACTIVESYSTEMS test_group 5
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTinACTIVESYSTEMS test_group # default 1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  LISTGROUPSWITHnoASSOCIATEDADMINIS
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  ADDSYSTEMS 'profile1 profile2' test_group1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  REMOVESYSTEMS 'profiel1 profile2' test_group1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  REMOVEADMINS 'test1 testtest' test_group1
#  manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
#  ADDADMINS 'test1 testtest' test_group1
#
# 1234=errata ID
# manage-sysgroups.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# APPLYERRATANOW group_name "1234 4567 8901"

import sys
import xmlrpclib
from spacewalk_api import Spacewalk


class SysGroups(Spacewalk):
    """Class SysGroups orovides methods to access and modify system groups.

    Namespace: systemgroup
    """

    def get_errata_list(self, errata_id):
        errata_ids = []
        if errata_id:
            for eid in errata_id.strip().split():
                if eid.isdigit():
                    print eid
                    errata_ids.append(int(eid))
        return errata_ids

    def get_system_id(self, sys_profiles):
        sys_ids = []
        if sys_profiles:
            for name in sys_profiles.strip().split():
                try:
                    sys_ids.append(
                        self.call("system.getId", name)[0]['id'])
                except:
                    sys_ids.append(int(name))
        return sys_ids

    def create(self, group_name, description):
        try:
            self.call("systemgroup.create", group_name, description)
        except xmlrpclib.Fault, e:
            print "Could not create group: ", e
            return False
        return True

    def delete(self, group_name):
        try:
            self.call("systemgroup.delete", group_name)
        except xmlrpclib.Fault, e:
            print "Could not delete group: ", e
            return False
        return True

    def getdetails(self, group_name):
        try:
            gr_param = self.call("systemgroup.getDetails", group_name)
            for k, v in gr_param.items():
                print "%s=%s" % (k, v)
        except xmlrpclib.Fault, e:
            print "Could not get system groups details : ", e
            return False

    def get_group_id(self, group_name):
        try:
            gr_param = self.call("systemgroup.getDetails", group_name)
            print gr_param['id']
        except xmlrpclib.Fault, e:
            print "Could not get Group ID for details : ", e
            return False
        return True

    def update(self, group_name, description):
        try:
            self.call("systemgroup.update", group_name, description)
        except xmlrpclib.Fault, e:
            print "Could not UPDATE Group : ", e
            return False
        return True

    def listsystems(self, group_name):
        try:
            system_list = self.call("systemgroup.listSystems", group_name)
            for i in range(len(system_list)):
                print system_list[i]['id'], system_list[i]['profile_name'], \
                    system_list[i]['hostname']
        except xmlrpclib.Fault, e:
            print "Could not list systems : ", e
            return False
        return True

    def listactivesystems(self, group_name):
        try:
            act_systems = self.call("systemgroup.listActiveSystemsInGroup",
                                    group_name)
            for i in range(len(act_systems)):
                print act_systems[i]
        except xmlrpclib.Fault, e:
            print "Could not list active systems : ", e
            return False
        return True

    def listinactivesystems(self, group_name, days_ago=None):
        try:
            if days_ago is None:
                inactive = self.call("systemgroup.listInactiveSystemsInGroup",
                                     group_name)
            else:
                inactive = self.call("systemgroup.listInactiveSystemsInGroup",
                                     group_name, days_ago)

            for i in range(len(inactive)):
                print inactive[i]
        except xmlrpclib.Fault, e:
            print "Could not list active systems : ", e
            return False
        return True

    def listadministrators(self, group_name):
        try:
            admin_list = self.call("systemgroup.listAdministrators",
                                   group_name)
            for i in range(len(admin_list)):
                print admin_list[i]['login_uc']
        except xmlrpclib.Fault, e:
            print "Could not list admins : ", e
            return False
        return True

    def listgroupswithnoassociatedadminis(self):
        try:
            no_admins = self.call(
                "systemgroup.listGroupsWithNoAssociatedAdmins")
            for i in range(len(no_admins)):
                print no_admins[i]['name']
        except xmlrpclib.Fault, e:
            print "Could not list groups with no admins  : ", e
            return False
        return True

    def listallgroups(self):
        try:
            group_list = self.call("systemgroup.listAllGroups")
            for i in range(len(group_list)):
                #{'description': 'Test', 'system_count': 0, 'org_id': 1,
                #'id': 81, 'name': 'test_group'}
                print group_list[i]['name']
        except xmlrpclib.Fault, e:
            print "Could not List All Groups : ", e
            return False
        return True

    def addadmins(self, users, group_name):
        try:
            users = users.strip().split()
            print users
            self.call("systemgroup.addOrRemoveAdmins", group_name, users, 1)
        except xmlrpclib.Fault, e:
            print "Could not add/remove admins  : ", e
            return False
        return True

    def removeadmins(self, users, group_name):
        try:
            users = users.strip().split()
            self.call("systemgroup.addOrRemoveAdmins",
                      group_name, users, False)
        except xmlrpclib.Fault, e:
            print "Could not ADD Users:", e
            return False
        return True

    def addsystems(self, profiles, group_name):
        try:
            system_id = self.get_system_id(profiles)
            self.call("systemgroup.addOrRemoveSystems",
                      group_name, system_id, True)
        except xmlrpclib.Fault, e:
            print "Could not Remove Users:", e
            return False
        return True

    def removesystems(self, profiles, group_name):
        try:
            system_id = self.get_system_id(profiles)
            self.call("systemgroup.addOrRemoveSystems",
                      group_name, system_id, False)
        except xmlrpclib.Fault, e:
            print "Could not add systems  : ", e
            return False
        return True

    def applyerratanow(self, group_name, errata_id):
        try:
            errata_list = self.get_errata_list(errata_id)
            print errata_list
            self.call("systemgroup.scheduleApplyErrataToActive",
                      group_name, errata_list)
        except xmlrpclib.Fault, e:
            print "Could not apply errata : ", e
            return False
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = SysGroups(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
