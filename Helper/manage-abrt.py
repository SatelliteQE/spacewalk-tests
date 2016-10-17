#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Dimitar Yordanov <dyordano@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016


# manage-abrt.py admin nimda $(hostname) listSystemCrashes ${serverId} 'id'
# manage-abrt.py admin nimda $(hostname) listSystemCrashes ${serverId} # print all

# manage-abrt.py admin nimda $(hostname) listSystemCrashFiles ${crashId}
# manage-abrt.py admin nimda $(hostname) listSystemCrashFiles ${crashId} False 'id'
# manage-abrt.py admin nimda $(hostname) listSystemCrashFiles ${crashId} True #only_uploaded_files

# manage-abrt.py admin nimda $(hostname) getCrashFile ${crashFileId}
# manage-abrt.py admin nimda $(hostname) getCrashFileUrl ${crashFileId}

# manage-abrt.py admin nimda $(hostname) getCrashCountInfo ${serverId} 'total_count'
# manage-abrt.py admin nimda $(hostname) getCrashCountInfo ${serverId} 'unique_count'
# manage-abrt.py admin nimda $(hostname) getCrashCountInfo ${serverId} 'last_report'

# manage-abrt.py admin nimda $(hostname) getCrashFileSizeLimit ${orgId}
# manage-abrt.py admin nimda $(hostname) setCrashFileSizeLimit ${orgId} 1

# manage-abrt.py admin nimda $(hostname) deleteCrash ${crashId}

# manage-abrt.py admin nimda $(hostname) isCrashfileUploadEnabled ${orgId}
# manage-abrt.py admin nimda $(hostname) isCrashReportingEnabled  ${orgId}

# manage-abrt.py admin nimda $(hostname) setCrashfileUpload ${orgId} ${bool}
# manage-abrt.py admin nimda $(hostname) setCrashReporting  ${orgId} ${bool}

# manage-abrt.py admin nimda $(hostname) createCrashNote ${crashId} ${note_sunject} ${note_details}
# manage-abrt.py admin nimda $(hostname) deleteCrashNote ${noteId}
# manage-abrt.py admin nimda $(hostname) getCrashNotesForCrash ${crashId} 'id'

# manage-abrt.py admin nimda $(hostname) getCrashOverview 'uuid'
# manage-abrt.py admin nimda $(hostname) getCrashOverview # print all

# manage-abrt.py admin nimda $(hostname) getCrashesByUuid ${uuid}


import sys
from spacewalk_api import Spacewalk


