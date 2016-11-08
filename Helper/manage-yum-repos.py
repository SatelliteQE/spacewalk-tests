#!/usr/bin/python
# -*- coding: UTF-8 -*-

# authors: Pavel Novotny
#          Dimitar Yordanov <dyordano@redhat.com>
#          Patrik Segedy <psegedy@redhat.com>
# year: 2016

# Example usage:

# Create Repository
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} createRepo RepoName=${YUM_REPO} channelName=${CUSTOM_CHANNEL} RepoType='YUM'  RepoUrl=${YUM_REPO_URL}_TEST_UPDATE

# Update Repository Url
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} updateRepoUrl RepoName=${YUM_REPO} RepoUrl=${YUM_REPO_URL}

# Get reposiptry details
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} getRepoDetails RepoName=${YUM_REPO}

# List all repositories available for the user.
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} listUserRepos

# Associate repository to custom channel.
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} associateRepo   ChannelName=${CUSTOM_CHANNEL} RepoName=${YUM_REPO}

# Schedule repo syn
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} scheduleSyncRepo ChannelName=${CUSTOM_CHANNEL}  scheduleTime='0 19 19 ? * 7'

# Unshcedule repo syn
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} scheduleSyncRepo ChannelName=${CUSTOM_CHANNEL}  scheduleTime=''

# Sync Repository Now
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} SyncRepoNow ChannelName=${CUSTOM_CHANNEL}  

# Get Repo Sync Cron Expression
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} getRepoSyncCronExpression ChannelName=${CUSTOM_CHANNEL}

# List Channel Repos
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} listChannelRepos ChannelName=${CUSTOM_CHANNEL}

# List all packages in a channel
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} listAllPackages ChannelName=${CUSTOM_CHANNEL}

# Disassociate Reposiory from a custom channnel
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} disassociateRepo ChannelName=${CUSTOM_CHANNEL} RepoName=${YUM_REPO}

# Remove Repository from Satellite
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} removeRepo ChannelName=${CUSTOM_CHANNEL}  RepoName=${YUM_REPO}


# Adds a filter for a given repo
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} addRepoFilter  filter_type=+ filter_str=package_name repo_label=${YUM_REPO}
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} addRepoFilter  filter_type=- filter_str=package_name repo_label=${YUM_REPO}

# Removes a filter for a given repo
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} removeRepoFilter  filter_type=+  filter_str=package_name repo_label=${YUM_REPO}
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} removeRepoFilter  filter_type=- filter_str=package_name repo_label=${YUM_REPO}

# Lists the filters for a repo
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} listRepoFilters   repo_label=${YUM_REPO}

# Removes the filters for a repo
# manage-yum-repos.py ${RHN_USER} ${RHN_PASS} ${RHN_SERVER} clearRepoFilters  repo_label=${YUM_REPO}


import sys
from spacewalk_api import Spacewalk


class YumRepos(Spacewalk):
    """Class for handling Sync Yum repository via API"""

    def addrepofilter(self, kwargs):
        """
        @summary: 'addRepoFilter'
        """
        print self.call("channel.software.addRepoFilter", kwargs['repo_label'],
                        {'filter': kwargs['filter_str'],
                         'flag': kwargs['filter_type']})
        return True

    def removerepofilter(self, kwargs):
        """
        @summary: 'removeRepoFilter'
        """
        print self.call("channel.software.removeRepoFilter",
                        kwargs['repo_label'], {'filter': kwargs['filter_str'],
                                               'flag': kwargs['filter_type']})
        return True

    def listrepofilters(self, kwargs):
        """
        @summary: 'listRepoFilter'
        """
        print self.call("channel.software.listRepoFilters",
                        kwargs['repo_label'])
        return True

    def clearrepofilters(self, kwargs):
        """
        @summary: 'clearRepoFilter'
        """
        print self.call("channel.software.clearRepoFilters",
                        kwargs['repo_label'])
        return True

    def createrepo(self, kwargs):
        """
        @summary: 'createRepo' action method. Create new repository.
        @param RepoName
        @param RepoType
        @param RepoUrl
        TODO: The returned value is not like in the Doc

        """
        print self.call("channel.software.createRepo", kwargs['RepoName'],
                        kwargs['RepoType'], kwargs['RepoUrl'])
        return True

    def updaterepourl(self, kwargs):
        """
        @summary: 'updateRepoUrl' action method. Create Update repository URL.
        @param RepoName
        @param RepoUrl
        """
        print self.call("channel.software.updateRepoUrl",
                        kwargs['RepoName'], kwargs['RepoUrl'])
        return True

    def getrepodetails(self, kwargs):
        """
        @summary: 'getRepoDetails' action method. Get repository details.
        @param RepoName
        """
        print self.call("channel.software.getRepoDetails", kwargs['RepoName'])
        return True

    def listuserrepos(self, kwargs):
        """
        @summary: 'listUserRepos' action method. List all repositories available for the user.
        """

        print self.call("channel.software.listUserRepos")
        return True

    def associaterepo(self, kwargs):
        """
        @summary: 'associateRepo' action method. Associate repository to custom channel.
        @param ChannelName
        @param RepoName
        """
        print self.call("channel.software.associateRepo",
                        kwargs['ChannelName'], kwargs['RepoName'])
        return True

    def schedulesyncrepo(self, kwargs):
        """
        @summary: 'scheduleSyncRepo' action method. Schedule repo sync.
        @param ChannelName
        @param scheduleTime
        """
        print self.call("channel.software.syncRepo", kwargs['ChannelName'],
                        kwargs['scheduleTime'])
        return True

    def syncreponow(self, kwargs):
        """
        @summary: 'SyncRepoNow' action method. Schedule repo sync.
        @param ChannelName
        """
        print self.call("channel.software.syncRepo", kwargs['ChannelName'])
        return True

    def getreposynccronexpression(self, kwargs):
        """
        @summary: 'getRepoSyncCronExpression' action method. Get Repo Sync Cron Expression.
        @param ChannelName
        """
        print self.call("channel.software.getRepoSyncCronExpression",
                        kwargs['ChannelName'])
        return True

    def listchannelrepos(self, kwargs):
        """
        @summary: 'listChannelRepos' action method. List Channel Repositories.
        @param ChannelName
        """
        print self.call("channel.software.listChannelRepos",
                        kwargs['ChannelName'])
        return True

    def listallpackages(self, kwargs):
        """
        @summary: 'listAllPackages' action method. List all packages in a channel.
        @param ChannelName
        """
        packages = self.call("channel.software.listAllPackages",
                             kwargs['ChannelName'])

        for package in packages:
            print package['name']
        return True

    def disassociaterepo(self, kwargs):
        """
        @summary: 'disassociateRepo' action method. Disassociate Reposiory from a custom channnel.
        @param ChannelName
        @param RepoName
        """
        print self.call("channel.software.disassociateRepo",
                        kwargs['ChannelName'], kwargs['RepoName'])
        return True

    def removerepo(self, kwargs):
        """
        @summary: 'removeRepo' action method. Remove Repository from Satellite.
        @param RepoName
        """
        print self.call("channel.software.removeRepo", kwargs['RepoName'])
        return True

    def run(self):
        """ main function which run method """
        method = self.getMethod()
        fce = getattr(self, method)
        kwargs = {}
        for arg in self.argv[1:]:
            (param, value) = arg.split('=')
            kwargs[param] = value
        return fce(kwargs)

if __name__ == "__main__":
    main = YumRepos(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
