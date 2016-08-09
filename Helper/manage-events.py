#!/usr/bin/python
# -*- coding: UTF-8 -*-
#
# author: Pavel Studeník <pstudeni@redhat.com>
# year: 2016
#
# Synopsis:
#    manage-events.py username login xmlrpc_handler action ( system_id  | "whoami" ) [params]
#
# Possible actions:
#    GET_PENDING_COUNT [action_type]
#       - action_type represents type of action counted
#    GET_HISTORY_COUNT [action_type]
#    GET_HISTORY_COUNT_SUCCESSFUL [action_type]
#       - will filter out actions with failed_count >= successful_count
#


import sys
from spacewalk_api import Spacewalk

try:
    from smqa_misc import read_system_id
except ImportError:
    # When we are using this utility directly from GIT on our workstation,
    # we do not have this and it should be enough if we fail only if we need
    # this functionality, so it should be safe to ignore
    print >> sys.stderr, "WARNING: Failed to import smqa_misc - assuming manual mode"


class Events(Spacewalk):
    """
    Provides methods to count number of events for chosen system.

    Namespace: system
    """

    def list_system_events(self, *argv):
        for item in self.call("system.listSystemEvents", *argv):
            print(item)
        return 1

    def get_pending_count(self, systemid, *params):
        result = 0
        for event in self.call("system.listSystemEvents", systemid):
            if not 'completed_date' in event.keys():
                if len(params):
                    if event['action_type'] == params[0]:
                        result += 1
                else:
                    result += 1
        print result
        return 1

    def get_history_count(self, systemid, params=None, only_successful=False):
        result = 0
        for event in self.call("system.listSystemEvents", systemid):
            if 'completed_date' in event.keys():
                if only_successful \
                   and event['failed_count'] >= event['successful_count']:
                    continue
                if params:
                    if event['action_type'] == params:
                        result += 1
                else:
                    result += 1
        print result
        return 1

    def get_history_count_successful(self, *argv):
        return self.get_history_count(*argv, only_successful=True)

    def run(self):
        method = self.getMethod()
        fce = getattr(self, method)

        system_id = self.argv[1]
        if self.argv[1] == "whoami":
            system_id = read_system_id()

        return fce(system_id, *self.argv[2:])


if __name__ == "__main__":
    main = Events(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