class Abrt(Spacewalk):
    """docstring for Abrt"""

    def getCrashesByUuid(self, uuid, param_key=None):
        """
        @summary: 'getCrashesByUuid' Create a crash note.
        """
        res = self.call("system.crash.getCrashesByUuid", uuid)
        if param_key:
            for i in range(len(res)):
                print res[i][param_key]
        else:
            print res
        return True

    def getCrashOverview(self, param_key=None):
        """
        @summary: 'getCrashOverview'
        """
        res = self.call("system.crash.getCrashOverview")
        if param_key:
            for i in range(len(res)):
                print res[i][param_key]
        else:
            print res
        return True

    def createCrashNote(self, crashId, note_subject, note_details):
        """
        @summary: 'createCrashNote' Create a crash note.
        @param crashId
        @param subject
        @param details
        """
        print self.call("system.crash.createCrashNote", int(crashId),
                        note_subject, note_details)
        return True

    def deleteCrashNote(self, noteId):
        """
        @summary: 'deleteCrashNote' Delete a crash note.
        @param crashNoteId

        """
        print self.call("system.crash.deleteCrashNote", int(noteId))
        return True

    def getCrashNotesForCrash(self, crashId, param_key=None):
        """
        @summary: 'getCrashNotesForCrash' List crash notes for crash.
        @param crashNoteId
        """

        res = self.call("system.crash.getCrashNotesForCrash",
                        int(crashId))
        if param_key:
            for i in range(len(res)):
                print res[i][param_key]
        else:
            print res
        return True

    def isCrashfileUploadEnabled(self, orgId):
        """
        @summary: 'isCrashfileUploadEnabled' Get the status of crash file upload settings for the given organization. Returns true if enabled, false otherwise.
        @param orgId
        """
        print self.call("org.isCrashfileUploadEnabled", int(orgId))
        return True

    def isCrashReportingEnabled(self, orgId):
        """
        @summary: 'isCrashReportingEnabled' Get the status of crash reporting settings for the given organization. Returns true if enabled, false otherwise.
        @param orgId
        """
        print self.call("org.isCrashReportingEnabled", int(orgId))
        return True

    def setCrashfileUpload(self, orgId, enable):
        """
        @summary: 'setCrashfileUpload' Set the status of crash file upload settings for the given organization. Modifying the settings is possible as long as crash reporting is enabled.
        @param orgId
        @boolean enable - Use true/false to enable/disable
        """
        print self.call("org.setCrashfileUpload", int(orgId), eval(enable))
        return True

    def setCrashReporting(self, orgId, enable):
        """
        @summary: 'setCrashReporting' Set the status of crash reporting settings for the given organization. Disabling crash reporting will automatically disable crash file upload.
        @param orgId
        @boolean enable - Use true/false to enable/disable
        """
        print self.call("org.setCrashReporting", int(orgId), eval(enable))
        return True

    def getCrashFileSizeLimit(self, orgId):
        """
        @summary: 'getCrashFileSizeLimit' action method. Get the organization wide crash file size limit. The limit value must i a non-negative number, zero means no limit.
        @param orgId
        """
        print self.call("org.getCrashFileSizeLimit", int(orgId))
        return True

    def setCrashFileSizeLimit(self, orgId, limit):
        """
        @summary: 'setCrashFileSizeLimit' action method. Set the organization wide crash file size limit. The limit value must be non-negative, zero means no limit.
        @param orgId
        @param limit
        """
        return self.call("org.setCrashFileSizeLimit", int(orgId), int(limit))

    def deleteCrash(self, crashId):
        """
        @summary: 'deleteCrash' action method. Delete a crash with given crash id.
        @param crashId
        """
        return self.call("system.crash.deleteCrash", int(crashId))

    def getCrashFile(self, crashFileId):
        """
        @summary: 'getCrashFile' action method. Download a crash file.
        @param crashFileId
        """
        print self.call("system.crash.getCrashFile", int(crashFileId))
        return True

    def getCrashFileUrl(self, crashFileId):
        """
        @summary: 'getCrashFileUrl' action method. Get a crash file download url.
        @param crashFileId
        """
        print self.call("system.crash.getCrashFileUrl", int(crashFileId))
        return True

    def getCrashCountInfo(self, serverId, param_key=None):
        """
        @summary: 'getCrashCountInfo' action method. Return crash count information.
        @param serverId
        """
        res = self.call("system.crash.getCrashCountInfo", int(serverId))
        if param_key:
            print res[param_key]
        else:
            print res
        return True

    def listSystemCrashFiles(self, crashId, only_uploaded_files=False,
                             param_key=None):
        """
        @summary: 'listSystemCrashFiles' action method. Return list of crash files for given crash id.
        @param crashId
        """
        res = self.call("system.crash.listSystemCrashFiles",
                        int(crashId))
        # If we were asked to, remove files which were not uploaded to server
        if only_uploaded_files:
            res2 = []
            for c in res:
                if c['is_uploaded'] is True:
                    res2.append(c)
            res = res2
        # Print all info or only that field which was requested
        if param_key:
            for i in range(len(res)):
                print res[i][param_key]
        else:
            print res
        return True

    def listSystemCrashes(self, serverId, param_key=None):
        """
        @summary: 'listSystemCrashes' action method. Return list of software crashes for a system.
        @param serverId
        """
        res = self.call("system.crash.listSystemCrashes", int(serverId))
        if param_key:
            for i in range(len(res)):
                print res[i][param_key]
        else:
            print res
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == '__main__':
    main = Abrt(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
