#!/bin/bash

cluster_type="private"
download_host="download.easyops-only.com"

# load config
source ./proxy_config.sh

which easyops > /dev/null 2>&1
if [[ $? -ne 0 ]]; then
    echo "you shoud install agent or upgrade agent first"
    exit 1
fi

# nginx 4 layer proxy
RED="\033[31m"  # RED
GRE="\033[32m"  # GREEN
DEF="\033[0m"   # DEFAULT

basedir="/usr/local/easyops"
mkdir -p $basedir

id easyops || useradd easyops -s /sbin/nologin
[[ $? -ne 0 ]] && echo "创建easyops用户失败，请手动创建easyops用户后，再尝试"


function main() {
    cd ${basedir}
    printf "downloading nginx_proxy.tar.gz ...\n"

    is_download=false
    all_server_ip=$(echo ${server_ip} |tr "," "\n")
    for each_server_ip in ${all_server_ip}
    do
        if [[ "$cluster_type" == "private" ]]; then
            curl --retry 2 --connect-timeout 60 --output ${basedir}/proxy.tar.gz --header "Host:${download_host}" http://${each_server_ip}/proxy.tar.gz
        else
            curl --retry 2 --connect-timeout 60 --output ${basedir}/proxy.tar.gz --header "Host:${download_host}" http://${download_host}/proxy.tar.gz
        fi

        if [[ $? -ne 0 ]]; then
            printf "${RED}download proxy.tar.gz failed. \033[m\n"
            continue
        else
            is_download=true
            break
        fi
    done

    [[ ${is_download} == "false" ]] && echo "download proxy.tar.gz failed" && exit 1

    printf "download proxy.tar.gz success\n"
    printf "decompressing proxy.tar.gz to ${basedir}/nginx ...\n"
    tar -zxf proxy.tar.gz
    printf "decompress proxy.tar.gz success\n"

    space="\ \ \ \ \ \ \ "
    for each_server_ip in ${all_server_ip}
    do
        for each_port in 5511 8820 80 443
        do
            sed -i "/__SERVERIP__:${each_port}/a  ${space} server ${each_server_ip}:${each_port};" "${basedir}/nginx/conf/nginx.conf"
        done
    done
    sed -i '/__SERVERIP__/d' "${basedir}/nginx/conf/nginx.conf"

    printf "starting nginx ...\n"
    cd ${basedir}/nginx/
    easyops init && easyops restart --debug
    if [[ $? -eq 0 ]]; then
        printf "\n${GRE}Install nginx SUCCESS! Now you can install agent following by help document\033[m\n"
    else
        printf "\n${RED}Something wrong, please contact with easyops\033[m\n"
    fi
}

main
