#!/bin/bash
# Name    : start_script.py
# Date    : 2016.03.28
# Func    : 启动脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 初始化环境

# 用户自定义
app_folder="ucpro_service"                 # 项目根目录
process_name="ucpro_service"       # 进程名

install_base="/usr/local/easyops"       # 安装根目录
data_base="/data/easyops"             # 日志/数据根目录

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

# 日志目录
log_path="${data_base}/${app_folder}/log"
mkdir -p ${log_path}
cd ${install_path} && ln -snf ${log_path} log

# 数据目录
data_path="${data_base}/${app_folder}/data"
mkdir -p ${data_path}
cd ${install_path} && ln -snf ${data_path} data

if [[ ! -f ${install_path}/data/org.json ]]; then
    echo '{"org": 0}' > ${install_path}/data/org.json
fi

#############################################################

# 启动程序
echo "start by cmd: ${start_cmd}"
cd ${install_path} && eval "${start_cmd}"
if [[ $? -ne 0 ]];then
    echo "start error, exit"
    exit 1
fi
#############################################################