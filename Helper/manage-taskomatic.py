#!/usr/bin/python
# -*- coding: UTF-8 -*-

# EXAMPLE:
#   manage-taskomatic.py admin admin https://`hostname`/rpc/api LIST_BUNCH
# OPERATION
#   LIST_BUNCH [name|templates|description]    -- list of bunches
#   LIST_ALL_SCHEDULE [id|data_map|cron_expr|active_from|bunch|job_label]     -- long list of all schedule
#   LIST_ACTIVE_SCHEDULE [id|data_map|cron_expr|active_from|bunch|job_label]   -- what will be scheduled from now
#   LIST_ACTIVE_SCHEDULE_BY_BUNCH bunch_name [id|data_map|cron_expr|active_from|bunch|job_label]   -- ^^
#   LIST_SCHEDULE_SAT_RUN ID_of_SCHEDULE [status|stdOutputPath|task|start_time|...]   -- you need ScheduleID here
#   STDOUT ID_of_log_from_RUN
#   STDERR ID_of_log_from_RUN
#   SCHEDULE_SINGLE_SAT_BUNCH_RUN   -- schedule smth immediately
#   REINITIALIZE_SCHEDULES -- reinitialize all schedules (that were moved because of timeshift)"


import sys
import re
from spacewalk_api import Spacewalk
try:
    from smqa_misc import read_system_id
except ImportError:
    # When we are using this utility directly from GIT on our workstation,
    # we do not have this and it should be enough if we fail only if we need
    # this functionality, so it should be safe to ignore
    print >> sys.stderr, "WARNING: Failed to import smqa_misc - assuming manual mode"


