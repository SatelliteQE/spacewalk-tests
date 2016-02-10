#!/bin/bash
#dyordano@redhat.com
#jhutar@redhat.com


function print_help(){
    
    echo  -e "Options: \n \
    --help|-h : Get Help \n \
    --action|-a : Action \n \
    --server|-s : Server name \n"
                
    echo -e "Examples: \n \
    helper-rhn-satellite.sh --action is_localhost --server=[$(hostname)|localhost] \n \
    helper-rhn-satellite.sh --action is_running --server=[$(hostname)|localhost|Empty for localhost] \n \
    helper-rhn-satellite.sh --action restart \n"
}

function print_msg() {
  
  if [ "$1" != 'INFO' -a "$1" != 'DEBUG' ]; then
    echo "[${1}] ${2}" >&2
  else
    echo "[${1}] ${2}"
  fi
  
}

function set_value() {
 
  [[ ${2} =~ ^- ]] && echo "Error: Option ${3} requires argument!"  && exit 1
  eval "${1}=${2}"
}
                                       
PARAMS=$( getopt  -n$0 -u -a --longoptions="help action: \
                                            server:" "shav" "$@" ) 
                                  
[[ $? -ne 0 ]] && print_help || set -- ${PARAMS}  

while [ $# -gt 0 ]; do
    case $1 in
        --help|-h)  print_help;;
        --action|-a) set_value ACTION ${2} ${1};shift;;
        --server|-s) set_value SERVER ${2} ${1};shift;;
        
        --)        shift;
                   [[ $# -gt 0 ]] && echo "Error: Extra string(s) was/were found: $@" && exit 1
                   break;;
        #-*)        print_help;;
        #*)         print_help;;            
    esac
    shift
done

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_helper_is_localhost
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_helper_is_localhost

Ensures that parameter is a localhost system, that it is not remote one.

    rhn_helper_is_localhost [hostname]

=over

=item hostname

Hostname you want to check. If not provided, function will try
to check C<RHN_SERVER> variable.

=back

Returns 0 if hostname is local system and non0 if it is not.

=cut
function rhn_helper_is_localhost() {
  local host=${1:-$RHN_SERVER}
  if [ "$host" == 'localhost' -o \
       "$host" == 'localhost.localdomain' -o \
       "$host" == '127.0.0.1' -o \
       "$host" == "$( hostname )" -o \
       "$host" == "$( hostname -i )" ]; then
    return 0
  else
    return 1
  fi
}


# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_satellite_check_if_runs
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_satellite_check_if_runs

Check if there is running RHN Satellite or Spacewalk on a given hostname.
If it is not running and given hostname is localhost, we will try to
restart satellite and will check again with previous errors logged.

    rhn_satellite_check_if_runs [hostname]

=over

=item hostname

Test server with this hostname, default is what C<hostname> command returns.

=back

Returns 0 if server is running, returns != 0 if not

=cut
function __rhn_satellite_check_if_runs() {
  local host=${1:-$(hostname)}
  local log=$( mktemp )
  ping -c 3 -i .2 -q $host &>$log || ping6 -c 3 -i .2 -q $host &>$log
  if [[ $? -ne 0 ]];then 
    cat $log
    return 1
  fi
  
  local log2=$( mktemp )
  wget -O $log https://$host --no-check-certificate &>$log2
  if [[ $? -ne 0 ]];then 
       cat $log
       cat $log2
      return 2
  fi

  if ! taskomatic_runs.py $host $DEFAULT_USER $DEFAULT_PASS; then
    rhn_helper_is_localhost $host && service taskomatic status
    return 3
  fi
}

function rhn_satellite_check_if_runs() {
  local host=${1:-$(hostname)}
  __rhn_satellite_check_if_runs $host
  local rc=$?
  if [ $rc -eq 0 ]; then
    return 0
  else
    if rhn_helper_is_localhost $host; then
      # We will try to restart satellite to try to fix satellite for upcomming tests.
      # Above errors stays logged in journal - this is important not to change.
      print_msg 'FAIL' "rhn_satellite_check_if_runs: Check failed and looks like satellite is on localhost, so trying to restart satellite now."
      rhn_satellite_restart
      __rhn_satellite_check_if_runs $host
      local rc2=$?
      return $( expr $rc + $rc2 )   # return result of 1st + 2nd check,
                                    # because usually logs submission is
                                    # tied to this exit value and we want
                                    # logs to investigate 1st fail even
                                    # if restart worked
    else
      return $rc   # return result of 1st check
    fi
  fi
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_satellite_restart
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_satellite_restart

Starts RHN Satellite

    rhn_satellite_restart [eec]

=over

=item eec

Expected exit code. Assert fails if satellite operation returns something else. Default is '0'.

=back

=cut
function rhn_satellite_restart() {
  rhn_satellite_stop || return 1
  rhn_satellite_start || return 1
}
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_satellite_stop
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_satellite_stop

Stops RHN Satellite

    rhn_satellite_stop [eec]

=over

=item eec

Expected exit code. Assert fails if satellite operation returns something else. Default is '0'.

=back

=cut
function rhn_satellite_stop() {
    rhn-satellite stop ||  return 1
}



# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_satellite_start
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_satellite_start

Starts RHN Satellite

    rhn_satellite_start [eec]

=over

=item eec

Expected exit code. Assert fails if satellite operation returns something else. Default is '0'.

=back

=cut
function rhn_satellite_start() {

  rhn-satellite start || return 1
  
  # Call this to return reasonable exit code
  wget https://$( hostname ) --no-check-certificate && return 0
  return 1
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# rhn_satellite_restart
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
: <<=cut
=pod

=head3 rhn_satellite_restart

Starts RHN Satellite

    rhn_satellite_restart [eec]

=over

=item eec

Expected exit code. Assert fails if satellite operation returns something else. Default is '0'.

=back

=cut
function rhn_satellite_restart() {
  rhn_satellite_stop || return 1
  rhn_satellite_start || return 1
}
### MAIN ###

# Set PATH as we need it
[[ ${PATH} =~ '/mnt/tests/CoreOS/Spacewalk/Helper' ]] && export PATH="$PATH:/mnt/tests/CoreOS/Spacewalk/Helper"

case ${ACTION} in

         restart) rhn_satellite_restart;;
      is_running) rhn_satellite_check_if_runs ${SERVER};;
    is_localhost) rhn_helper_is_localhost ${SERVER};;
               *) print_msg ERROR "Unknown action"; exit 100;;
esac

