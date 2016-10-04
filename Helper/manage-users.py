#!/usr/bin/python
# -*- coding: UTF-8 -*-
#
# author: Patrik Segedy <psegedy@redhat.com>
# year: 2016
#
# Synopsis:
#    manage-users.py username login xmlrpc_handler action [params]
#
# Possible actions:
#    LIST, CREATE, ADD_ROLE, ADD_EXTERNAL_ROLE, ADD_EXTERNAL_SYSTEM_GROUP,
#    LIST_ROLES, GET_USER_ID, ENABLE, DISABLE, DELETE, LIST_LOCALE, SET_LOCALE,
#    LIST_TIMEZONE, SET_TIMEZONE
#
# Examples:
#    python manage-users.py $USER $PASS http://$(hostname)/rpc/api
#    ADD_EXTERNAL_SYSTEM_GROUP new_ext_group "system-group1;system-group2"
#
#    python manage-users.py $USER $PASS http://$(hostname)/rpc/api
#    ADD_EXTERNAL_ROLE new_ext_role "0011010"
#
#    python manage-users.py $USER $PASS http://$(hostname)/rpc/api
#    CREATE login password first_name last_name user@example.com 1
#

import sys
from spacewalk_api import Spacewalk


class Users(Spacewalk):
    """Users class contains methods to access common user functions available
    from the web user interface."""

    def list(self):
        for user in self.call("user.listUsers"):
            print user
        return True

    def create(self, login, *argv):
        self.call("user.create", login, *argv)
        # print user id
        for user in self.call("user.listUsers"):
            if user['login'] == login:
                print user['id']
                return True

    def add_role(self, login, roles_code):
        roles = create_role(roles_code)
        for role in roles:
            self.call("user.addRole", login, role)
        return True

    def add_external_role(self, name, roles_code):
        roles = create_role(roles_code)
        listext = self.call("user.external.listExternalGroupToRoleMaps")
        # if group role doesn't exist then create new
        if [it for it in listext if it["name"] == name]:
            self.call("user.external.setExternalGroupRoles", name, roles)
        else:
            self.call("user.external.createExternalGroupToRoleMap", name, roles)
        return True

    def add_external_system_group(self, name, groups):
        groups = groups.split(";")
        listext = self.call("user.external.listExternalGroupToSystemGroupMaps")
        # if group role doesn't exist then create new
        if [it for it in listext if it["name"] == name]:
            self.call("user.external.setExternalGroupSystemGroups", name, groups)
        else:
            self.call("user.external.createExternalGroupToSystemGroupMap",
                      name, groups)
        return True

    def list_roles(self, *argv):
        for role in self.call("user.listRoles", *argv):
            print role
        return True

    def get_user_id(self, *argv):
        for user in self.call("user.listUsers"):
            if user['login'] == argv[5]:
                print user['id']
                return True

    def enable(self, *argv):
        return self.call("user.enable", *argv)

    def disable(self, *argv):
        return self.call("user.disable", *argv)

    def delete(self, *argv):
        return self.call("user.delete", *argv)

    def list_locale(self):
        for locale in self.client.preferences.locale.listLocales():
            print locale
        return True

    def set_locale(self, *argv):
        return self.client.preferences.locale.setLocale(*argv)

    def list_timezone(self):
        for timezone in self.client.preferences.locale.listTimeZones():
            print int(timezone['time_zone_id']), timezone['olson_name']
        return True

    def set_timezone(self, *argv):
        return self.client.preferences.locale.setTimeZone(*argv)

    def run(self):
        """main function which run method"""
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


def create_role(ROLES):
    roles = []
    # we need to have addition of roles in alphabetic order
    # we expect such ordering in reporting-genereal/testcases/where.sh
    if ROLES[5] == '1':
        roles.append('activation_key_admin')
    if ROLES[2] == '1':
        roles.append('channel_admin')
    if ROLES[3] == '1':
        roles.append('config_admin')
    if ROLES[6] == '1':
        roles.append('monitoring_admin')
    if ROLES[1] == '1':
        roles.append('org_admin')
    if ROLES[0] == '1':
        roles.append('satellite_admin')
    if ROLES[4] == '1':
        roles.append('system_group_admin')
    return roles

if __name__ == '__main__':
    main = Users(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
