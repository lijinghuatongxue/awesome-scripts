#!/bin/bash
# Name    : start_script.py
# Date    : 2016.03.28
# Func    : 启动脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
set -e

# 用户自定义
app_folder="ucpro"                 # 项目根目录

install_base="/usr/local/"       # 安装根目录

# 执行准备
install_path="${install_base}/${app_folder}/"
if [[ ! -d ${install_path} ]]; then
    echo "${install_path} is not exist"
    exit 1
fi

cd ${install_path}
./bin/stop.sh

./bin/start.sh
