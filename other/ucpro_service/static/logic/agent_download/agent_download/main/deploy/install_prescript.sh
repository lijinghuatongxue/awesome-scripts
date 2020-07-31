#!/bin/bash
# Name    : install_prescript.py
# Date    : 2016.03.28
# Func    : 安装前脚本
# Note    : 注意：当前路径非应用部署文件夹，注意相对路径

#############################################################
# 检查相关依赖组件是否已安装
install_base="/usr/local/easyops"      # 安装根目录

# nginx
if [ ! -d ${install_base}/nginx ];then
    echo "nginx not exists"
    exit 2
fi

if [ ! -d ${install_base}/ens_client ];then
    echo "ens_client not exists"
    exit 2
fi
