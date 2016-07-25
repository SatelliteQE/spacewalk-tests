#!/usr/bin/python
# -*- coding: UTF-8 -*-
#
# author: Pavel Studeník <pstudeni@redhat.com>
# year: 2016

# Examples:
# manage-search.py admin nimda https://$( hostname )/rpc/api
# PACKAGE_BY_NAME kernel

import sys
from spacewalk_api import Spacewalk


class Search(Spacewalk):

    def package_by_name(self, *argv):
        pkgs = self.call("packages.search.name", *argv)
        for pkg in pkgs:
            print pkg

    def package_by_name_and_description(self, *argv):
        pkgs = self.call("system.search.nameAndDescription", *argv)
        for pkg in pkgs:
            print pkg

    def package_by_name_and_summary(self, *argv):
        pkgs = self.call("packages.search.nameAndSummary", *argv)
        for pkg in pkgs:
            print pkg

    def package_advanced(self, *argv):
        pkgs = self.call("packages.search.advanced", *argv)
        for pkg in pkgs:
            print pkg

    def package_advanced_with_channel(self, string, addon):
        assert len(addon) > 0
        pkgs = self.all("packages.search.advancedwithchannel", string, addon)
        for pkg in pkgs:
            print pkg

    def run(self):
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])


if __name__ == "__main__":
    main = Events(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))


