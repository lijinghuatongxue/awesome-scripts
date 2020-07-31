#!/bin/bash

# Desc: single component update script
# Version: 1.0.0
# Date: 2016-12-01 18:15:07
# Author: Turing Chu

# error 1: 缺少参数
# error 2: easyops命令未找到
# error 3: 停止服务失败
# error 4: 执行升级前置脚本失败
# error 5: 执行升级后置脚本失败
# error 6: 升级后重启失败

basedir=/usr/local/easyops
datadir=/data/easyops
backupdir=/tmp/easyops_backup
cur_path=$(dirname $(which $0))



function print_help() {
    cat <<EOF
Usage: $0 app_name install_path [options]

[options]
    --not_backup    是否备份, 默认备份于/tmp/easyops_backup下面
    --not_prestop   升级前是否停止, 默认停止
    --not_restart   升级后是否重启, 默认重启
EOF
}

# arg 1: 错误码
# arg 2: 错误信息
function echo_error() {
    printf "[ \033[31mERROR $1 \033[0m] $2\n"
}

function parse_arg() {
    app_name=$1
    install_path=$2
    not_backup=false  # 默认备份
    not_prestop=false  # 默认停止
    not_restart=false  # 默认重启
    arg=$*
    for arg do
        case "$arg" in
            --not_backup)
                not_backup=true
            ;;
            --not_prestop)
                not_prestop=true
            ;;
            --not_restart)
                not_restart=true
            ;;
        esac
    done
}


# arg 1: app_name
# arg 2: install_path
# 暂不做参数异常情况处理
function backup() {
    local app_folder=$(basename $2)
    if [ "${not_prestop}" == "false" ];then
        easyops stop $2
        if [ $? -ne 0 ];then
            echo_error 3 "备份前停止服务失败,备份失败"
            exit 3
        fi
    fi
    
    mkdir -p $backupdir
    local curdir=$(pwd)
    cd $basedir
    curtime=$(date "+%Y%m%d%H%M%S")
    # backup src  dir
    echo "备份 $1 源码文件夹"
    local src_backup="${1}.src.${curtime}"
    rsync -a --exclude='log' --exclude='src/log' --exclude='logs' ${basedir}/${app_folder}/* $backupdir/$src_backup/
    cd $backupdir
    tar zcf $src_backup.tar.gz $src_backup
    rm -fr $src_backup
    echo "备份 $1 源码文件夹成功"
    # backup data dir
    echo "备份 $1 数据文件夹"
    cd $datadir
    if [ ! -d $1 ];then
        echo "数据文件夹不存在 不予备份数据文件夹"
        if [ "${not_prestop}" == "true" ];then
            easyops 'restart' $2
        fi
        return 0
    fi
    local data_backup="${1}.data.${curtime}"
    rsync -a --exclude='log' --exclude='src/log' --exclude='logs' ${datadir}/${app_folder}/* $backupdir/$data_backup/
    cd $backupdir
    tar zcf ${data_backup}.tar.gz $data_backup
    rm -fr $data_backup
    echo "备份 $1 数据文件夹成功"
    cd $curdir
}

# 升级前执行的脚本
function preexecute() {
    echo "$app_name: 执行升级前置脚本"
    if [ ! -f "$cur_path/main/deploy/update_prescript.sh" ];then
        echo "升级前置脚本不存在，不予执行"
        return 0
    fi
    local user=$(cat $cur_path/main/package.conf.yaml |grep -E "^user"|grep -oE "[0-9a-zA-Z]+"|grep -v user|uniq)
    [[ -z "${user}" ]] && local user="root"
    cp -f "$cur_path/main/deploy/update_prescript.sh" "${install_path}/deploy/"
    #bash $install_path/deploy/update_prescript.sh
    
    su --shell="/bin/bash" - "${user}" --command="cd $install_path;bash ${install_path}/deploy/update_prescript.sh"
    if [ $? -ne 0 ];then
        echo_error 4 "执行前置脚本失败"
        cd $cur_path
        exit 4
    fi
    cd $cur_path
}


# 升级后执行的脚本
function postexecute() {
    echo "$app_name: 执行升级后置脚本"
    if [ ! -f "$cur_path/main/deploy/update_postscript.sh" ];then
        echo "升级前置脚本不存在，不予执行"
        return 0
    fi
    local user=$(cat $cur_path/main/package.conf.yaml |grep -E "^user"|grep -oE "[0-9a-zA-Z]+"|grep -v user|uniq)
    [[ -z "${user}" ]] && local user="root"
    cp -f "$cur_path/main/deploy/update_postscript.sh" "${install_path}/deploy/"
    # TODO 执行后置脚本请按package.conf.yaml中的用户执行,2.18.1添加用户导致data中文件为root启动时无权限而失败
    
    su --shell="/bin/bash" - "${user}" --command="cd $install_path;bash $install_path/deploy/update_postscript.sh"
    #bash $install_path/deploy/update_postscript.sh
    if [ $? -ne 0 ];then
        echo_error 5 "执行升级后脚本失败"
        cd $cur_path
        exit 5
    fi
    cd $cur_path
}


function update() {
    preexecute
    cp -fr ${cur_path}/main/* ${install_path}/
    chown -R easyops:easyops ${install_path}/*
    postexecute
    easyops init ${install_path}
    if [ "${not_restart}" == "false" ];then
        easyops 'restart' ${install_path}
        if [ $? -ne 0 ];then
            echo_error 6 "文件更新成功，升级后重启失败, 请手动重启解决"
            exit 6
        fi
    fi
    echo "升级成功"
}

# 此处考虑到后续有新增组件的情况 目前尚未遇到 暂不处理 因为急着用
function install() {
    echo "install"
}

function version_diff() {
    local pre_ver_file="${install_path}/version.ini"
    local cur_ver_file="${cur_path}/main/version.ini"
    if [ ! -f  ${pre_ver_file} ];then
        echo "未找到version.ini文件, 将进行强制升级" 
        local pre_ver=""
    else
        local pre_ver=$(cat ${install_path}/version.ini |head -2|tail -1)
    fi
    local cur_ver=$(cat ${cur_path}/main/version.ini |head -2|tail -1)
    if [ "${pre_ver}" == "" -o "${pre_ver}" != "${cur_ver}" ];then
        return 0
    else
        return 1
    fi
}

function main() {
    if [ $# -lt 2 ];then
        echo_error 1 "缺少参数"
        print_help
        exit 1
    fi
    which easyops >> /dev/null 2>&1
    if [ $? -ne 0 ];then
        echo_error 2 "easyops 命令未找到"
        exit 2
    fi
    parse_arg $*
    if [ ! -d "$install_path" ];then
        echo "安装目录不存在，请确认安装目录是否正确，按Ctrl+C退出重新修改安装目录，或按y进行安装操作"
        echo "这里进行安装操作"
        exit 0
    fi
    version_diff
    if [ $? != 0 ];then
        echo "当前升级包版本和部署版本一致，不进行升级操作"
        return 0
    fi

    if [ "${not_backup}" == "false" ];then
        echo "备份"
        backup "${app_name}" "${install_path}"
    fi
    update "${app_name}" "${install_path}"
}


#### main ####
main $*
#### main ####
