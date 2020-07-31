#!/bin/bash
# Name    : start_script.py
# Date    : 2016.03.28
# Func    : 启动脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 初始化环境

# 用户自定义
app_folder="ucpro"                 # 项目根目录

install_base="/usr/local/"       # 安装根目录

# 启动命令
start_cmd="./bin/ucpro_service > /dev/null 2>log/${app_folder}.err &"


#############################################################
# 通用前置
# ulimit 设定
ulimit -n 10000

# 执行准备
install_path="${install_base}/${app_folder}/"
if [[ ! -d ${install_path} ]]; then
    echo "${install_path} is not exist"
    exit 1
fi

#############################################################

cd ${install_path}

# 启动程序
ln -snf ${install_path}/log ${install_path}/nginx/log
ln -snf ${install_path}/log ${install_path}/nginx/logs
ln -snf ${install_path}/log ${install_path}/ucpro_service/log

if [[ ! -f ${install_path}/ucpro_service/data/org.json ]]; then
    echo '{"org": 0}' > ${install_path}/ucpro_service/data/org.json
fi
         
# 启动nginx
cd ${install_path}/nginx
./sbin/nginx -c ./conf/nginx.conf -p `pwd`
      
# 启动ucpro_service
echo "start by cmd: ${start_cmd}"
cd ${install_path}/ucpro_service && eval "${start_cmd}"
if [[ $? -ne 0 ]]; then
    echo "start error, exit" 
    exit 1
fi  
    
#############################################################
