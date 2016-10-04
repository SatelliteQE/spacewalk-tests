#!/usr/bin/python
# -*- coding: UTF-8 -*-
# examples:
# manage-org.py admin admin https://`hostname`/rpc/api SET_ENTITLEMENT 96 ALL 10
# manage-org.py admin admin https://`hostname`/rpc/api LIST_SOFTWARE_ENTITLEMENTS
# manage-org.py admin admin https://`hostname`/rpc/api LIST_SOFTWARE_ENTITLEMENTS channel-label
# manage-org.py admin admin https://`hostname`/rpc/api
# LIST_SOFTWARE_ENTITLEMENTS channel-label GET attribute-name

# author: Pavel Studeník <pstudeni@redhat.com>
# year: 2016

from __future__ import print_function

import sys
from spacewalk_api import Spacewalk


class Organization(Spacewalk):

    def check_org_exists(self, org_id):
        # check if org exists
        # NOTE: This function can be used only by "satellite administrator"
        # because of API calls used
        list = self.call("org.listOrgs")
        try:
            org = int(org_id)   # if this worked, org was orgId
            k = 'id'
        except ValueError:
            k = 'name'   # if ValueError appeared, org was orgName
        for o in list:
            if o[k] == org_id:
                return True
        return False

    def test(self):
        print("client.api.getVersion(): %s" % self.client.api.getVersion())
        print("client.api.systemVersion(): %s" %
              self.client.api.systemVersion())

    def list(self):
        data = self.call("org.listOrgs")
        for org in data:
            users = self.call("org.listUsers", org['id'])
            admin = ''
            for user in users:
                if user['is_org_admin']:
                    admin = user['login']
                    break
            print("%s|%s|%s" % (org['id'], org['name'], admin))
        return True

    def create(self, org_id, org_admin, org_admin_pass, org_admin_email, org_admin_pam):
        if self.check_org_exists(org_id):
            raise(Exception("Organization exists"))
        if len(org_admin_pass) < 5:
            raise(Exception('Password have to be at least 5 chars long'))
        org_admin_pam = bool(int(org_admin_pam))
        org = self.call("org.create", org_id, org_admin, org_admin_pass,
                        'Mr.', 'firstName', 'lastName', org_admin_email, org_admin_pam)
        print(org)
        print(org['id'])
        return True

    def delete(self, org_id):
        ret = self.call("org.delete", int(org_id))
        return ret - 1

    def add_trust(self, org_id, org_admin):
        if self.check_org_exists(org_id) or \
                self.check_org_exists(org_admin):
            raise(Exception("Organization exists"))
        self.call("org.trusts.addTrust", int(org_id), int(org_admin))
        return True

    def del_trust(self, org, org_admin):
        if not self.check_org_exists(int(org)) or \
                check_org_exists(int(org_admin)):
            raise(Exception("Organization doesn't exist"))
        self.call("org.trusts.removetrust", int(org), int(org_admin))
        return True

    def list_trust(self, org):
        if not self.check_org_exists(int(org)):
            raise(Exception("Organization doesn't exist"))

        for org_data in self.call("org.trusts.listTrusts", int(org)):
            if org_data['trustEnabled']:
                print "%s trusts to %s (%s)" % (org, org_data['orgId'], org_data['orgName'])
        return True

    def details_trust(self, org):
        details = self.call("org.trusts.getDetails", int(org))
        print "created:", details["created"]
        print "trusted_since:", details["trusted_since"]
        print "channels_provided:", details["channels_provided"]
        print "channels_consumed:", details["channels_consumed"]
        print "systems_migrated_to:", details["systems_migrated_to"]
        print "systems_migrated_from:", details["systems_migrated_from"]
        return True

    def list_channels_consumed(self, org):
        channels = self.call("org.trusts.listChannelsConsumed", int(org))
        for ch in channels:
            print ch
        return 0

    def list_channels_provided(self, org):
        channels = client.org.trusts.listChannelsProvided(key, int(org))
        for ch in channels:
            print ch
        return 0

    def migrate_system(self, org, org_admin, org_to, system_id):
        system_id = int(org)
        org_to = int(org_admin)
        # returns array of servers migrated
        ret = self.call("org.migrateSystems"(org_to, (system_id,)))
        print ret
        return len(ret) - 1

    def get_mine_org_id(self, user):
        ret = self.call("user.getDetails"(user))
        print ret['org_id']
        return 0

    def get_org_info(self, org):
        for k, v in self.call("org.getdetails", int(org)).iteritems():
            print '%s: %s' % (k, v)
        return 0

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = Organization(*sys.argv[1:])
    sys.exit(main.run() - 1)
