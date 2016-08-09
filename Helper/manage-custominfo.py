#!/usr/bin/python
# -*- coding: UTF-8 -*-
# author: Pavel Studeník <pstudeni@redhat.com>
# year: 2016

# Examples:
# manage-custominfo.py admin nimda https://`hostname`/rpc/api CREATE_KEY keyLabel keyDescr
# manage-custominfo.py admin nimda https://`hostname`/rpc/api DELETE_KEY keyLabel
# manage-custominfo.py admin nimda https://`hostname`/rpc/api LIST_ALL_KEYS
# manage-custominfo.py admin nimda https://`hostname`/rpc/api UPDATE_KEY
# keyLabel keyDescr

from __future__ import print_function

import sys
from spacewalk_api import Spacewalk


class CustomInfo(Spacewalk):
    """
    Provides methods to access and modify custom system information.

    Namespace: system.custominfo
    """

    def create_key(self, *argv):
        return self.call("system.custominfo.createKey", *argv)

    def delete_key(self, *argv):
        return self.call("system.custominfo.deleteKey", *argv)

    def update_key(self, *argv):
        return self.call("system.custominfo.updateKey", *argv)

    def list_all_keys(self, *argv):
        for item in self.call("system.custominfo.listAllKeys", *argv):
            print("\t".join([str(item) for item in item.values()]))
        return 1

    def run(self):
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = CustomInfo(*sys.argv[1:])
    sys.exit(main.run() - 1)
