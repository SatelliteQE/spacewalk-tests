#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: pnovotny
#          Dimitar Yordanov <dyordano@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Example usage:

# Create config channel
# manage-config.py admin admin hp-xw6400-01.rhts.eng.bos.redhat.com create_channel channelLabel=channel-label channelName=channel-name channelDescription=channel-description 

# Create/update config file
# $ manage-config.py admin admin https://`hostname`/rpc/api create_file configChannelLabel=channel-label path=/tmp/test-config.cfg contents=ABCDEFGH owner=root group=root permissions=644 selinux_ctx=root:object_r:unconfined_t macro-start-delimiter=\|\} macro-end-delimiter=\{\| 

# Crate/update config directory
# $ manage-config.py admin admin https://`hostname`/rpc/api create_dir configChannelLabel=channel-label path=/tmp/test-directory owner=root group=root permissions=644 selinux_ctx=root:object_r:unconfined_t

# Crate/update config symlink
# $ manage-config.py admin admin https://`hostname`/rpc/api create_symlink configChannelLabel=channel-label path=/tmp/test-symlink.cfg target_path=/tmp/test-config.cfg selinux_ctx=root:object_r:unconfined_t

# Get info
# $ manage-config.py admin admin https://`hostname`/rpc/api get_info channelLabel=channel-label path=/tmp/test-config.cfg

# Delete config file/dir/symlink
# $ manage-config.py admin admin https://`hostname`/rpc/api delete_file channelLabel=channel-label path=/tmp/test-config.cfg

# Delete config channel (including all it's content!)
# $ manage-config.py admin admin https://`hostname`/rpc/api delete_channel channelLabel=channel-label 

# Does config channel exists
# $ manage-config.py admin admin https://`hostname`/rpc/api channelExists channelLabel=test  

# List all Items in a Conf Channel
# $ manage-config.py admin admin https://`hostname`/rpc/api listFiles channelLabel=test

# Return a list of systems subscribed to a configuration channel 
# $ manage-config.py admin admin https://`hostname`/rpc/api listSubscribedSystems channelLabel=test

# Lists details on a list channels given their channel labels.
# $manage-config.py admin admin https://`hostname`/rpc/api lookupChannelInfo channelLabel=test

# Given a list of paths and a channel, returns details about the latest revisions of the paths. 
# manage-config.py admin admin https://`hostname`/rpc/api lookupFileInfo channelLabel=test path=/tmp/test

# Update a global config channel.
# manage-config.py admin admin https://`hostname`/rpc/api update channelLabel=test channelName=test_updated  description=test_update


import sys
from spacewalk_api import Spacewalk


