#!/bin/bash
# Name    : start_script.py
# Date    : 2016.03.28
# Func    : 启动脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
app_folder="nginx"                 # 项目根目录
process_name="nginx"       # 进程名

# file_owner="easyops"                    # 文件属主
install_base="/usr/local/easyops"       # 安装根目录
data_base="/data/easyops"               # 日志/数据根目录

# 启动命令
start_cmd="./sbin/${process_name} -c conf/nginx.conf >/dev/null 2>log/${app_folder}.err &"

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

# 日志目录
log_path="${data_base}/${app_folder}/log"
mkdir -p ${log_path}
cd ${install_path} && ln -snf ${log_path} log
# nginx必须要有logs目录
cd ${install_path} && ln -snf log logs

chown -R easyops:easyops $log_path


# 启动程序
echo "start by cmd: ${start_cmd}"
cd ${install_path} && eval $start_cmd
if [[ $? -ne 0 ]];then
    echo "start error, exit"
    exit 1
fi
