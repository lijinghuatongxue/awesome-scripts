#!/bin/bash
# Name    : install_postscript.py
# Date    : 2016.03.28
# Func    : 停止脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
app_folder="nginx"                 # 项目名称
install_base="/usr/local/easyops"       # 安装根目录
install_path="${install_base}/${app_folder}/"


#############################################################

# 替换nginx 配置
[[ -f /usr/local/easyops/nginx/conf/conf.d/cmdb_resource.conf ]] && mv -f /usr/local/easyops/nginx/conf/conf.d/cmdb_resource.conf /usr/local/easyops/nginx/conf/conf.d/cmdb_resource.conf.bak
cp -f /usr/local/easyops/nginx/deploy/cmdb_service.conf /usr/local/easyops/nginx/conf/conf.d/cmdb_resource.conf

