#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: <psklenar@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# REMOVE:
# manage-package.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api REMOVE
# psklenar-is-testing-me-first 1 1 '' noarch"

# GETDETAILS:
# manage-package.py admin admin https://ultraman-1.lab.eng.brq.redhat.com/rpc/api GETDETAILS 6783 name
# manage-package.py admin admin
# https://ultraman-1.lab.eng.brq.redhat.com/rpc/api GETDETAILS 6783 epoch

# REMOVEALL: - removes all by given name. (it's strict = complains about any error)
# manage-package.py $RHN_USER $RHN_PASS https://$RHN_SERVER/rpc/api
# REMOVEALL zsh

import sys
import xmlrpclib
import pprint
from spacewalk_api import Spacewalk


class Package(Spacewalk):
    """
    Class that provides methods to retrieve information about
    the Packages contained within this server.

    Namespace: packages
    """

    def remove(self, name, version, release, epoch, arch):
        to_delete = self.call("packages.findByNvrea", name, version, release,
                              epoch, arch)
        deleted_count = 0
        for pkg in to_delete:
            self.call("packages.removePackage", pkg['id'])
            deleted_count = deleted_count + 1
        if deleted_count == 0:
            return False
        return True

    def remove_pkgid(self, pkgid):
        return self.call("packages.removePackage", int(pkgid))

    def getdetails(self, pkgid, version):
        details = self.call("packages.getDetails", int(pkgid))
        # print details
        print "%s" % details[version]
        return True

    def getdetails_all(self, pkgid):
        details = self.call("packages.getDetails", int(pkgid))
        pprint.pprint(details)
        return True

    def get_files(self, pkgid):
        for file in self.call("packages.listFiles", int(pkgid)):
            print file
        return True

    def get_id(self, name, version, release, epoch, arch):
        pkg = self.call("packages.findByNvrea", name, version, release, epoch,
                        arch)
        assert len(pkg) == 1
        print pkg[0]['id']
        return True

    def search(self, name):
        pkg = self.call("packages.search.nameAndSummary", name)
        for p in range(len(pkg)):
            print pkg[p]['name'] + "; " + pkg[p]['summary']
        return True

    def removeall(self, name):
        print name
        to_delete = self.call("packages.search.name", name)
        if to_delete == []:
            print "None package found for deletion."
            return 101
        else:
            for pkg in to_delete:
                if pkg['name'] == name:
                    print "Deleting " + pkg['name'] + ": ",
                    try:
                        self.call("packages.removePackage", pkg['id'])
                        print "Success"
                    except xmlrpclib.Fault, e:
                        print "FAILURE"
                        print "  - " + str(e)
                        return False
        return True

    def list_pkgs_without_channel(self):
        for pkg in self.call("channel.software.listPackagesWithoutChannel"):
            print pkg
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    main = Package(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
