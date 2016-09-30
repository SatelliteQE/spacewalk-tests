#!/bin/sh

# Copyright (c) 2006 Red Hat, Inc. All rights reserved. This copyrighted material
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
#
# Author: Petr Sklenar <psklenar@redhat.com>
# based on Jan Hutar <jhutar@redhat.com> installation script


: <<=cut
=pod

=head1 NAME

spacewalk-install.sh - magic for installing Spacewalk

=head1 DESCRIPTION

Set of functions for tests which neads to install Spacewalk.

=head1 FUNCTIONS

=cut



for lib in /usr/share/beakerlib/beakerlib.sh ; do
  source $lib || echo "FAIL: cannot source $lib"
done
unset lib

function __rlGetDistroVersionVariant() {
  local version=0
  if rpm -q redhat-release &>/dev/null; then
    version=$( rpm -q --qf="%{VERSION}" redhat-release )
  elif rpm -q fedora-release &>/dev/null; then
    version=$( rpm -q --qf="%{VERSION}" fedora-release )
  elif rpm -q centos-release &>/dev/null; then
    version=$( rpm -q --qf="%{VERSION}" centos-release )
  fi
  rlLogDebug "__rlGetDistroVersionVariant: This is distribution version/variant '$version'"
  echo "$version"
}
function rlGetDistroVariant() {
  __rlGetDistroVersionVariant | sed "s/^[0-9]\+\(.*\)$/\1/"
}


#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  defaults variables
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

RHEL=$(rlGetDistroRelease | tail -n 1)
FEDORA=$RHEL
ARCH=$(rlGetArch | tail -n 1)
DEFAULT_ANSWER_FILE="/usr/share/spacewalk/setup/defaults.d/defaults.conf"
SYNC_CHANNELS="-"
APP=$( /mnt/tests/CoreOS/Spacewalk/Helper/helper-get-updater.sh )

