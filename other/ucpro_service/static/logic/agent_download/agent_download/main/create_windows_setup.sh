#!/bin/bash

curr_folder=$(dirname $(which $0))
setup_base="/tmp/windows_tmp/easyops"
[[ -d "$setup_base" ]] && rm -rf $setup_base
mkdir -p $setup_base

env_config="/usr/local/easyops/deploy_init/env.config"
if [[ ! -f $env_config ]]; then
    echo "not found $env_config, please check"
    exit 1
fi

source /usr/local/easyops/deploy_init/env.config

if [[ ${inner_ip}"X" == "X" || ${inner_ip} == "127.0.0.1" ]]; then
    echo "not found inner_ip in env.confg or inner_ip is 127.0.0.1, exit"
fi

file_list="agent.zip python_windows.zip daemon_windows.zip"
for filename in $(echo $file_list)
do
    echo "extract $filename..."
    cp -rf $curr_folder/$filename $setup_base
    if [[ $? -ne 0 ]]; then
        echo "copy $filename error, please check"
        exit 1
    fi
    cd $setup_base && unzip $filename > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        echo "unzip $filename error, please check"
    fi
    cd $setup_base && rm -f $filename
done


cd $setup_base
# 预置配置处理
sed -i "s/__SERVERIP__/${inner_ip}/g" "./agent/easyAgent/conf/conf.yaml"
sed -i "s/__ORGID__/${org}/g" "./agent/easyAgent/conf/conf.yaml"
mkdir -p ./agent/easyAgent/log
mkdir -p ./agent/collector_agent/log
mkdir -p ./agent/collector_agent/data
mkdir -p ./agent/collector_agent/data/user_log_collector
mkdir -p ./agent/collector_agent/data/user_log_collector/user_log
mkdir -p ./agent/collector_agent/data/user_log_collector/record
mkdir -p ./agent/easy_collector/log

cd $setup_base
echo ".\daemon\DaemonSvc.exe start" > start.bat
echo ".\daemon\DaemonSvc.exe stop" > stop.bat
echo ".\daemon\DaemonSvc.exe install" > install.bat
cat << EOF > README.txt
##############################

1. 从 http://${inner_ip}/agent_windows_full.zip 下载，并拷贝到目标windows机器，并将里面的easyops目录解压到c:\\
2. 目录结构应该是：c:\\easyops\\agent,c:\\easyops\\python,c:\\easyops\\daemon
3. 双击install.bat
4. 双击start.bat
5. 请检查主机管理页面，该主机应该就已经注册
6. 如果没有，请检查任务管理器中是否有DaemonSvc.exe和两个python进程，请联系Easyops

##############################
EOF



cd $setup_base && cd ..
zip -r agent_windows_full.zip easyops > /dev/null 2>&1
mv agent_windows_full.zip $curr_folder

echo ""
printf "已经生成了windows agent免安装包（\033[32m ./agent_windows_full.zip \033[0m），请按如下指引安装windows agent\n"
cat $setup_base/README.txt
rm -rf $setup_base


