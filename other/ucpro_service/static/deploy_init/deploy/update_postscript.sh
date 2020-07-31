#!/bin/bash

# translate old env file to new easy_env

new_easy_env=easy_env.ini

# just upgrade when first time
if [[ ! -f ${new_easy_env} ]]; then
    bash ./tools/env2easy_env.sh
    if [[ $? != 0 ]]; then
        rm -f ${new_easy_env}
        exit 255
    fi
fi

cd /usr/local/easyops/deploy_init
/usr/local/easyops/python/bin/python ./tools/update_easy_env.py
[[ $? -ne 0 ]] && echo "udpate easy env error" && exit 255

# set grafana password encode
/usr/local/easyops/deploy_init/tools/get_env.py grafana encode
if [[ $? -ne 0 ]]; then
    /usr/local/easyops/deploy_init/tools/set_env.py grafana encode false
fi

# set edition
/usr/local/easyops/deploy_init/tools/get_env.py common edition
if [[ $? -eq 2 ]]; then
    /usr/local/easyops/deploy_init/tools/set_env.py common edition enterprise
fi

exit 0