class Taskomatic(Spacewalk):
    """Provides methods to manage Taskomatic

    Namespace taskomatic
    """

    def reinitialize_schedules(self):
        print self.call("taskomatic.reinitializeAllSchedulesFromNow")
        return True

    def list_bunch(self, arg):
        # List all bunches available
        list = self.call("taskomatic.listSatBunches")
        if arg is None:
            for bunches in list:
                for field_name in bunches:
                    print "%s %s ;" % (field_name, bunches[field_name]),
                print
        else:
            if arg in ("templates", "name", "description"):
                for bunches in list:
                    print bunches[arg]
            else:
                self.log.error("!!!!!%s is not defined!!!!\nuse only templates , name , description" % arg)
                return 101
        return True

    def list_bunch_sat_run(self, bunch):
        for run in self.call("taskomatic.listBunchSatRuns"):
            print run
        return True

    def list_all_schedule(self, arg):
        ARGS_ENABLE = ("data_map", "active_till", "active_from", "bunch", "id", "job_label", "cron_expr")
        list = self.call("taskomatic.listAllSatSchedules")
        if arg is None:
            for item in list:
                print("\n")
                for field_name in item:
                    print "%s = %s;" % (field_name, item[field_name]),
        else:
            if arg in ARGS_ENABLE:
                for item in list:
                    print item[arg]
            else:
                self.log.error("!!!!!%s is not defined!!!!\nuse only data_map , active_till , active_from , bunch , id , job_label" % arg)
                return 101
        return True

    def list_active_schedule(self, arg=None):
        schedules = self.call("taskomatic.listActiveSatSchedules")
        ARGS_ENABLE = ("data_map", "cron_expr", "active_from", "bunch", "id", "job_label")
        if arg is None:
            for item in schedules:
                print("\n")
                for field_name in item:
                    print "%s = %s;" % (field_name, item[field_name]),
        else:
            if arg in ARGS_ENABLE:
                for item in schedules:
                    print item[arg]
            else:
                self.log.error("!!!!!%s is not defined!!!!\nuse only %s" % (arg, " ".ARGS_ENABLE))
                return 101
        return True

    def list_active_schedule_by_bunch(self, bunch, arg):
        if bunch is None:
            self.log.error("Error: Specify bunch name in parameter  !!!! ")
            self.log.error("try: ******** LIST_BUNCH name")
            return 101

        schedules = self.call("taskomatic.listActiveSatSchedulesByBunch", bunch)
        ARGS_ENABLE = ("data_map", "cron_expr", "active_from", "bunch", "id", "job_label")
        if arg is None:
            for item in schedules:
                print("\n")
                for field_name in item:
                    print "%s = %s;" % (field_name, item[field_name]),
        else:
            if arg in ARGS_ENABLE:
                for item in schedules:
                    print item[arg]
            else:
                self.log.error("!!!!!%s is not defined!!!!\nuse only data_map , cron_expr , active_from , bunch , id , job_label" % bunch)
                return 101
        return True

    def list_schedule_sat_run(self, run_id, arg):
        if run_id is None:
            self.log.error("Error: Specify some RUN ID in parameter  !!!! ")
            self.log.error("ID is from : ****** LIST_ACTIVE_SCHEDULE_BY_BUNCH <name_of_bunch> id")
            return 101

        list = self.call("taskomatic.listScheduleSatRuns", int(run_id))
        if arg is None:
            #     print list
            for item in list:
                print("\n")
                for field_name in item:
                    print "%s = %s;" % (field_name, item[field_name]),
        else:
            for item in list:
                print item[arg]
        return True

    def stdout(self, log_id):
        print self.call("taskomatic.getSatRunStdOutputLog", int(log_id), -1)
        return True

    def stderr(self, log_id):
        print self.call("taskomatic.getSatRunStdErrorLog", int(log_id), -1)
        return True

    def schedule_single_sat_bunch_run(self, *args):
        # Interpret param in a way based on a bunch name
        second_param = self.interpret_param(*args)
        # Finally run the API call
        log = self.call("taskomatic.scheduleSingleSatBunchRun",
                        args[0], second_param)
        # Print result (time)
        print log
        return True

    def schedule_sat_bunch_run(self, bunch, job_label, cron_expr, params):
        #  SECOND_PARAM = {'channel_id': '121'}
        #  SECOND_PARAM = {'list':'true'}
        # (String bunchName, String jobLabel, Date startTime, Date endTime,
        # String cronExpression, Map params)
        if params is None:
            self.log.error("error, use:")
            self.log.error("taskomatic.scheduleSatBunch(String bunchName, String jobLabel, Date startTime, Date endTime, String cronExpression, Map params)")
            self.log.error("cmd for date now=date +%Y%m%dT%H:%m:%S")
            self.log.error("currently supported syntax:")
            self.log.error("taskomatic.scheduleSatBunch(String bunchName, String jobLabel, String cronExpression, Map params)")
            return 101
        else:
            #    now = datetime.datetime.now()
            #    now=datetime.date
            #    difference1 = datetime.timedelta(minutes=1)
            #    difference2 = datetime.timedelta(weeks=2)
            #    value = time.time()
            #    value = time.localtime(value)
            #    value = time.strftime("%Y%m%dT%H:%M:%S", value)
            #    now1=value
            #    now2=value
            #    print now1
            #    maper=map'list','true'
            # Interpret param in a way based on a bunch name
            params = self.interpret_param(bunch, params)
            log = self.call("taskomatic.scheduleSatBunch",
                            bunch, job_label, cron_expr, params)
            print log
        return True

    def unschedule_sat_bunch_run(self, job_label):
        if job_label is None:
            self.log.error("error, use:")
            self.log.error("taskomatic.unscheduleSatBunch(String jobLabel)")
            return 101
        print self.call("taskomatic.unscheduleSatBunch", job_label)
        return True

    def interpret_param(self, bunch, param=None):
        # result = {'channel_id': '161'}
        # result = {'list':'true'}
        # result = {'cobbler':'sync'}
        # Interpret second param in a way based on a first one
        # (see examples above for different bunches)
        result = {}
        if bunch in ('repo-sync-bunch', 'channel-repodata-bunch'):
            result = {'channel_id': str(param)}
        if bunch in ('errata-cache-bunch'):
            if param is not None and re.match(r'^[0-9]{10}$',
                                              str(param), re.M):
                result = {'system_id': str(param)}
            if param == 'whoami':
                result = {'system_id': str(read_system_id())}
            elif param is not None and re.match(r'^[0-9]{1,}$',
                                                str(param), re.M):
                result = {'channel_id': str(param)}

        print "bunch:", bunch   # DEBUG
        print "result:", result   # DEBUG
        return result

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == '__main__':
    main = Taskomatic(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
