#!/usr/bin/env python
# -*- coding: UTF-8 -*-

# author: Patrik Segedy <psegedy@redhat.com>
# year: 2016
#
# Synopsis:
#    manage-users.py username login xmlrpc_handler action [params]
#
# Possible actions:
#    ADD_PACKAGE, CLONE, LIST, LIST_ADVISORY, LIST_ADVISORY_BY_DATE,
#    LIST_ADVISORY_FOR_CHANNEL, LIST_FOR_CHANNEL, LIST_FOR_CHANNEL_BY_DATE
#    LIST_FOR_CHANNEL_DETAILED, LIST_ALL_CHANNELS_BY_DATE, LIST_PACKAGES,
#    DELETE, CREATE, APPLY, MODIFY, GETPKGID
#
# Examples:
#    manage-errata.py ${RHN_USER} ${RHN_PASS}
#    https://${RHN_SERVER}/rpc/api ADD_PACKAGE advisoryName packageId
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST_FOR_CHANNEL_BY_DATE ${CUSTOM_CHANNEL} 20071030  20071130
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST_FOR_CHANNEL_BY_DATE ${CUSTOM_CHANNEL} 20071030
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST_ALL_CHANNELS_BY_DATE 20071030  20071130
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST_ALL_CHANNELS_BY_DATE 20071030
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST_ADVISORY_BY_DATE 20071030 20071031 HBA-2007:0574
#    manage-errata.py  ${RHN_USER}  ${RHN_PASS}  https://${RHN_SERVER}/rpc/api LIST_FOR_CHANNEL ${CUSTOM_CHANNEL}
#    manage-errata.py ${RHN_USER} ${RHN_PASS} https://${RHN_SERVER}/rpc/api LIST 852
#    manage-errata.py ${RHN_USER} ${RHN_PASS}
#    https://${RHN_SERVER}/rpc/api LIST_ADVISORY CLA-2007:0574

import sys
import re
import xmlrpclib
import time
from datetime import datetime
from spacewalk_api import Spacewalk


