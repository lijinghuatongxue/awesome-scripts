#!/bin/bash
# Name    : install_postscript.py
# Date    : 2016.03.28
# Func    : 安装后脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
app_folder="agent_download"             # 项目根目录
install_base="/usr/local/easyops"      # 安装根目录
download_folder="/data/easyops/fileDownload" # Agent安装包存放位置

install_path="${install_base}/${app_folder}"

# 注册的服务名，多个用空格隔开
ens_names="web.gateway"
ens_port=5511

#############################################################
# 通用前置，加载全局变量
source ${install_base}/deploy_init/env.config

# 执行准备
if [[ ! -d ${install_path} ]]; then
    echo "${install_path} is not exist"
    exit 1
fi

[[ ! -d ${download_folder} ]] && mkdir -p ${download_folder}/ && chown easyops:easyops ${download_folder}/

# link all files to /data/easyops/fileDownload
ln -snf ${install_path}/* ${download_folder}/

cd $download_folder

# 新增agent版本文件
# echo ${version} > /data/easyops/fileDownload/version
# 暂不启动自动升级
echo "" > ${download_folder}/version

# 注册名字服务，注册失败直接退出，不启动程序。确保进程启动时候名字是有注册的
for name in $(echo $ens_names)
do
    ${install_base}/ens_client/tools/register_service.py $name $ens_port ${inner_ip}
    if [[ $? -ne 0 ]];then
        echo "register name error, exit"
        exit 255
    fi
done


