#!/bin/bash
#
# Author:      Simon Lukasik
# Description: Creating a first user on Spacewalk after the installation
#
set -e
set -o pipefail

post_data="login=$RHN_USER&desiredpassword=$RHN_PASS&desiredpasswordConfirm=$RHN_PASS&prefix=Mr.&firstNames=Admin&lastName=Admin&email=root@localhost&orgName=SystemsManagementQA&submitted=true"
rpm -q spacewalk-branding | grep -- '-2\.4\.' \
    && post_data="login=$RHN_USER&desiredpassword=$RHN_PASS&desiredpasswordConfirm=$RHN_PASS&prefix=Mr.&firstNames=Admin&lastName=Admin&email=root@localhost&account_type=create_sat"
wget_command="wget --no-check-certificate"
base_uri="https://$RHN_SERVER"

handler=${CFU_handler:-CreateFirstUser}
rpm -q spacewalk-branding | grep -- '-2\.4\.' \
    && handler=${CFU_handler:-CreateFirstUserSubmit}

${wget_command} -O create-admin-user.html \
    --save-cookies cookies.txt --keep-session-cookies \
    ${base_uri}
if grep csrf_token create-admin-user.html; then
    token=`grep csrf_token create-admin-user.html | awk -F'"' '{print $6}'`
    post_data="$post_data&csrf_token=${token}"
fi
${wget_command} -O create-admin-user-response.html \
    --post-data "${post_data}" \
    --load-cookies cookies.txt \
    "${base_uri}/rhn/newlogin/$handler.do"

