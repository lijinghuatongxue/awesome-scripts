#!/bin/bash
# Name    : stop_script.py
# Date    : 2016.03.28
# Func    : 停止脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
process_name="ucpro_service"       # 进程名

cd nginx
./sbin/nginx -c ./conf/nginx.conf -p `pwd` -s stop

# 停止进程
if [[ "${process_name}x" != "x" ]]; then
    ps -ef | grep ${process_name} | grep -v grep | awk '{print $2}' | xargs kill -9
fi

exit 0
