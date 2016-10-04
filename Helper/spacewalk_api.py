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


class Spacewalk:

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

        if os.environ.get("DEBUG"):
            logging.basicConfig(level=logging.DEBUG)

        if not username and not password:
            # anonymous authorization
            return
        self.key = self.client.auth.login(username, password)

    def call(self, method, *args):
        conv_params = []
        method_all = False

        m = ".".join(method.split(".")[:-1])
        methods = self.client.api.getApiNamespaceCallList(self.key, m)

        for key, it in methods.items():
            if key.startswith(method):
                method_all = key
                params = it["parameters"][1:]
                logging.debug("# %s %s" % (method, params))
                if len(args) == len(params):
                    break
        if not method_all:
            print("All methods: ", [it[0] for it in methods.items()])
            raise Exception("method %s doesn't exist" % method)
            return

        for value, convert in zip(args, params):
            logging.debug("# \t %s -> %s" % (value, convert))
            if convert == "int":
                value = int(value)
            conv_params.append(value)

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
        return 1

if __name__ == "__main__":
    s = Spacewalk(sys.argv[1], sys.argv[2], sys.argv[3])
    s.call(*sys.argv[4:])
    s.stdOut()
