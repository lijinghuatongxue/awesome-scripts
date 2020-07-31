#!/bin/bash
# set ulimit


limit_file=/etc/security/limits.conf
max_limit=102400

user=$1

[[ ${user}"X" == "X" ]] && echo "user is empty" && exit 1

set_ulimit() {
    user=$1

    [[ "X" == "${user}X" ]] && echo "user is empty" && exit 1

    grep "$user" $limit_file >/dev/null 2>&1
    if [[ $? -ne 0 ]]; then
	echo "${user} - nofile $max_limit" >> $limit_file
	echo "${user} - nproc $max_limit" >> $limit_file
    else
	sed -i "s/.*${user}.*nofile.*/${user} - nofile $max_limit/g" $limit_file
	sed -i "s/.*${user}.*nproc.*/${user} - nproc $max_limit/g" $limit_file
    fi
}

set_ulimit ${user}
echo "set max ulimit $max_limit done"