export RHEL ARCH DEFAULT_SPACEWALK_INSTALL DEFAULT_ANSWER_FILE SPACEWALK_REPO SYNC_CHANNELS



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_install_important_package
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# Author: Simon Lukasik <slukasik@redhat.com>
function spacewalk_install_important_package() {
  local install_package=$1
  rlAssertGreater "Package name have to be provided" ${#install_package} 0 || return 1

  # Remember pipefail setting and set what we need
  # (due that '... | tee' later)
  set -o | grep --quiet 'pipefail.*on'
  local set_pipefail_was=$?
  set -o pipefail

  # Install what we have to
  local install_log="/tmp/$APP-install-$install_package"
  rlRun "$APP clean all"
  #$APP install -d9 $install_package </dev/null >$install_log.debug 2>&1
  rlRun "$APP install $install_package -y >$install_log 2>&1"
  if [ $? -ne 0 ]; then
    #rlRun "tail $install_log.debug"
    rlRun "tail $install_log"
    #rlFileSubmit $install_log.debug
    rlFileSubmit $install_log
  fi
  rlAssertRpm $install_package
  rlShowPackageVersion $install_package
  rlFileSubmit $install_log

  # Restore pipefail setting
  [ $set_pipefail_was -ne 0 ] && set +o pipefail

  # Check yum/dnf output for relevant warnings
  grep -v '^warning: .*Header.*NOKEY' $install_log \
    | grep -v '^Warning: RPMDB altered outside of $APP' \
    | grep -v '^warning: /etc/sysconfig/rhn/up2date created as /etc/sysconfig/rhn/up2date.rpmnew' \
    | grep -v '^warning: /etc/yum/pluginconf.d/rhnplugin.conf created as /etc/yum/pluginconf.d/rhnplugin.conf.rpmnew' \
    > $install_log-filtered
  rlRun "grep -i '^warning' $install_log-filtered" 1

}



#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_answers_prepare
#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

function spacewalk_answers_prepare() {

  rlAssertExists $DEFAULT_ANSWER_FILE
  rlRun "cp -rf $DEFAULT_ANSWER_FILE answers.txt"
  rlAssertExists answers.txt   # new values for answers.txt
  sed -i s/admin-email.*/admin-email=root@localhost/ answers.txt
  sed -i s/ssl-set-org" ".*/ssl-set-org=SpaceWalkerORG/ answers.txt
  sed -i s/ssl-set-org-unit.*/ssl-set-org-unit=SpaceWalkerUNIT/ answers.txt
  sed -i s/ssl-set-city.*/ssl-set-city=SpaceCity/ answers.txt
  sed -i s/ssl-set-state.*/ssl-set-state=WalkerState/ answers.txt
  sed -i s/ssl-set-country.*/ssl-set-country=CZ/ answers.txt
  sed -i s/ssl-password.*/ssl-password=$DEFAULT_PASS/ answers.txt
  echo "ssl-set-email = root@localhost" >> answers.txt
  echo "run-updater=1" >> answers.txt
  echo "ssl-config-sslvhost=Y" >> answers.txt

# call_function $DB_TYPE-1 $DB_USER-2 $DB_PASSWORD-3 $DB_SID-4 $DB_HOST-5 $DB_PORT-6
    if echo "$1" | grep 'ORA'; then
      echo  "db-backend = oracle" >> answers.txt
    else
      echo  "db-backend = postgresql" >> answers.txt
    fi
    echo  "db-user = $2" >> answers.txt
    echo  "db-password = $3"  >> answers.txt
    echo  "db-host = $5"  >> answers.txt
    echo  "db-sid = $4"  >> answers.txt
#db-sid was renamed in sw1.1
    echo  "db-name = $4"  >> answers.txt
    echo  "db-port = ${6:-1521}"  >> answers.txt
    echo  "db-protocol = TCP"  >> answers.txt
    echo  "enable-tftp = Y"  >> answers.txt

#TODO: log what is prepared here
  rlRun "ls -la answers.txt"
  rlLog "`echo answer-file;cat answers.txt|grep '^[^#]'`"
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_setup
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 spacewalk_install

Install Spacewalk using answers file and  script. Default answers file
 will be updated using values from the answers_updates.txt file
in the current directory.

After the installation first user 'admin' with password $DEFAULT_PASSWORD will be created.

    spacewalk_install install [gpgcheck] [selinux]

=over

=item install

Absolute path to the installation tree (i.e. mounted install medium) - starts
with a C{/}. You can use paths on the C{/mnt/<whatever>} (which will be mounted).
Or: this can also be a URL to the installation image (staring with
C{http://}). In this case we will download it, mount it and will install from
it.

=item gpgcheck

gpgcheck

=item selinux

selinux

=back

=cut
function spacewalk_setup() {
  #local SPACEWALK_GPGCHECK="$1"
  #local SPACEWALK_SELINUX="$2"
  #
  #rlLog "spacewalk_install: Spacewalk gpgcheck state:      $SPACEWALK_GPGCHECK"
  rlLog "spacewalk_install: Spacewalk SELinux state:       `getenforce`"

  # Backup
  rlFileBackup /etc/yum.conf
  rlFileBackup /etc/yum.repos.d/

  # Import all RPM keys we can find
  __rpm_import_keys

  # TODO: set GPG up to config and later restore
  # gpg is 0 now
  #

  # Modify SELinux
  # rhn_helper_selinux "$SPACEWALK_SELINUX"
  # TODO: selinux is 0 now

  # Set these variables - we need them for the installer's gpg
  local local_USER=$USER
  local local_HOME=$HOME
  export USER='root'
  export HOME='/root'

  # Install (in root's common SELinux context)
  rlRun "spacewalk-setup --answer-file=$(pwd)/answers.txt --disconnected --non-interactive --run-updater --clear-db --external-db"
  # Show few last rows and try installation again
  if [ $? -ne 0 ]; then
    rlRun "false" 0 "spacewalk-setup FAILS there were ERRORS but I will try installation again"
    rlLog `echo rhn-installation-log;tail /var/log/rhn/rhn-installation.log`
    rlLogWarning "spacewalk-setup: Showing last few lines of DB install log"
    rlRun "tail /var/log/rhn/install_db.log"
    rlLogWarning "spacewalk-setup: Showing last few lines of install log"
    rlRun "tail /var/log/rhn/rhn-installation.log"
    rlLog "!!!!!!!!!  trying installation again !!!!!!!!!!!!!! "
    sleep 7m
    spacewalk-setup --answer-file=$(pwd)/answers.txt --disconnected --non-interactive --run-updater --clear-db --external-db
    rlAssert0 "trying INSTALATION again with same steps" $?
  fi

  # Restore USER and HOME variables
  export USER=$local_USER
  export HOME=$local_HOME

  rlRun "create_first_user.sh"

  # Check if spacewalk is OK
  spacewalk_check_if_runs && spacewalk_check_emailed_errors
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_check_if_runs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 spacewalk_check_if_runs

Sanity check if spacewalk is runnnig

    spacewalk_check_if_runs [hostname]

=over

=item hostname

Test server with this hostname, default is what C<hostname> command returns.

=back

Returns 0 if server is running, returns != 0 if not

=cut
function spacewalk_check_if_runs() {
  local host=${1:-$(hostname)}
  if [ "$USE_IPV6_ONLY" == 'true' ]; then
     rlRun "ping6 -c 3 -q $host &>/dev/null" || return 1
  else
     rlRun "ping -c 3 -q $host &>/dev/null" || return 1
  fi
  rlRun "wget -O `mktemp` -q https://$host --no-check-certificate" || return 2
  sleep 2
  rlRun "wget -O `mktemp` -q http://$host/pub/RHN-ORG-TRUSTED-SSL-CERT" || return 3
  # TODO: more tests here
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_check_emailed_errors
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 spacewalk_check_emailed_errors

Check if there are some errors or tracebacks in the root's mailbox
(as 'root@localhost' is configured in answers_updates.txt in 'admin-email').
If root's mailbox do not exist, check if sendmail really works.

    spacewalk_check_emailed_errors

Returns 0 if there are not, returns != 0 if there are erros or tracebacks.

=cut
function spacewalk_check_emailed_errors() {
  if [ -e /var/spool/mail/root ]; then
    local score=0
    rlAssertNotGrep '^Subject: WEB TRACEBACK from' /var/spool/mail/root || let score+=1
    rlAssertNotGrep '^Subject: RHN TRACEBACK from' /var/spool/mail/root || let score+=1
    rlAssertNotGrep '^SYNC ERROR: unhandled exception occurred' /var/spool/mail/root || let score+=1
    return $score
  else
    # In case /var/spool/mail/root do not exist,
    #    a) no errors were send - good
    #    b) sendmail do not work - lets test it now with mail
    rlRun "echo 'test' | mail -s 'test' 'root@localhost'"
    rlRun "sleep 10"   # give a little bit time to the email
    rlAssertExists '/var/spool/mail/root'
    return $?
  fi
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# spacewalk_upload_logs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 spacewalk_upload_logs

Upload all spacewalk relevant log files, adds some general logs
and used answers.txt (should be in a local dir) and generates
some info about current SELinux state.

    spacewalk_upload_logs [additional_log1] [additional_log2] ...

=over

=item additional_log

Additional log you want to add to the resulting tarball

=back

=cut
function spacewalk_upload_logs() {
  local logs=''

  # Generate SELinux infos
  echo '# sestatus' > selinux.info
  sestatus >> selinux.info 2>&1
  echo '# getsebool -a' >> selinux.info
  getsebool -a >> selinux.info 2>&1
  echo '# ls -RZ /var/log/rhn/' >> selinux.info
  ls -RZ /var/log/rhn/ >> selinux.info 2>&1
  echo '# cat /var/log/audit/audit.log | audit2allow' >> selinux.info
  cat /var/log/audit/audit.log | audit2allow >> selinux.info 2>&1

  # Choose which logs to include
  for i in $@ \
    answers.txt selinux.info /etc/yum.conf /etc/sysconfig/rhn/up2date \
    /var/log/up2date /var/log/yum.log \
    /var/spool/mail/root /var/log/audit/audit.log \
    $(find /var/log/tomcat5/ -type f 2>/dev/null) \
    $(find /var/log/tomcat6/ -type f 2>/dev/null) \
    $(find /var/log/httpd/ -type f 2>/dev/null) \
    $(find /var/log/rhn/ -type f 2>/dev/null) \
    $(find /etc/yum.repos.d/ -type f 2>/dev/null) \
    /var/log/rhn_satellite_install.log; do
    [ -r "$i" ] && logs="$logs $i"
  done

  # Bundle chosen logs
  if [ -n "$logs" ]; then
    rlBundleLogs spacewalk-server-var-logs-$RANDOM $logs
  else
    rlLogDebug "spacewalk_upload_logs: No logs were readable"
  fi
}



function rlGetDistroName() {
  rlLogWarning "This function is obsoleted, please use helper-get-distro-name.sh directly"
  /mnt/tests/CoreOS/Spacewalk/Helper/helper-get-distro-name.sh
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# helper_install_repo
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 helper_install_repo

Copies repository specified by C<repofile> option.

    helper_install_repo repofile

=over

=item repofile

Specifies path to the repository file which might contain some
marks wich will be replaced based on current system. These are
C<%OSname%>, C<%OSversion%>, C<%ARCH%>

=back

These marks are:

=over

=item C<%OSname%>

This is RHEL or Fedora.

=item C<%OSversion%>

This is 5 on RHEL5-U6 and 14 on Fedora14.

=item C<%ARCH%>

This is basearch.

=back

=cut
function helper_install_repo() {
  rlAssertExists "$1" || rlDie "Can not access repofile '$1'"
  rlLogInfo "Going to set up repo '$1'"
  rlRun "install $1 /etc/yum.repos.d/"
  local name="/etc/yum.repos.d/$( basename $1 )"
  rlRun "sed -i s/%OSname%/$( helper-get-distro-name.sh | tail -n 1 )/g $name"
  local version=$( rlGetDistroRelease | tail -n 1 )
  rlRun "sed -i s/%OSversion%/$version/g $name"
  local arch=$( rlGetArch | tail -n 1 )
  rlRun "sed -i s/%ARCH%/$arch/g $name"
  if [ -r /etc/yum.repos.d/beaker-Server.repo ]; then
    local beaker_baseurl=$(grep baseurl /etc/yum.repos.d/beaker-Server.repo | sed "s|/x86_64/os\(/Server\)\?$||g")
  else
    local beaker_baseurl=$(grep "name=\"beaker-Server\"" /root/anaconda-ks.cfg | sed 's|^.*url=\([^ ]\+\).*$|\1|' | sed "s|/x86_64/os\(/Server\)\?$||g")
  fi
  rlRun "sed -i 's|%beaker_rhel6_baseurl%|${beaker_baseurl}|g' $name"

  rlRun "cat $name"
  gpgkey=$( grep '^\s*gpgkey\s*=' $name | cut -d '=' -f 2 )
  if [ -n "$gpgkey" ]; then
    gpgkey_file="$( rhn_helper_get "$gpgkey" | tail -n 1 )"
    rlRun "rpm --import $gpgkey_file"
  fi
  rlRun "ls -al /etc/yum.repos.d/"
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# helper_install_repo_EPEL
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 helper_install_repo_EPEL

Installs reository for RHEL we are currently on.

    helper_install_repo_EPEL

Returns 0 if EPEL was enabled, othervise returns 1
(e.g. if it failed to enable it or if it was already enabled).

=cut
function helper_install_repo_EPEL() {
  local rc=1   # default return value is 1
  if rlIsRHEL; then
    if rpm -q epel-release; then
      rlShowPackageVersion 'epel-release'
      rlLogInfo "helper_install_repo_EPEL: EPEL already configured!"
    else
      local dis=$( rlGetDistroRelease | tail -n 1 )
      local arch=$( uname -i )
      if echo "$arch" | grep -e '^i386$' -e '^x86_64$' -e '^ppc$'; then
        rlRun "rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-${dis}.noarch.rpm" \
          && rc=0
        rlShowPackageVersion 'epel-release'
      else
        rlLogWarning "helper_install_repo_EPEL: EPEL not available for '$arch'."
      fi
    fi
  else
    rlLogWarning "helper_install_repo_EPEL: You are not on RHEL system. Skipping EPEL installation."
  fi
  return $rc
}