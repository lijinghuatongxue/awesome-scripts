#!/bin/bash
# Name    : stop_script.py
# Date    : 2016.03.28
# Func    : 停止脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
process_name="mysqld"       # 进程名

# 注销的名字服务，多个用空格分隔
ens_names="dev.mysql.easyops-only.com data.mysql"
ens_port=3306
#############################################################

# # 注销名字服务，暂不注销名字
# source /usr/local/easyops/deploy_init/env.config
# master_ip=$(/usr/local/easyops/ens_client/tools/get_service.py config.mysql.master |awk '{print $2}')
# # master节点才注销名字
# if [[ $master_ip == $local_ip ]];then
#     for name in $(echo $ens_names)
#     do
#         /usr/local/easyops/ens_client/tools/unregister_service.py $name $ens_port
#         if [[ $? -ne 0 ]];then
#             echo "unregister name error, exit"
#             exit 255
#         fi
#     done
# fi

./bin/mysqladmin shutdown -h 127.0.0.1 > /dev/null 2>&1

sleep 3

ps -fC mysqld | grep "mysql/bin/mysqld" | awk '{print $2}' | xargs kill > /dev/null 2>&1

exit 0


