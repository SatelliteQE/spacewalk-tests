#!/usr/bin/python
# -*- coding: UTF-8 -*-

# author: Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples:
# manage-sync-slave.py admin nimda https://`hostname`/rpc/api CREATE <slave-fqdn> 1 1
# manage-sync-slave.py admin nimda https://`hostname`/rpc/api DELETE 13
# manage-sync-slave.py admin nimda https://`hostname`/rpc/api GET_SLAVE 13

import sys
from spacewalk_api import Spacewalk


class SyncSlave(Spacewalk):
    """Contains methods to set up information about known-"masters",
    for use on the "slave" side of ISS

    Namespace: sync.master
    """

    def create(self, slave, enabled, allow_orgs):
        """
        Args:
            slave (string): Slave's fully-qualified domain name
            enabled (boolean): Let this slave talk to us?
            allow_orgs (boolean): Export all our orgs to this slave?
        """
        enabled = True if enabled == 1 else False
        allow_orgs = True if allow_orgs == 1 else False
        slave = self.call("sync.slave.create", slave, enabled, allow_orgs)
        print slave['id']
        return True

    def get_slave(self, slave_id):
        return self.call("sync.slave.getSlave", int(slave_id))

    def delete(self, slave_id):
        return self.call("sync.slave.delete", int(slave_id))

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    main = SyncSlave(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
