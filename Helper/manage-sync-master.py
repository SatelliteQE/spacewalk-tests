#!/usr/bin/python
# -*- coding: UTF-8 -*-

# author: Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples:
# manage-sync-master.py admin nimda https://`hostname`/rpc/api CREATE <master-fqdn>
# manage-sync-master.py admin nimda https://`hostname`/rpc/api CREATE_OR_FIND <master-fqdn>
# manage-sync-master.py admin nimda https://`hostname`/rpc/api SET_CA_CERT 13 /path/to/the/cert
# manage-sync-master.py admin nimda https://`hostname`/rpc/api GET_MASTER 13
# manage-sync-master.py admin nimda https://`hostname`/rpc/api DELETE 13

import sys
import xmlrpclib
from spacewalk_api import Spacewalk


class SyncMaster(Spacewalk):
    """Contains methods to set up information about known-"masters",
    for use on the "slave" side of ISS

    Namespace: sync.master
    """

    def create(self, label):
        """
        Args:
            label: master hostname
        """
        master = self.call("sync.master.create", label)
        print master['id']
        return True

    def CREATE_OR_FIND(self, label):
        """
        Use this instead of 'CREATE' in case there might be such a master
        already and you are OK with that and you just want it's ID then

        Args:
            label: master hostname
        """
        try:
            master = self.call("sync.master.getMasterByLabel", label)
        except xmlrpclib.Fault, err:
            if err.faultString.find('Unable to locate or access ISS Master') != -1:
                master = self.call("sync.master.create", label)
            else:
                raise
        print master['id']
        return True

    def SET_CA_CERT(self, master_id, ca_file_path):
        return self.call("sync.master.setCaCert", int(master_id), ca_file_path)

    def GET_MASTER(self, master_id):
        return self.call("sync.master.getMaster", int(master_id))

    def DELETE(self, master_id):
        return self.call("sync.master.delete", master_id)

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    main = SyncMaster(*sys.argv[1:])
    sys.exit(main.run() - 1)
