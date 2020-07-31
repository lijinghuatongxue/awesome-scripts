#!/bin/bash

# Date: 2016-07-19 20:49:08
# Author: Turing Chu
# Description: uninstall cmdb/monitor
# error 1 can not find easyops in $PATH
# error 2 rm easyops folder failed
# error 3 delete easyops user failed

basedir="/usr/local/easyops"
curdir=$(dirname $0)

function print_help() {
    echo ""
    echo "$0 [options]  uninstall with interect to confirm"
    echo ""
    echo "[options]"
    echo "  -h, --help  show this help and exit"
    echo "  -y          uninstall silently without confirmation"
    echo ""
    exit 0
}


function check_env() {
    which easyops >>/dev/null 2>&1
    if [ $? -ne 0 ];then
        printf "[ \033[31mERROR 1\033[0m ] Can not find command: easyops in ${PATH}\n"
    fi
}

# stop component
function stop_component() {
    local old_dir=$(pwd)
    local app_lists=$(ls -Sr ${basedir})
    local pids=`ps -ef|egrep "^easyops"|awk '{print $2}'`
    if [ -n "$pids" ];then
        kill -9 $pids
    fi 
    
    # some componen's special processing
    local apps="detect_agent agent nginx rabbitmq"
    for app in ${apps};do
        if [ -d /usr/local/easyops/${app} ];then
            easyops 'stop' /usr/local/easyops/${app}
        fi
    done
} 

# rm folder
function remove_file() {
    # rm /usr/local/easyops
    rm -fr /usr/local/easyops
    if [ $? -ne 0 ];then
        printf "[ \033[31mERROR 2\033[0m ] Remove $basedir error.\n"
    else
        printf "[ \033[32mSUCCESS\033[0m ] Remove $basedir\n"
    fi

    # rm /data/easyops
    rm -fr /data/easyops
    if [ $? -ne 0 ];then
        printf "[ \033[31mERROR 2\033[0m ] remove /data/easyops error.\n"
    else
        printf "[ \033[32mSUCCESS\033[0m ] Remove /data/easyops\n"
    fi
    
    # rm ~/.erlang.cookie
    rm -f ~/.erlang.cookie
    if [ $? -ne 0 ];then
        printf "[ \033[31mERROR 2\033[0m ] remove ~/.erlang.cookie error.\n"
        exit 2
    fi   

    # rm ~/.easyops start 2.11
    rm -f ~/.easyops
    rm -f "${curdir}/stat.log"
    rm -f "${curdir}/Deploy/InstallDeploy-C/bin/stat.log"
    rm -f /usr/bin/easyops
}

# delete easyops user
function rm_user() {
    id easyops >> /dev/null 2>&1
    if [ $? -ne 0 ];then
        printf "[ \033[33mWarning\033[0m ] No such user: easyops\n"
        return
    fi
    userdel -r easyops
    if [ $? -ne 0 ];then
        printf "[ \033[31mERROR 3\033[0m ] delete user: easyops error, please try again.\n"
    else
        printf "[ \033[32mSUCCESS\033[0m ] Delete user: easyops\n"
    fi
}

# clean uc
function clean_uc() {
    ps -ef |grep uc-worker |grep -v grep |awk '{print $2}' |xargs kill
}

function uninstall() {
    clean_uc
    check_env
    stop_component
    rm_user
    remove_file
    printf "Please type 'top' command to check\n"
}

function parse_arg_and_handle() {
    arg=$1 
    case $arg in 
        -h|--help)
            print_help
            ;;
        -y)
            uninstall
            ;;
        *)
            print_help
            ;;
    esac 
}

function confirm() {
    while true;do
        printf "\n[ \033[31mDangers\033[0m ] "
        read -p "uninstall easyops[yes/no]? " -t 30 affirm
		if [ $? -ne 0 ];then
			printf "\nTime out \n"
			exit 0
		fi
        if [[ $affirm =~ yes|y|Y ]];then
            local affirm="yes"
            break
        elif [[ $affirm =~ N|n|NO|no|No|nO ]];then
            local affirm="no"
            break
        fi
    done

    if [ $affirm == "yes" ];then
        uninstall
    else
        echo "Get $affirm. Nothing can be done."
        exit 0
    fi
}

# main
function main() {
    if [ "$1" == "" ];then
        confirm
    else
        parse_arg_and_handle $*
    fi
}

# start
main $*
