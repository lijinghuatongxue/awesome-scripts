#!/bin/bash
#############################################################
set -eux -o pipefail

app_folder="mysql"                 # 项目名称
install_base="/usr/local/easyops"       # 安装根目录
data_base="/data/easyops"               # 日志/数据根目录
install_path="${install_base}/${app_folder}"
#############################################################

echo "backup my.cnf"
cp -av "$install_path/etc/my.cnf" "$install_path/etc/my.cnf.beforeupdate"
