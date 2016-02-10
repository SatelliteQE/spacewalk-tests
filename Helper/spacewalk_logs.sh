#!/bin/bash
#
# Author: Simon Lukasik
#
set -e
set -o pipefail

#FEATURE_FLAG=${SW_LOG_PARAM:-0} # Log checking is switched ON
FEATURE_FLAG=${SW_LOG_PARAM:-1} # Log checking is switched OFF

function print_help(){
    local script_name=`basename $0`
    echo "$script_name - Tool for automatic inspection of Spacewalk logs. It greps"
    echo "        given Spacewalk logs for strings which could indicate a failure"
    echo "        of Spacewalk. Supports easy made workarounds."
    echo
    echo "Synopsis: $script_name assert_clean|assert_dirty|skip_assert [FILES]"
    echo
    echo "assert_clean - assert that given logs are clean and rotate them."
    echo "               Returns a count of logs which were found dirty."
    echo "assert_dirty - assert that given logs are not clean and rotate them"
    echo "               Returns a count of logs which were found clean."
    echo "verify_dirty - Verify that the expected errors are presented"
    echo "               Returns zero on success"
    echo "skip_assert  - rotate given logs without assertions (Use with CAUTION!!!)"
    echo "               Returns zero on success."
}

function main(){
    # Create local log and link to the last one
    rm -f last_rhn_local.log
    local_rhn_log="rhn_local_$(date +%a_%b_%d_%Y_%H_%M_%S).log"
    touch ${local_rhn_log}
    ln -s ${local_rhn_log} last_rhn_local.log

    local command="$1";
    [ "$#" -ge "1" ] && shift
    local filelist="$@"
    [ -z "$filelist" ] && filelist=`get_spacewalk_logs`
    case "$command" in
        assert_clean)
            assert_clean $filelist
            ;;
        assert_dirty)
            assert_dirty $filelist
            ;;
        skip_assert)
            skip_assert $filelist
            ;;
        verify_dirty)
            verify_dirty $filelist
            ;;
        *)
            echo "Unknown command-line option: '$command' (!)" >&2
            echo >&2
            print_help
            false
            ;;
    esac
}

function assert_clean(){

    [[ ${FEATURE_FLAG} == 1 ]] && skip_assert $@ &> /dev/null; return 0 # Log checking is switched off
    local score=0
    for log in $@; do
         if [ -s $log ]; then
             cat_new_lines $log | grep_spacewalk_log $log || let score+=1
         fi
    done
    return $score
}

function assert_dirty(){

    [[ ${FEATURE_FLAG} == 1 ]] && skip_assert $@ &> /dev/null; return 0 # Log checking is switched off
    local score=0
    for log in $@; do
        if [ -s $log ]; then
            cat_new_lines $log | grep_spacewalk_log revert $log && let score+=1
        else
            echo "FAIL: File not found: $log" >&2
            #let score+=1
        fi
    done

    return $score
}

function skip_assert(){
    for log in $@; do
        if [ -s $log ]; then
            cat_new_lines $log
            echo "Pass: The output above was ignored"
        else
            echo "Not moving $log. File does not exists."
        fi
    done
}

function verify_dirty() {

   [[ ${FEATURE_FLAG} == 1 ]] && return 0 # Log checking is switched off

   # workaround_grep $log 0,1
   [[ -z ${WORKAROUND_STRING} ]] && echo "Variable WORKAROUND_STRING must be set and exported !!!" && return 1

   ! egrep -v "${WORKAROUND_STRING}" ${1}

   return $?

}

function get_spacewalk_logs(){
    local logs="
    /var/log/cobbler/cobbler.log
    /var/log/httpd/ssl_error_log
    /var/log/httpd/error_log
    /var/log/rhn/osa-dispatcher.log
    /var/log/rhn/rhn_server_satellite.log
    /var/log/rhn/rhn_taskomatic_daemon.log
    /var/log/rhn/rhn_server_xmlrpc.log
    /var/log/rhn/rhn_web_api.log
    /var/log/rhn/search/rhn_search.log
    /var/log/rhn/search/rhn_search_daemon.log
    /var/log/up2date
    /var/log/rhn/rhn_proxy_broker.log
    /var/log/rhn/rhn_proxy_redirect.log
    /var/log/squid/access.log
    /var/log/squid/cache.log
    /var/log/squid/store.log
    /var/log/squid/squid.out
    /var/log/maillog
    "
    rpm -q --quiet tomcat5 && logs="$logs /var/log/tomcat5/catalina.out"
    rpm -q --quiet tomcat6 && logs="$logs /var/log/tomcat6/catalina.out"
    rpm -q --quiet tomcat && logs="$logs /var/log/tomcat/catalina.out"
    rpm -q --quiet postgresql-server && logs="$logs /var/lib/pgsql/data/pg_log/postgresql-$(date | awk '{print $1}').log"

    echo $logs
}

