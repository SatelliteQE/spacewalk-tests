#!/bin/bash

# Copyright (c) 2016 Red Hat, Inc. All rights reserved. This copyrighted material 
# is made available to anyone wishing to use, modify, copy, or
# redistribute it subject to the terms and conditions of the GNU General
# Public License v.2.
#
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Author: Jan Pazdziora

. /usr/bin/rhts-environment.sh
echo "rhts-env sourced, status = $?"

. /usr/share/beakerlib/beakerlib.sh
echo "beakerlib sourced, status = $?"


rlJournalStart


rlPhaseStartSetup "Initial PATH setup"

    export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"; rlLogInfo "PATH set to $PATH"
    # Source the our spacewalk library
    . /mnt/tests/CoreOS/Spacewalk/Helper/spacewalk-install.sh
    rlAssert0 "File 'spacewalk-install' sourced" $?

rlPhaseEnd


rlPhaseStartTest "Install PostgreSQL server 8.4 or 9.2"
	
	rlRun "$(helper-get-updater.sh) install -y 'postgresql-server > 8.4' > /tmp/spacewalk-install-postgresql-server.log"
	# on RHEL, it's called postgresql84-server, so we cannot rlAssertRpm easily
	rlRun "rpm -q --whatprovides postgresql-server" 0
	PSQL='psql'
	CREATELANG='createlang'
	CREATEUSER='createuser'
	CREATEDB='createdb'

	rlFileSubmit /tmp/spacewalk-install-postgresql-server.log

rlPhaseEnd


rlPhaseStartTest "Install PostgreSQL PL/Tcl extension"

	rlRun "$(helper-get-updater.sh) install -y 'postgresql-pltcl' > /tmp/spacewalk-install-postgresql-pltcl.log"

	rlFileSubmit /tmp/spacewalk-install-postgresql-pltcl.log

rlPhaseEnd


rlPhaseStartTest "Configure and start PostgreSQL server"

	PG_HBA_CONF='/var/lib/pgsql/data/pg_hba.conf'
	POSTGRESQL_CONF='/var/lib/pgsql/data/postgresql.conf'
	PG_VERSION='/var/lib/pgsql/data/PG_VERSION'
	SERVICE='postgresql'

	rlRun "chkconfig $SERVICE on" 0
	if [ -f $PG_VERSION ] ; then
		rlLogInfo "PostgreSQL seems already initialized"
	else
		if which postgresql-setup &>/dev/null; then
			rlLogInfo "New postgresql detected."
			rlRun "postgresql-setup initdb" 0
		else
			rlLogInfo "Using old initialization."
			rlRun "service $SERVICE initdb" 0
		fi
	fi
	rlRun "perl -i -pe 'if (/^# TYPE/) { open IN, q!pg_hba.conf!; \$_ .= join q!!, <IN>; }' '$PG_HBA_CONF'" 0 "Enable password authentication"

	# Increase max number of connections
	# https://fedorahosted.org/spacewalk/wiki/PostgreSQLServerSetup
	rlRun "sed -i 's/^\(max_connections.*\)$/###\1/' $POSTGRESQL_CONF"
	rlRun "echo 'max_connections = 600' >> $POSTGRESQL_CONF"
	# Problem here is that when setting only max_connections, you often
	# (depends on a systems HW) are not able to start PostgreSQL server
	# due to max_connections and shared_buffers configuration. I was
	# unable to use pgtune to calculate this properly because of
	# bug 918419.
	rlRun "sed -i 's/^\(shared_buffers.*\)$/###\1/' $POSTGRESQL_CONF"
	rlRun "echo 'shared_buffers = 256kB' >> $POSTGRESQL_CONF"
	# If we are on 9.2, we need "bytea_output = 'escape'" - see:
	echo $SERVICE | grep '92' \
		&& rlRun "echo \"bytea_output = 'escape'\" >> $POSTGRESQL_CONF"

	rlRun "service $SERVICE start" 0

rlPhaseEnd

rlPhaseStartTest "Wait for PostgreSQL server to start"

	# Wait for DB to come up
	wait_max=30
	wait_current=0
	wait_step=3
	while ! su - postgres -c "echo 'SELECT version();' | $PSQL"; do
		if [ $wait_current -ge $wait_max ]; then
			rlDie "DB did not came up in time"
		fi
		rlLogInfo "DB not ready, waiting"
		rlRun "sleep $wait_step"
		let wait_current+=1
	done
	rlRun "su - postgres -c \"echo 'SELECT version();' | $PSQL\""

rlPhaseEnd

rlPhaseStartTest "Create the spacewalk user"
	if su - postgres -c "$PSQL spaceschema < /dev/null" 2>/dev/null ; then
		rlLogInfo "Database spaceschema already exists, not re-creating."
	else
		rlRun "su - postgres -c '$CREATEDB -E UTF8 spaceschema'"
	fi
	if su - postgres -c "$CREATELANG -l spaceschema | grep plpgsql" 2>/dev/null ; then
		rlLogInfo "Language plpgsql already exists in spaceschema."
	else
		rlRun "su - postgres -c '$CREATELANG plpgsql spaceschema'"
	fi
	if su - postgres -c "$CREATELANG -l spaceschema | grep pltclu" 2>/dev/null ; then
		rlLogInfo "Language pltclu already exists in spaceschema."
	else
		rlRun "su - postgres -c '$CREATELANG pltclu spaceschema'"
	fi
	export PGPASSWORD=spacepw
	if $PSQL -h localhost -a -U spaceuser spaceschema < /dev/null ; then
		rlLogInfo "User spaceuser already exists, not re-creating."
	else
		#rlRun "su - postgres -c '( echo spacepw ; echo spacepw ) | $CREATEUSER -P -sDR spaceuser'" 0
		rlRun "su - postgres -c '( echo spacepw ; echo spacepw ) | $CREATEUSER -P -s spaceuser'" 0
	fi
	rlRun "$PSQL -h localhost -a -U spaceuser spaceschema < /dev/null" 0 "Check the setup"

rlPhaseEnd

rlJournalEnd

rlJournalPrintText