class Config(Spacewalk):
    """class Config for handling configuration channels & files via API"""

    def create_channel(self, kwargs):
        """
        @summary: 'create_channel' action method. Create new configuration channel.
        @param channelLabel
        @param channelName
        @param channelDescription
        """
        self.call("configchannel.create", kwargs['channelLabel'],
                  kwargs['channelName'], kwargs['channelDescription'])
        return True

    def create_file(self, kwargs):
        """
        @summary: 'create_file' action method. Create or update config file.
        @param configChannelLabel
        @param path
        @param contents
        @param owner
        @param group
        @param permissions
        @param selinux_ctx
        @param macro-start-delimiter
        @param macro-end-delimiter
        @param revision
        @see: create_or_update_path()
        """
        path_info = {}
        for key in [
                'contents', 'owner', 'group', 'permissions', 'selinux_ctx', 'macro-start-delimiter',
                'macro-end-delimiter', 'revision', 'contents_enc64']:
            if key in kwargs:
                if key == 'contents_enc64':
                    if kwargs[key] == 'true':
                        path_info[key] = True
                    else:
                        path_info[key] = False
                else:
                    path_info[key] = kwargs[key]

        self.create_or_update_path(
            kwargs['configChannelLabel'], kwargs['path'], False, path_info)
        return True

    def create_dir(self, kwargs):
        """
        @summary: 'create_dir' action method. Create or update config directory.
        @param configChannelLabel
        @param path
        @param owner
        @param group
        @param permissions
        @param selinux_ctx
        @param revision
        @see: create_or_update_path()
        """
        path_info = {}
        for key in ['owner', 'group', 'permissions', 'selinux_ctx', 'revision']:
            if key in kwargs:
                path_info[key] = kwargs[key]

        self.create_or_update_path(
            kwargs['configChannelLabel'], kwargs['path'], True, path_info)

    def create_symlink(self, kwargs):
        """
        @summary: 'create_symlink' action method. Create or update config symlink.
        @param configChannelLabel
        @param path
        @param target_path
        @param selinux_ctx
        @param revision
        @see: create_or_update_symlink()
        """
        path_info = {}
        for key in ['target_path', 'selinux_ctx', 'revision']:
            if key in kwargs:
                path_info[key] = kwargs[key]

        self.create_or_update_symlink(
            kwargs['configChannelLabel'], kwargs['path'], path_info)

    def delete_channel(self, kwargs):
        """
        @summary: 'delete_channel' action method. Delete configuration channel.
        @param channelLabel
        """
        return self.call("configchannel.deleteChannels",
                         [kwargs['channelLabel']])

    def delete_file(self, kwargs):
        """
        @summary: 'delete_file' action method. Delete configuration file/directory/symlink.
        @param channelLabel
        @param path
        """
        return self.call("configchannel.deleteFiles",
                         kwargs['channelLabel'], [kwargs['path']])

    def get_info(self, kwargs):
        """
        @summary: 'get_info' action method. Return information about configuration file/directory/symlink.
        @param channelLabel
        @param path
        """
        info_list = self.call("configchannel.lookupFileInfo",
                              kwargs['channelLabel'], [kwargs['path']])
        try:
            info = info_list.pop()
            for key, value in info.items():
                print("%s: %s" % (key, value))
        except IndexError:
            self.error("Error: Given path `%s` does not exist!" %
                       kwargs['path'])
        return True

    def channelexists(self, kwargs):
        """
        @summary: channelExists action method. Checks if config channel exists.
        @param channelLabel

        """
        print self.call("configchannel.channelExists", kwargs['channelLabel'])
        return True

    def deployallsystems(self, kwargs):
        """
        @summary: 'deployAllSystems' action method. Schedule a configuration deployment for all systems subscribed to a particular configuration channel. .
        @param channelLabel
        """
        print self.call("configchannel.deployAllSystems",
                        kwargs['channelLabel'])
        return True

    def listglobals(self, kwargs):

        chann_info = self.call("configchannel.listGlobals")
        for i in range(len(chann_info)):
            print "%s | %s | %s | %s | %s " % (chann_info[i]['id'],
                                               chann_info[i]['orgId'],
                                               chann_info[i]['name'],
                                               chann_info[i]['label'],
                                               chann_info[i]['description'])
        return True

    def listfiles(self, kwargs):
        """
        @summary: 'listFiles' action method. Return a list of files in a channel.
        @param channelLabel
        """
        file_list = self.call("configchannel.listFiles",
                              kwargs['channelLabel'])
        for i in range(len(file_list)):
            print "%s | %s | %s " % (file_list[i]['type'],
                                     file_list[i]['path'],
                                     file_list[i]['last_modified'])
        return True

    def listsubscribedsystems(self, kwargs):
        """
        @summary: 'listSubscribedSystems' action method. Return a list of systems subscribed to a configuration channel.
        @param string channelLabel

        """
        system_list = self.call("configchannel.listSubscribedSystems",
                                kwargs['channelLabel'])
        for i in range(len(system_list)):
            print "%s | %s " % (system_list[i]['name'], system_list[i]['id'])
        return True

    def lookupchannelinfo(self, kwargs):
        """
        @summary: 'lookupChannelInfo' action method. Lists details on a list channels given their channel labels.
        @param string channelLabel

        """
        chann_info = self.call("configchannel.lookupChannelInfo",
                               [kwargs['channelLabel']])
        for i in range(len(chann_info)):
            print "%s | %s | %s | %s " % (chann_info[i]['id'],
                                          chann_info[i]['orgId'],
                                          chann_info[i]['name'],
                                          chann_info[i]['label'])
        return True

    def lookupfileinfo(self, kwargs):
        """
        @summary: 'lookupFileInfo' action method. Given a list of paths and a channel, returns details about the latest revisions of the paths.
        @param string channelLabel
        @param string string sessionKey
        @param array string - List of paths to examine

        """
        file_info = self.call("configchannel.lookupFileInfo",
                              kwargs['channelLabel'], [kwargs['path']])
        for i in range(len(file_info)):
            print " %s | %s | %s | %s | %s " % (file_info[i]['type'],
                                                file_info[i]['path'],
                                                file_info[i]['owner'],
                                                file_info[i]['group'],
                                                file_info[i]['permissions'])
        return True

    def update(self, kwargs):
        """
        @summary: 'update' action method. Update a global config channel.
        @param string sessionKey
        @param string channelLabel
        @param string channelName
        @param string description

        """
        chann_info = self.call("configchannel.update", kwargs['channelLabel'],
                               kwargs['channelName'], kwargs['description'])
        print "%s | %s | %s | %s | %s " % (chann_info['id'],
                                           chann_info['orgId'],
                                           chann_info['name'],
                                           chann_info['label'],
                                           chann_info['description'])
        return True

    def listglobals(self, kwargs):
        """
        @summary: 'listGlobals' action method. List all the global config channels accessible to the user.
        """
        for ch in self.call("configchannel.listGlobals"):
            print ch
        return True

    def create_or_update_path(self, configChannelLabel, path, isDir, path_info):
        """ Call API function configchannel.createOrUpdatePath() with given parameters. """
        return self.call("configchannel.createOrUpdatePath",
                         configChannelLabel, path, isDir, path_info)

    def create_or_update_symlink(self, configChannelLabel, path, path_info):
        """ Call API function configchannel.createOrUpdateSymlink() with given parameters. """
        return self.call("configchannel.createOrUpdateSymlink",
                         configChannelLabel, path, path_info)

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        kwargs = {}
        for arg in self.argv[1:]:
            (param, value) = arg.split('=')
            kwargs[param] = value
        return fce(kwargs)

if __name__ == '__main__':
    main = Config(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