function grep_spacewalk_log(){
    local revert=0
    if [ "$1" == "revert" ]; then
        local revert=1
        shift
    fi
    local log_name=$1
    local grep_options='--quiet'
    case $log_name in
        # Strings come from long running RHN Satellite 5.4.1 instance,
        #         might not be exhaustive
        # TODO - not sure for what to check
        # /var/log/rhn/rhn_upload_package_push.log
        # /var/log/rhn/rhn_config_management.log
        /var/log/cobbler/cobbler.log)
            egrep -i 'Exception'
            ;;
        /var/log/httpd/ssl_error_log)
            egrep '\[error\]'
            ;;
        /var/log/httpd/error_log)
            workaround bz703495 | workaround bz844676 | egrep '\[error\]'
            ;;
        /var/log/rhn/osa-dispatcher.log)
            egrep -i 'ERROR|Traceback'
            ;;
        /var/log/rhn/rhn_server_satellite.log)
            egrep -i 'ERROR|Exception|Traceback|rhnFault'
            ;;
        /var/log/rhn/rhn_taskomatic_daemon.log)
            workaround bzNo100rep | workaround bzNo100repSpClone | egrep -i 'Exception'
            ;;
        /var/log/rhn/rhn_server_xmlrpc.log)
            egrep -i 'ERROR'
            ;;
        /var/log/rhn/rhn_web_api.log)
            egrep 'ERROR|XmlRpcFault|Exception'
            ;;
        /var/log/rhn/search/rhn_search.log)
            egrep -i 'ERROR|WARN|Exception'
            ;;
        /var/log/rhn/search/rhn_search_daemon.log)
            egrep -i 'ERROR|WARN|Exception'
            ;;
        /var/log/tomcat5/catalina.out|/var/log/tomcat6/catalina.out|/var/log/tomcat/catalina.out)
            # workaround bug 707469, bug 748341
            workaround bz707469 | workaround bz748341 | workaround bz905092 \
                | egrep 'WARNING|ERROR|^Caused by:|SIGSEGV|WARN  com.redhat.rhn.common.hibernate.EmptyVarcharInterceptor'
                # TODO: Assert for SEVERE strings as well
            ;;
        /var/log/up2date)
            workaround bzNotBug | egrep -i 'Traceback|Fatal|error|Invalid|WARNING|exceptions'
            ;;
        /var/log/rhn/rhn_proxy_redirect.log)
            egrep -i 'ERROR'
            ;;
        /var/log/rhn/rhn_proxy_broker.log)
            egrep -i 'ERROR'
            ;;
        /var/log/squid/access.log)
            egrep -i "[^0-9]404[^0-9] [0-9]+"
            ;;
        /var/log/squid/cache.log)
            egrep -i "FATAL|ERROR|WARNING|SECURITY ERROR|SECURITY ALERT|SECURITY NOTICE"
            ;;
        /var/log/squid/store.log)
            egrep -i " 404 "
            ;;
        /var/log/squid/squid.out)
            egrep -i "ERROR"
            ;;
        /var/log/maillog)
            false
            ;;
        *)
            echo "WARN: Unknown pattern for: '$log_name'." >&2
            [ "$revert" -eq 0 ] # make it fail either case
            ;;
    esac
    if [ "$?" -eq "0" ]; then
       [ "$revert" -eq "0" ] && echo -n "BAD" >&2
       [ "$revert" -eq "1" ] && echo -n "GOOD" >&2
       echo ": Malicious strings found in $log" >&2
       echo >&2
       return 1
    else
       [ "$revert" -eq "0" ] && echo -n "GOOD" >&2
       [ "$revert" -eq "1" ] && echo -n "BAD" >&2
       echo ": File is sane: $log" >&2
    fi
}

