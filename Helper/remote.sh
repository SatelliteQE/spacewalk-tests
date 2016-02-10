#!/bin/bash
#
# Author:  Simon Lukasik
# Credits: Based on work of Petr Sklenar & Dimitar Yordanov
#

# Set DEBUG to non-empty string for Bash debug output
[ -n "$DEBUG" ] && set -x

set -e
set -o pipefail


function Print_Help(){
    local cmd=`basename $0`
    echo "$cmd - tool for running commands on a remote machine"
    echo "Usage:"
    echo "  $cmd init SERVER [PASSWORD]"
    echo "  $cmd run SERVER BASH_COMMAND - Run the command on remote server"
    echo
    echo "Where SERVER is either:"
    echo "  RHN_SERVER - The value of RHN_SERVER bash variable"
    echo "  REG        - Machine we are registered to"
    echo "  REG_SAT    - Machine we are registered to, recursion if it's RHN Proxy"
    echo "  hostname   - arbitrary hostname"
    echo
    echo "Example:"
    echo "  $cmd init REG_SAT 12345"
    echo "  $cmd run REG_SAT 'rpm -q --whatprovides rhn-java'"
}

function Prerequisities(){
    rpm -q expect &> /dev/null || yum -y install expect
    export RHTESTDIR='/etc/rhtest'
    mkdir -p "$RHTESTDIR/ssh-keys"
}

function Is_Localhost(){
    [ "$1" == 'localhost' -o "$1" == "`hostname`" ]
}

function Is_Hosted(){
    echo "$1" | grep -q --quiet 'rhn\.redhat\.com'
}

function Get_Key(){
    echo -n "$RHTESTDIR/ssh-keys/$1"
}

function Init(){
    host=$1
    Is_Localhost "$host" && return 0
    Is_Hosted "$host" && return 1

    rm -rf /root/.ssh/known_hosts
    key=`Get_Key $host`
    rm -rf $key
    ssh-keygen -f $key -N "" -v &> /dev/null || return 99
    restorecon -vR $key* &> /dev/null || return 99
    chmod 600 $key

    rm /tmp/ssh-copy.exp -rf
    cat > /tmp/ssh-copy.exp << EOF
#!/usr/bin/expect
spawn ssh-copy-id -i [lindex \$argv 2]  root@[lindex \$argv 0]
#exp_internal 1   # uncomment to get debug output
expect {
  timeout {
    send_user "\nFailed to get password prompt\n"
    exit 1
  }

  -re ".*Are.*.*yes.*no.*" {
    send "yes\r"
    #send_user "\nYes no question answered\n"
    exp_continue
  }

  "*?assword:*" {
    send [lindex \$argv 1]
    send "\r"
    #send_user "\nPassword sent\n"
    exp_continue
  }

  "*Now try logging into the machine*" {
    #send_user "\nEnd reached\n"
    exit
  }
}
EOF

    /usr/bin/expect /tmp/ssh-copy.exp $host $password $key
}


function Run(){
    local host=$1;shift
    local command="$@"
    local output=`mktemp`
    if Is_Localhost "$host"; then
        eval "$command;echo \$?" >> $output
    else
        command="$command ;echo \$?"
        ssh -o 'PubkeyAuthentication yes' -o 'PasswordAuthentication no' -o 'GSSAPIAuthentication no' root@$host -i `Get_Key $host` -o StrictHostKeyChecking=no "$command" > $output
    fi
    cat $output
    local result=`tail -n1 $output`
    rm -rf $output
    return $result
}

function Parse_Update(){
    egrep "^serverURL=http.*/XMLRPC$" /etc/sysconfig/rhn/up2date \
        | tail -n 1 \
        |  sed 's/^serverURL=http[s]*:[\/]\{2\}\(.*\)\/XMLRPC$/\1/'
}

function Get_Server(){
    local server="${1:-'RHN_SERVER'}"
    case $server in
        'RHN_SERVER')
            server="$RHN_SERVER"
            ;;
        'REG')
            server=`Parse_Update`
            ;;
        'REG_SAT')
            server=`Parse_Update`
            Init $server
            local override=`Run $server "awk -F'=' '"'$1'" ~ /proxy.rhn_parent/ {print "'$2'"}' /etc/rhn/rhn.conf" | head -n -1 | head -n 1`
            [ "$override" != "" ] && server="$override"
            ;;
    esac
    echo $server
}


function Main(){
    Prerequisities
    # export password='password'
    server=`Get_Server $2`
    case $1 in
        'init')
            [ $# -eq 3 ] && password="$3"
            Init $server
            ;;
        'run')
            shift;shift
            Run $server $@
            ;;
        *)
            Print_Help
            exit 56
            ;;
    esac
}

Main $@


