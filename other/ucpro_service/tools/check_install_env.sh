#!/bin/bash

function log()
{    
    echo -e "\033[0m$*\033[0m"
}

function infolog()
{    
    echo -e "\033[32m$*\033[0m"
}

function warn()
{    
    echo -e "\033[33m$*\033[0m"
}

function error()
{    
    echo -e "\033[31m$*\033[0m"
}

function check_os_version
{
    info="check os version"
    getconf LONG_BIT | grep -iq 64
    if [ $? -eq 0 ]; then
        info="$info is 64, success"
        infolog $info 
    else
         info="$info is 32 bit, failed"
         error $info
         exit -1
    fi
}

check_umask()
{
    uval=$(umask)
    info="os umask value is: $uval,"
    u1=${uval:0-3:1}
    u2=${uval:0-2:1}
    u3=${uval:0-1:1}

    flag=0
    if [[ x$u1 != x0 ]]; then
        flag=1
    fi
    
    if [[ x$u2 != x0 ]] && [[ x$u2 != x2 ]]; then
        flag=1
    fi 

    if [[ x$u3 != x0 ]] && [[ x$u3 != x2 ]]; then
        flag=1
    fi 
    
    if [ $flag -eq 0 ]; then
       infolog $info success 
    else
       error $info should be in [000,002,020,022], check failed
       exit 1
    fi
}

check_nc()
{
    info="check nc command "
    which nc 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
       infolog $info exists success 
    else
        error $info failed
        exit 1
    fi
    
}

check_platform_ports()
{
    which netstat 1>/dev/null 2>&1
    if [ $? -ne 0 ]; then
        warn "not found the command: netstat, please check it first".
        return -1
    fi
    ports=$1
    success_ports=""
    failed_ports=""
    for port in $ports
    do
        netstat -nalp | grep LISTEN | grep -q ":$port "
        if [ $? -eq 0 ]; then
            error "port: $port " check failed
            failed_ports="$failed_ports $port"
        else
            success_ports="$success_ports $port"
        fi
    done
    if [ x"$success_port"  != x ]; then
        infolog "check ports: $success_ports success"
    fi
    if [ x"$failed_ports" != "x" ]; then
        error "check ports:$failed_ports failed"
        exit -1
    fi
}

function check_memory()
{
    size=$1
    num_value=`expr ${size} \* 1024 \* 1024 - 500000`
    now_size=`cat /proc/meminfo | grep -i MemTotal | awk -F':' '{print $2}' | sed 's/  \+//g' | awk '{print $1}'`
    if [ $now_size -gt $num_value ]; then
       infolog "check memory size is large than $size G"
    else
        error "current machine's memory is $now_size kB, it's better large than ${size}G"
        exit -1
    fi
}

function check_disk()
{
    size=$1
    real_size=`expr $size \* 1024 \* 1024`
    result=$(df -Pk)
    flag=0
    echo $result | grep '/data' 1>/dev/null 2>&1
    if [ $? -eq 0 ]; then
        result_size=$(echo "$result" | grep -w '/data' | awk '{print $4}')
        if [ $result_size -gt $real_size ]; then
            infolog "check disk size success."
        else
            flag=1
        fi
    else
         result_size=$(echo "$result" | grep -w '/' | awk '{print $4}')
         if [ $result_size -gt $real_size ]; then
             infolog "check disk size success."
         else
             flag=1
         fi
    fi
    if [ $flag -eq 1 ]; then
        error "Warings: current machine's disk is not enough, it's better large than ${size}G in dir / or /data."
        exit -1
    fi
}


ports="2181 2424 2480 26379 27017 3000 3306 5511 5513 5672 6379 6627 6666 6700 80 8060 8061 8062 8063 8081 8082 8083 8084 8085 8086 8087 8089 8092 8093 8094 8096 8820 9092 9201"
main()
{
    mem_limit=$1
    disk_limit=$2

    #check os 64 bit is ok
    check_os_version
    #umask 022
    check_umask
    #nc
    check_nc
    #memory size
    check_memory ${mem_limit}
    #disk size
    check_disk ${disk_limit}
    #os port 
    check_platform_ports "$ports"
}

mem_limit=$1
disk_limit=$2
##execute main function
main ${mem_limit} ${disk_limit}