function workaround(){
    local bz703495=' \[error\] Exception KeyError: KeyError.* in <module .threading. from ./usr/lib(64)*/python2.[67]/threading.pyc.> ignored'
    local bz707469='^Throwable occurred: javax.management.MalformedObjectNameException: Cannot create object name for org.apache.catalina.connector.Connector@'
    local bz748341='^WARNING: A docBase /var/lib/tomcat.*/webapps/rhn inside the host appBase has been specified, and will be ignored$'
    local bz844676='\[error\] python_init: Python version mismatch, expected .2\.7\.2., found .2\.7\.3.\.|\[error\] python_init: Python executable found ./usr/bin/python.\.|\[error\] python_init: Python path being used .*\.'  # clone for F17 is bug 845943
    local bz905092='WARN  com.redhat.rhn.common.hibernate.EmptyVarcharInterceptor - Object com\.redhat\.rhn\.domain\.errata\.impl\.PublishedBug is setting empty string url'
    local bzNo100rep='com.redhat.rhn.common.db.ConstraintViolationException: ORA-00001: unique constraint \(SPACEUSER.RHNPACKAGEREPODATA_PK\) violated|at com.redhat.rhn.common.translation.SqlExceptionTranslator.oracleSQLException\(SqlExceptionTranslator.java:75\)|at com.redhat.rhn.common.translation.SqlExceptionTranslator.sqlException\(SqlExceptionTranslator.java:42\)|java.sql.SQLException: ORA-00001: unique constraint \(SPACEUSER.RHNPACKAGEREPODATA_PK\) violated|at oracle.jdbc.driver.DatabaseError.throwSqlException\(DatabaseError.java:112\)|com.redhat.rhn.common.db.ConstraintViolationException: ORA-00001: unique constraint \(RHNSAT.RHNPACKAGEREPODATA_PK\) violated|java.sql.SQLException: ORA-00001: unique constraint \(RHNSAT.RHNPACKAGEREPODATA_PK\) violated'
    # workaround for bug 915287
    # problem is traceback: exceptions.AttributeError: 'module' object has no attribute 'utf8_encode''
    # this error message is correct behaviour:
    # # local bzNotBug='Traceback \(most recent call last\):\|if ret is None:raise libvirtError\(.virConnectOpen\(\) failed.\)\|libvirt.libvirtError: unable to connect to ./var/run/libvirt/libvirt-sock., libvirtd may need to be started: No such file or directory'
    local bzNotBug='Traceback|if ret is None:raise libvirtError|libvirt.libvirtError: unable to connect to ./var/run/libvirt/libvirt-sock., libvirtd may need to be started: No such file or directory|if _is_host_domain\(fail_on_error\).|sys.stderr.write\(rhncli.utf8_encode\(_\(.Warning. Could not retrieve virtualization information|exceptions.AttributeError: .module. object has no attribute .utf8_encode.'
    # in test spacewalk-clone-by-date
    local bzNo100repSpClone='com.redhat.rhn.common.db.WrappedSQLException: ERROR: duplicate key value violates unique constraint .rhnpackagerepodata_pk.|
at com.redhat.rhn.common.translation.SqlExceptionTranslator.postgreSqlException\(SqlExceptionTranslator.java:54\)|
at com.redhat.rhn.common.translation.SqlExceptionTranslator.sqlException\(SqlExceptionTranslator.java:44\)|
Caused by: org.postgresql.util.PSQLException: ERROR: duplicate key value violates unique constraint .rhnpackagerepodata_pk.'
    case $1 in
        bz703495)
            egrep -v "${bz703495}"
            ;;
        bz707469)
            egrep -v "${bz707469}"
            ;;
        bz748341)
            cat
            ;;
        bz844676)
            if is_fedora 17; then
                egrep -v "$bz844676"
            else
                cat
            fi
            ;;
        bz905092)
              egrep -v "${bz905092}"
            ;;
        bzNo100rep)
              egrep -v "${bzNo100rep}"
            ;;
        bzNotBug)
              egrep -v "${bzNotBug}"
            ;;
        bzNo100repSpClone)
              egrep -v "${bzNo100repSpClone}"
            ;;
        *)
            echo "FAIL: Unknown workaround '$1'!" >&2
            false
            ;;
    esac
}

function is_fedora(){
    local version=''
    [ -n "$1" ] && local version="-$1"
    rpm -q --whatprovides redhat-release | grep -q "^fedora-release$version"
}

function cat_new_lines(){
    # Cat lines from log, we haven't seen yet
    local log="$1"
    local journal="$log.journal"
    local tmp=`mktemp`
    cp $log $tmp
    if is_journal_valid $tmp $journal; then
        local last_checked_line=`tail -n 1 $journal | cut -d',' -f 1`
        local lines=`wc -l $tmp | cut -d' ' -f 1`

        echo "#### ${log} ####" >> ${local_rhn_log} # DY

        if [ "$last_checked_line" -gt "$lines" ]; then
             echo "The sky falls down. The log file has been curtailed! \
                 $last_checked_line,$lines,$log,$tmp,$journal" >&2 | tee -a ${local_rhn_log} # DY
             create_new_journal $tmp $journal
        elif [ "$last_checked_line" -lt "$lines" ]; then
             let last_checked_line+=1
             tail -n +$last_checked_line $tmp | tee -a ${local_rhn_log} # DY

             make_journal_entry $lines $journal
        fi
    elif [ -s $tmp ]; then
        create_new_journal $tmp $journal
    fi
    rm -rf $tmp
}

function create_new_journal(){
    local log="$1"
    local journal="$2"
    local lines=`wc -l $tmp | cut -d' ' -f 1`
    local sha=`sha256sum $tmp | cut -d' ' -f 1`
    echo "$lines,$sha," > $journal
    cat $tmp
    make_journal_entry $lines $journal
}

function is_journal_valid(){
    local log="$1"
    local journal="$2"
    if [ -s $journal ]; then
        local first_line=`head -n 1 $journal`
        local lines=`echo $first_line | cut -d',' -f 1`
        local expected_sha=`echo $first_line | cut -d',' -f 2`
        local actual_sha=`head -n $lines $log | tee nevis.txt | sha256sum | cut -d' ' -f 1`
        [ "$expected_sha" == "$actual_sha" ]
    else
        false
    fi
}

function make_journal_entry(){
    local lines="$1"
    local journal="$2"
    echo "$lines,`date +'%F %k:%m:%S:%N'`,`pwd`" >> $journal
}

# Set PATH as we need it
[[ ${PATH} =~ '/mnt/tests/CoreOS/Spacewalk/Helper' ]] || export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"

main $@

