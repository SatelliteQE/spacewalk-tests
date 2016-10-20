#!/usr/bin/env python
# author: Pavel Studenik

import xmlrpclib
import sys
import os
import logging


class BeakerEnv:

    @staticmethod
    def testname():
        name = os.environ.get("TESTVERSION")
        return ('', name)[name != None]

    @staticmethod
    def recipeid():
        return os.environ.get("RECIPEID")

    @staticmethod
    def taskid():
        return os.environ.get("TESTID")


"""
# Example using this script and python classes

>> python spacewalk_api.py admin nimda http://elisha.brq.redhat.com/rpc/api "system.listActiveSystems"

# via Python
from spacewalk_api import Spacewalk

class Example(Spacewalk):
    def test1(self):
       for system in self.call("system.listActiveSystems"):
          print system
if __name__=="__main__":
    s=Example("admin", "pass", "localhost")
    s.test1()
"""

class Spacewalk:

    exitcode = 1
    @staticmethod
    def parse_bool(code_string):
        # Parse string like '1' to boolean like True
        if code_string in ('1', 'true', 'True', 'yes', 'Yes'):
            return True
        else:
            return False

    def __init__(self, username=None, password=None, hostname=None, *argv):

        if hostname.startswith("http://") or hostname.startswith("https://"):
            server_url = hostname
        else:
            server_url = "https://%s/rpc/api" % hostname
        self.client = xmlrpclib.Server(server_url, verbose=0)
        self.argv = argv

        self.log = logging
        if os.environ.get("DEBUG"):
            self.log.basicConfig(level=logging.DEBUG)
        if not username and not password:
            # anonymous authorization
            return
        self.key = self.client.auth.login(username, password)

    def call(self, method, *args):
        conv_params = []
        method_exist = False

        m = ".".join(method.split(".")[:-1])
        methods = self.client.api.getApiNamespaceCallList(self.key, m)

        if m != "taskomatic":
        # for taskomatic api call dosn't exist documentation
            param_args = []
            for key, it in methods.items():
                params = it["parameters"][1:]
                if method == "%s.%s" % (m, it["name"]) and len(args) == len(params):
                    method_exist = key
                    logging.debug("# %s %s" % (method, params))
                    param_args.append([args, params])
            if not method_exist:
                print("All methods: ", [it[0] for it in methods.items()])
                raise Exception("method %s doesn't exist" % method)
                return

            # FIXME choose first params of method
            # maybe more then one can exists
            args, params = param_args[0]
            for value, convert in zip(args, params):
                logging.debug("# \t %s -> %s" % (value, convert))
                if convert == "int":
                    if type(value) == str and value.isdigit():
                        value = int(value)
                conv_params.append(value)
        else:
            conv_params = args

        fce = getattr(self.client, method)
        self.output = fce(self.key, *conv_params)
        return self.output

    def stdOut(self):
        def _print(data):
            print("\t".join(["%s" % it[1] for it in data.items()]))

        if type(self.output) == list:
            for it in self.output:
                _print(it)
        else:
            _print(self.output)

    def getMethod(self):
        return self.argv[0].lower()

    def __del__(self):
        if hasattr(self, "key"):
            self.client.auth.logout(self.key)

    def test(self):
        print "client.api.getVersion(): %s" % self.client.api.getVersion()
        print "client.api.systemVersion(): %s" % self.client.api.systemVersion()
        return self.exitcode

if __name__ == "__main__":
    s = Spacewalk(sys.argv[1], sys.argv[2], sys.argv[3])
    s.call(*sys.argv[4:])
    s.stdOut()
