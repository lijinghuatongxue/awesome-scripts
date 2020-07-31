#!/bin/bash
# Name    : start_script.py
# Date    : 2016.03.28
# Func    : 启动脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
app_folder="mysql"                 # 项目根目录
process_name="mysqld"               # 进程名

install_base="/usr/local/easyops"   # 安装根目录
data_base="/data/easyops"           # 日志/数据根目录

# 启动命令
start_cmd="./bin/mysqld_safe --defaults-file=./etc/my.cnf --user=easyops >/dev/null 2>log/${app_folder}.err &"
# 基于easy_framework的启动方式
# start_cmd="/usr/local/easyops/easy_framework/easy_service.py conf/client.yaml start"

#############################################################
# 通用前置
# ulimit 设定
ulimit -n 100000

# 执行准备
install_path="${install_base}/${app_folder}/"
if [[ ! -d ${install_path} ]]; then
    echo "${install_path} is not exist"
    exit 1
fi

export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${install_path}/lib64

# 日志目录
log_path="${data_base}/${app_folder}/log"
mkdir -p ${log_path}
cd ${install_path} && ln -snf ${log_path} log

# 数据目录
data_path="${data_base}/${app_folder}/data"
mkdir -p ${data_path}
cd ${install_path} && ln -snf ${data_path} data

data_path="${data_base}/${app_folder}/binlog"
mkdir -p ${data_path}
cd ${install_path} && ln -snf ${data_path} binlog

data_path="${data_base}/${app_folder}/run"
mkdir -p ${data_path}
cd ${install_path} && ln -snf ${data_path} run


# 启动程序
###############################################################################
echo "start by cmd: ${start_cmd}"
cd ${install_path}

./bin/mysqld_safe --defaults-file=./etc/my.cnf --user=easyops >/dev/null 2>log/${app_folder}.err & # 5.6的版本 切后台只能这样(我有点不信)

