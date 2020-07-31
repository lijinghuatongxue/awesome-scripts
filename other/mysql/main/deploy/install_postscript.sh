#!/bin/bash
# Name    : install_postscript.py
# Date    : 2018.02.23
# Func    : 安装后置脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
set -eux -o pipefail

# 用户自定义
app_folder="mysql"                 # 项目名称
install_base="/usr/local/easyops"       # 安装根目录
data_base="/data/easyops"               # 日志/数据根目录
install_path="${install_base}/${app_folder}"
get_env=${install_base}/deploy_init/tools/get_env.py   # get easy_env.ini tools

local_ip=$(${get_env} common local_ip)

# mysql 组件安装后置脚本:
#   更新 ./etc/my.cnf 中的 server_id
#   创建 data 目录和软链
#   初始化db
function main {
    write_server_id
    install_dirs
    install_db
    fix_auto_cnf
}

# 修改 server-id. master 为 1, slave 为 11, 12, 13, ...
function write_server_id {
    echo 'write_server_id'
    local master_ip=$(${get_env} mysql master)
    if [[ "$master_ip" == "$local_ip" ]]; then
        sed -i "s@server-id=.*@server-id=1@" ${install_path}/etc/my.cnf
        return 0
    fi

    local slave_ip
    local server_id
    set +e
    for n in {1..100}
    do
        slave_ip=$(${get_env} mysql node.${n})
        [[ $? -ne 0 ]] && break
        [[ "$slave_ip" == "$master_ip" ]] && continue
        [[ "$slave_ip" != "$local_ip" ]] && continue
        server_id=$(($n+10))
        sed -i "s@server-id=.*@server-id=${server_id}@" ${install_path}/etc/my.cnf
    done
    set -e
}

function install_dirs {
    echo 'install_dirs'
    local links=('binlog' 'data' 'log' 'run')
    for lnk in "${links[@]}"
    do
        data_path="${data_base}/${app_folder}/${lnk}"
        mkdir -p ${data_path}
        cd "$install_path" && ln -snf "$data_path" "$lnk"
    done
}

function install_db {
    echo 'install_db'
    cd "$install_path"
    # cp -rf db/* /data/easyops/mysql/data/
    tar -xf "$install_path/db.tar.gz" -C "$data_base/$app_folder/data"
}

# Fix INSTALLPKG-106
function fix_auto_cnf() {
    if grep 'server-uuid=c57ae5e4-afa7-11e6-8c47-aaf3372c2994' "$data_base/$app_folder/data/auto.cnf" ; then
        rm -fv "$data_base/$app_folder/data/auto.cnf"
    fi
}

main
