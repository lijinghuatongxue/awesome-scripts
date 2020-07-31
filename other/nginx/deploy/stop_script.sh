#!/bin/bash
# Name    : stop_script.py
# Date    : 2016.03.28
# Func    : 停止脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
# 用户自定义
process_name="nginx"       # 进程名

# 停止进程
./sbin/nginx -s stop

