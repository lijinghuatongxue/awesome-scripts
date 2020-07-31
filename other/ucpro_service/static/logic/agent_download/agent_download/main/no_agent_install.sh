#!/bin/bash

cluster_type="private"
download_host="download.easyops-only.com"

# 支持从命令行获得参数
org=$1
server_ip=$2
install_base=$3

echo "start to install..."
if [ -z ${install_base} ]; then
    install_base="/usr/local/easyops"
else
    install_base=${install_base}"/easyops"
fi

[[ ! -d "${install_base}" ]] && mkdir -p ${install_base}
cd ${install_base}
if [[ $? -ne 0 ]]; then
    echo "not found and can not create ${install_base}, exit"
    exit 1
fi


# check para
[[ "${proxy_ip}X" != "X" ]] && server_ip="${proxy_ip}"
if [[ "${server_ip}X" == "X" || "${org}X" == "X" ]]; then
    echo "not found server_ip or org in environment variable"
    echo "Example: $0 org server_ip "
    exit 1
fi

aix_flag="false"
uname -a|grep -i aix 
if [ $? -eq 0 ];then
    python_pkg="python_aix.tar"
    agent_pkg="agent.tar"
    thirdLibs_pkg="thirdLibs.tar"
    aix_flag="true"
else
    is_64=$(uname -m |tr "X" "x")
    if [[ ${is_64} != "x86_64" ]]; then
        echo "only support 64 bit os system, exit"
        exit 1
    fi
    python_pkg="python_linux.tar.gz"
    agent_pkg="agent.tar.gz"
    thirdLibs_pkg="thirdLibs.tar.gz"
fi
curl_cmd=`which curl`
wget_cmd=`which wget`

echo "start to download..."
rm -rf ${install_base}/${agent_pkg}
rm -rf ${install_base}/${python_pkg}
if [ "${curl_cmd}" != "" ];then
    ${curl_cmd} -L --output ${install_base}/${agent_pkg} --connect-timeout 60 --retry 2 --header "Host:${download_host}" http://${server_ip}/${agent_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${agent_pkg}, exit"
        exit 1
    fi
    ${curl_cmd} -L --output ${install_base}/${python_pkg} --connect-timeout 180 --retry 2 --header "Host:${download_host}" http://${server_ip}/${python_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${python_pkg}, exit"
        exit 1
    fi
    ${curl_cmd} -L --output ${install_base}/${thirdLibs_pkg}  --connect-timeout 180 --retry 2 --header "Host:${download_host}" http://${server_ip}/${thirdLibs_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${thirdLibs_pkg}, exit"
        exit 1
    fi
elif [ "${wget_cmd}" != "" ];then
    ${wget_cmd} --output-document=${install_base}/${agent_pkg} --timeout=60 --tries=2 --header="Host:${download_host}" http://${server_ip}/${agent_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${agent_pkg}, exit"
        exit 1
    fi
    ${wget_cmd} --output-document=${install_base}/${python_pkg} --timeout=600 --tries=2 --header="Host:${download_host}" http://${server_ip}/${python_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${python_pkg}, exit"
        exit 1
    fi
    ${wget_cmd} --output-document=${install_base}/${thirdLibs_pkg} --timeout=600 --tries=2 --header="Host:${download_host}" http://${server_ip}/${thirdLibs_pkg}
    if [[ $? -ne 0 ]]; then
        echo "failed to download ${thirdLibs_pkg}, exit"
        exit 1
    fi
fi


# 检测下载包完整性
tar -tf ${install_base}/${agent_pkg} > /dev/null
[[ $? -ne 0 ]] && echo "download agent failed, please retry or contact with easyops" && exit 1

tar -tf ${install_base}/${python_pkg} > /dev/null
[[ $? -ne 0 ]] && echo "download ${python_pkg} failed, please retry or contact with easyops" && exit 1



# install & run
cd ${install_base}
[[ ! -d agent ]] && mkdir agent
[[ ! -d python ]] && mkdir python
[[ ! -d agent/thirdLibs ]] && mkdir agent/thirdLibs
if [ ${aix_flag} = "true" ];then
    tar -xf ${python_pkg}
    [[ $? -ne 0 ]] && echo "decompress ${python_pkg} error, please retry or contact with easyops" && exit 1
    tar -xf ${agent_pkg} 
    [[ $? -ne 0 ]] && echo "decompress ${agent} error, please retry or contact with easyops" && exit 1
    tar -xf ${thirdLibs_pkg}
    [[ $? -ne 0 ]] && echo "decompress ${thirdLibs} error, please retry or contact with easyops" && exit 1
    cp -rf thirdLibs/* python/lib/python2.7/site-packages/
else
    tar -xf ${python_pkg} -C python --strip-components 1
    [[ $? -ne 0 ]] && echo "decompress ${python_pkg} error, please retry or contact with easyops" && exit 1
    tar -xf ${agent_pkg} -C agent --strip-components 1
    [[ $? -ne 0 ]] && echo "decompress ${agent} error, please retry or contact with easyops" && exit 1
    #tar -xf ${thirdLibs_pkg} -C python/lib/python2.7/site-packages --strip-components 1
    #[[ $? -ne 0 ]] && echo "decompress ${thirdLibs} error, please retry or contact with easyops" && exit 1
fi
cd agent

sed  "s/__SERVERIP__/${server_ip}/g" "./easyAgent/conf/conf.yaml" > "conf.yaml.tmp"
mv "conf.yaml.tmp" "./easyAgent/conf/conf.yaml"
sed  "s/__ORGID__/${org}/g" "./easyAgent/conf/conf.yaml" > "conf.yaml.tmp"
mv "conf.yaml.tmp" "./easyAgent/conf/conf.yaml"