class Errata(Spacewalk):
    """
    Class Errata provides methods to access and modify errata.

    Namespace: errata
    """
    def add_package(self, errata_name, pkgid):
        count = 0
        count = self.call("errata.addPackages", errata_name, [int(pkgid)])
        print count
        return True

    def clone(self, channel_from, channel_to):
        """
        Ars:
            channel_from -- channel to clone from
            channel_to -- channel to clone to
        """
        count = 0
        errata = self.call("channel.software.listErrata", channel_from)
        for e in errata:
            print "DEBUG: Cloning advisory '%s'" % e['advisory_name']
            cloned = self.call("errata.clone", channel_to,
                               [e['advisory_name'], ])
            count += len(cloned)
        if len(errata) != count:
            print "ERROR: not all errata were cloned"
            ret = 100
        else:
            ret = True
        print count
        return ret

    def list(self, errata_id=None):
        """
        Args:
            errata_id (int): ID of wanted erratum (optional)
        """
        if errata_id is not None:
            found = False
            for channel in self.call("channel.listAllChannels"):
                for errata in self.call("channel.software.listErrata",
                                        channel['label']):
                    if errata['id'] == int(errata_id):
                        found = True
                        print errata
            return found
        else:
            for channel in self.call("channel.listAllChannels"):
                print self.call("channel.software.listErrata",
                                channel['label'])
            return True

    def list_advisory(self, advisory_name):
        found = False
        for channel in self.call("channel.listAllChannels"):
            for errata in self.call("channel.software.listErrata",
                                    channel['label']):
                if errata['advisory'] == advisory_name:
                    found = True
                    print errata
        return found

    def list_advisory_by_date(self, start_date, end_date, advisory_name):
        start_date = datetime(*(time.strptime(start_date, "%Y%m%d")[0:6]))
        end_date = datetime(*(time.strptime(end_date, "%Y%m%d")[0:6]))
        found = False
        for channel in self.call("channel.listAllChannels"):
            for errata in self.call("channel.software.listErrata",
                                    channel['label'],
                                    xmlrpclib.DateTime(start_date.timetuple()),
                                    xmlrpclib.DateTime(end_date.timetuple())):
                if errata['advisory_name'] == advisory_name:
                    found = True
                    print errata
        return found

    def list_advisory_for_channel(self, channel):
        for errata in self.call("channel.software.listErrata", channel):
            print errata['id']
        return True

    def list_for_channel(self, name):
        for errata in self.call("channel.software.listErrata", name):
            print errata
        return True

    def list_for_channel_by_date(self, channel, start_date, end_date=None):
        start_date = datetime(*(time.strptime(start_date, "%Y%m%d")[0:6]))
        if end_date is None:
            print self.call("channel.software.listErrata", channel,
                            xmlrpclib.DateTime(start_date.timetuple()))
        else:
            end_date = datetime(*(time.strptime(end_date, "%Y%m%d")[0:6]))
            print self.call("channel.software.listErrata", channel,
                            xmlrpclib.DateTime(start_date.timetuple()),
                            xmlrpclib.DateTime(end_date.timetuple()))
        return True

    def list_all_channels_by_date(self, start_date, end_date=None):
        start_date = datetime(*(time.strptime(start_date, "%Y%m%d")[0:6]))
        for channel in self.call("channel.listAllChannels"):
            if end_date is None:
                res = self.call("channel.software.listErrata",
                                channel['label'],
                                xmlrpclib.DateTime(start_date.timetuple()))
            else:
                res = self.call("channel.software.listErrata",
                                channel['label'],
                                xmlrpclib.DateTime(start_date.timetuple()),
                                xmlrpclib.DateTime(end_date.timetuple()))
            if len(res) != 0:
                print res
                return True
            return False

    def list_for_channel_detailed(self, name):
        for errata in self.call("channel.software.listErrata", name):
            details = self.call("errata.getDetails", errata['advisory_name'])
            out = ""
            for k in sorted(details.keys()):
                out = out + \
                    "%s: %s|" % (k, unicode(details[k]).replace(
                        '\n', '').encode('ascii', 'xmlcharrefreplace'))
            print out
        return True

    def list_packages(self, advisory_name):
        for pkg in self.call("errata.listPackages", advisory_name):
            print pkg
        return True

    def delete(self, name):
        return self.call("errata.delete", name)

    def create(self, errata_name, pkgid, channel, errata_type='BA'):
        types = {'BA': 'Bug Fix Advisory',
                 'EA': 'Product Enhancement Advisory',
                 'SA': 'Security Advisory',
                 }
        me = {'synopsis': 'synopsis',
              'advisory_name': errata_name,
              'advisory_release': 1,
              'advisory_type': types[errata_type],
              'product': 'product',
              'topic': 'topic',
              'description': 'description',
              'references': 'references',
              'notes': 'notes',
              'solution': 'solution'}
        mb = ({'id': 123456, 'summary': 'bug 123456 summary'},)
        mk = ('keyword1', 'keyword2')
        # more packages might be provided, separated by ","
        mp = re.split(',', pkgid)
        mp_i = []
        for i in mp:
            mp_i.append(int(i))
        mc = (channel,)
        errata = self.call("errata.create", me, mb, mk, mp_i, True, mc)
        print errata
        print errata['id']
        return True

    def apply(self, system_id, errata_id):
        """
        Args:
            system_id: Target system ID
            errata_id: Errata ID you want to apply
        """
        print self.call("system.scheduleApplyErrata", int(system_id),
                        (int(errata_id),))
        return True

    def getpkgid(self, nvrea):
        """
        Args:
            nvrea: name, version, release, epoch, archLabel delimited by '|'
        """
        N, V, R, E, A = re.split('\|', nvrea)
        pkg = self.call("packages.findByNvrea", N, V, R, E, A)
        if len(pkg) == 0:
            return False
        else:
            print pkg[0]['id']
            return True

    def modify(self, name, detail, value):
        # Usage:
        # manage-errata admin admin https://fqdn/rpc/api MODIFY RHEA:2010:21-1
        # description "My new description"
        #
        # manage-errata admin admin https://fqdn/rpc/api MODIFY RHEA:2010:122-1
        # bugs "[{'id': 2323, 'string': nevis})]"
        # And that is truly obfuscated :)
        self.call("errata.setDetails", name, {detail: value})
        print self.call("errata.getDetails", name)
        return True

    def run(self):
        """main function which run method"""
        method = self.getMethod()
        fce = getattr(self, method)
        return fce(*self.argv[1:])

if __name__ == '__main__':
    main = Errata(*sys.argv[1:])
    sys.exit(abs(main.run() - 1))
