#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Matej Kollar <mkollar@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Examples
# manage-scap.py ${RHN_SERVER} ${RHN_USER} ${RHN_PASS} list $SYSTEM_ID
# manage-scap.py ${RHN_SERVER} ${RHN_USER} ${RHN_PASS} schedule $SYSTEM_ID
# /tmp/test_xccdf.xml
# manage-scap.py ${RHN_SERVER} ${RHN_USER}
# ${RHN_PASS} ruleresults  $xid

# manage-scap.py ${RHN_SERVER}${RHN_USER} ${RHN_PASS} details $xid
# manage-scap.py ${RHN_SERVER}${RHN_USER}
# ${RHN_PASS} details $xid xid

# manage-scap.py ${RHN_SERVER} ${RHN_USER} ${RHN_PASS}
# setPolicyForScapResultDeletion 0 1
# manage-scap.py ${RHN_SERVER} ${RHN_USER}
# ${RHN_PASS} setPolicyForScapResultDeletion 1 1 10

# manage-scap.py ${RHN_SERVER}${RHN_USER} ${RHN_PASS}
# setPolicyForScapFileUpload 0 1
# manage-scap.py ${RHN_SERVER}${RHN_USER}
# ${RHN_PASS} setPolicyForScapFileUpload 1 1 100

# manage-scap.py ${RHN_SERVER}${RHN_USER} ${RHN_PASS}
# getPolicyForScapResultDeletion 1 "enabled retention_period"
# manage-scap.py ${RHN_SERVER} ${RHN_USER} ${RHN_PASS}
# getPolicyForScapFileUpload 1 "size_limit enabled"

# manage-scap.py ${RHN_SERVER}${RHN_USER}
# ${RHN_PASS} deleteXccdfScan $xid

import sys
from spacewalk_api import Spacewalk
import pprint

myPPrint = pprint.PrettyPrinter(indent=4).pprint


class Scap(Spacewalk):
    """Namespace: system.scap

    Provides methods to schedule SCAP scans and access the results.
    """

    def list(self, server_ids):
        if server_ids == []:
            raise Exception("at least one serverId is needed for list")
        map(lambda x: myPPrint(
            self.call(".system.scap.listXccdfScans", int(x))), server_ids)
        return True

    def details(self, xids, keys=""):
        if xids == []:
            raise Exception("at least one xid is needed for details")
        if len(keys) == 0:
            map(lambda x: myPPrint(
                self.call("system.scap.getXccdfScanDetails", int(x))), xids)
        else:
            for xid in xids:
                res = self.call("system.scap.getXccdfScanDetails", xid)
                for k in keys:
                    print "%s:%s" % (k, res[k])
        return True

    def ruleresults(self, xids):
        if xids == []:
            raise Exception("at least one xid is needed for ruleresults")
        map(lambda x: myPPrint(
            self.call("system.scap.getXccdfScanRuleResults", int(x))), xids)
        return True

    def schedule(self, server_ids, path, args):
        if server_ids == []:
            raise Exception("at least one serverId is needed for schedule")
        if len(path) < 1:
            raise Exception("path is needed for schedule")
        # we are not really implementing all possibilities for
        # 4 versions of scheduleXccdfScan
        # scheduleXccdfScan :: key, {[serverId],serverId}, path, params, {,date} -> ...
        # we implement only
        # scheduleXccdfScan :: key, [serverId], path, params -> ...
        # Maybe some day in future?
        myPPrint(self.call("system.scap.scheduleXccdfScan",
                           server_ids, path, " ".join(args)))
        return True

    def setPolicyForScapResultDeletion(self, flag, org_id,
                                       retention_period=-1):
        if retention_period == -1:
            self.call("org.setPolicyForScapResultDeletion",
                      org_id, {"enabled": flag})
        else:
            self.call("org.setPolicyForScapResultDeletion", org_id,
                      {"enabled": flag, "retention_period": retention_period})
        return True

    def setPolicyForScapFileUpload(self, flag, org_id, size_limit=-1):
        if size_limit == -1:
            self.call("org.setPolicyForScapFileUpload",
                      org_id, {"enabled": flag})
        else:
            self.call("org.setPolicyForScapFileUpload",
                      org_id, {"enabled": flag, "size_limit": size_limit})
        return True

    def getPolicyForScapResultDeletion(self, org_id, keys):
        res = self.call("org.getPolicyForScapResultDeletion", org_id)
        keys = keys.strip().split()
        for k in keys:
            print "%s:%s" % (k, res[k])
        return True

    def getPolicyForScapFileUpload(self, org_id, keys):
        res = self.call("org.getPolicyForScapFileUpload", org_id)
        keys = keys.strip().split()
        for k in keys:
            print "%s:%s" % (k, res[k])
        return True

    def deleteXccdfScan(self, xids):
        for xid in xids:
            print self.call("system.scap.deleteXccdfScan", xid)
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == "__main__":
    main = Scap(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
