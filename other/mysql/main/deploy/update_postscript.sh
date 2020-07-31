#!/bin/bash
# Name    : update_postscript.py
# Date    : 2016.03.28
# Func    : 升级后脚本
# Note    : 注意：当前路径为应用部署文件夹
set -eu -o pipefail

#############################################################
app_folder="mysql"                 # 项目名称
install_base="/usr/local/easyops"       # 安装根目录
data_base="/data/easyops"               # 日志/数据根目录
install_path="${install_base}/${app_folder}"
#############################################################

restore_server_id() {
    # my.cnf.beforeupdate must exists
    local my_cnf_before="$install_path/etc/my.cnf.beforeupdate"
    local server_id_line="$( grep -x "server-id=[0-9]\{1,\}" "$my_cnf_before" )"
    local num_lines="$( grep -x "server-id=[0-9]\{1,\}" "$my_cnf_before" | wc -l )"
    if [ $num_lines -ne 1 ]; then
        echo "restore server id failed: unexpected lines: $server_id_line"
        exit 1
    fi

    echo "restore server id: $server_id_line"
    sed -i "s@server-id=.*@${server_id_line}@" ${install_path}/etc/my.cnf
}

restore_server_id
