#!/usr/bin/python
# -*- coding: UTF-8 -*-

# author: Pavel Studeník <pstudeni@redhat.com>
# year: 2016

# Examples:
# manage-ak.py admin admin https://`hostname`/rpc/api CREATE my_channel True True
#   Prints new activation key created with this options:
#     * base channel is 'my_channel'
#     * entitlement is set to True meaning virtualization_host (False would be none), virtualization_host is the only entitlement in SW
#     * key will be universal default because last option is 'True'
# manage-ak.py ${SAT_USER} ${SAT_PASS} https://${RHN_PARENT_SERVER_TAG}/rpc/api ADD_CHILD_CHANNELS $CHILD_CHANN $ACTIVE_KEY
# manage-ak.py ${SAT_USER} ${SAT_PASS} https://${RHN_PARENT_SERVER_TAG}/rpc/api CREATE $BASE_CHANNEL True True
# manage-ak.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api CREATE_WITH_DEFAULT_CHANNEL False True

import sys
from spacewalk_api import Spacewalk
from spacewalk_api import BeakerEnv


class ActivationKey(Spacewalk):
    """
    Contains methods to access common activation key functions available from the web interface.
    """

    def check_channel_exists(self, label):
        # get list of all channels (in kinda compatible way)
        try:
            channels = self.call("channel.listAllChannels")
        except xmlrpclib.Fault, e:
            # On Hosted we do not have listAllChannels, so if we hit this
            # (and exactly this) exception, we should retry with listSoftwareChannels
            if str(e) == "<Fault -1: 'Could not find method listAllChannels in class class com.redhat.rhn.frontend.xmlrpc.channel.ChannelHandler'>":
                channels = self.call("channel.listSoftwareChannels")
            else:
                raise
        # check that given channel is among them
        for channel in channels:
            if channel["label"] == label:
                return True
        return False

    def create(self, channel, ent="0", default=False):
        """
        Create a new activation key. The activation key parameter passed in will be prefixed with the organization ID,
        and this value will be returned from the create call. Eg. If the caller passes in the key "foo" and belong to
        an organization with the ID 100, the actual activation key will be "100-foo". This call allows for the setting
        of a usage limit on this activation key. If unlimited usage is desired see the similarly named API method with
        no usage limit argument.
        """
        def entitlements(code):
            if code == "1":
                return ["virtualization_host", ]
            return []

        if self.check_channel_exists(label):
            raise Exception("Channel %s exists" % label)
            return 0
        descritption = BeakerEnv.testname()
        self.call("activationkey.create", '', descritption, channel,
                   entitlements(ent), Spacewalk.parse_bool(default))
        return 1

    def create_with_default_channel(self, ent="0", default=False):
        return self.create(label, "", ent, default=True)

    def list(self):
        """
        List activation keys that are visible to the user.
        """
        keys = self.call("activationkey.listActivationKeys")
        for ak in keys:
            print "%s|%s|%s|%s" % (ak['key'], ak['base_channel_label'], ak['entitlements'], ak['universal_default'])
        return 1
    
    def delete(self, activ_key):
        ret = self.call("activationkey.delete", activ_key)
        return ret

    def list_conf_chann(self, activ_key):
        keys = self.call("activationkey.listConfigChannels", activ_key)
        for channel in keys:
            print channel
        return 1

    def add_packages(self, activ_key, package, arch):
        data = [{'name': package, 'arch': arch}, ]
        return self.call("activationkey.addPackages", activ_key, data) 

    def add_conf_chann(self, activ_key, conf_channel, default):
        if not self.call("configchannel.channelExists", conf_channel):
            raise Exception("Config channel %s doesn't exist" % conf_channel)
            return 2
        else:
            default = Spacewalk.parse_bool(activ_key, default)
            self.call("activationkey.addConfigChannels", activ_key, conf_channel, default)
        return 1

    def del_conf_chann(self, activ_key, conf_channel):
        if not self.call("configchannel.channelExists", conf_channel):
            raise Exception("Config channel %s doesn't exist" % conf_channel)
            return 2
        ret = self.call("activationkey.removeConfigChannels", activ_key, conf_channel)
        return ret

    def add_child_channels(self, activ_key, conf_channel):
        if not self.call("configchannel.channelExists", conf_channel):
            raise Exception("Config channel %s doesn't exist" % conf_channel)
            return 2
        ret = self.call("activationkey.addChildChannels", activ_key, conf_channel)
        return ret

    def run(self):
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    main = ActivationKey(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))




