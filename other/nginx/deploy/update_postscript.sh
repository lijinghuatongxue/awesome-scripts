#!/bin/bash
# Name    : update_postscript.py
# Date    : 2016.03.28
# Func    : 升级后脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
[[ -d log && ! -L log ]] && mv log log.`date '+%Y%m%d%H%M%S'`
[[ -d logs && ! -L logs ]] && mv log log.`date '+%Y%m%d%H%M%S'`

exit 0
