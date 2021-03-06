#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Dimitar Yordanov <dyordano@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples:
# manage-proxy.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# IS_PROXY    # Returns O if the host is Proxy
# manage-proxy.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# ACTIVATE_PROXY 5.4
# manage-proxy.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# DEACTIVATE_PROXY
# manage-proxy.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# CREATE_MONITORING_SCOUT
# manage-proxy.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api
# LIST_AVAILABLE_PROXY_CHANNELS

import sys
import xmlrpclib
from spacewalk_api import Spacewalk


class Proxy(Spacewalk):
    """Provides methods to activate/deactivate a proxy server.

    Namespace: proxy
    """

    def activate_proxy(self, proxy_version):
        try:
            print self.call("proxy.activateProxy", SYSTEM_ID_FILE,
                            proxy_version)
        except xmlrpclib.Fault, e:
            print "Proxy Activation Failed:", e
            return 3
        return True

    def create_monitoring_scout(self):
        try:
            print self.call("proxy.createMonitoringScout", SYSTEM_ID_FILE)
        except xmlrpclib.Fault, e:
            print "FAILED to crate monitoring Scout: ", e
            return 3
        return True

    def deactivate_proxy(self):
        try:
            self.call("proxy.deactivateProxy", SYSTEM_ID_FILE)
        except xmlrpclib.Fault, e:
            print "FAILED to deactivate Proxy: ", e
            return 3
        return True

    def is_proxy(self):
        try:
            if not self.call("proxy.isProxy", SYSTEM_ID_FILE):
                return False
        except xmlrpclib.Fault, e:
            print "FAILED to check if the host is Proxy: ", e
            return 3
        return True

    def list_available_proxy_channels(self):
        try:
            print self.call("proxy.listAvailableProxyChannels", SYSTEM_ID_FILE)
        except xmlrpclib.Fault, e:
            print "FAILED to List available Proxy Channels: ", e
            return 3
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    try:
        main = Proxy(*sys.argv[1:])
    except xmlrpclib.Fault, e:
        print e
        sys.exit(2)

    SYSTEM_ID_FILE = open("/etc/sysconfig/rhn/systemid", 'r').read()
    sys.exit(main.run() - 1)
