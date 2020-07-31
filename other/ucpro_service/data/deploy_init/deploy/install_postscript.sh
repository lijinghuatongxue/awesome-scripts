#!/bin/bash
# Name    : install_postscript.py
# Date    : 2016.03.28
# Func    : 停止脚本
# Note    : 注意：当前路径为应用部署文件夹

#############################################################
cp -f ./easy_env.sample.ini ./easy_env.ini

cd /usr/local/easyops/deploy_init
/usr/local/easyops/python/bin/python ./tools/init_easy_env.py
[[ $? -ne 0 ]] && echo "init easy env error" && exit 255

# 兼容老的env_config, 后面版本删掉，不维护env_config了
/usr/local/easyops/python/bin/python ./tools/generate_env_config.py
[[ $? -ne 0 ]] && echo "generate env config error" && exit 255

exit 0
