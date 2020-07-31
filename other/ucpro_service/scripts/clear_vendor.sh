#!/usr/bin/env bash
easyops_base="/usr/local/easyops/"
vendor_list="console/_opcache/src/vendor/
cmdb_resource/_opcache/src/lib/vendor
jobservice/_opcache/src/vendor
graph/_opcache/src/lib/vendor
deploy/_opcache/src/vendor
autodiscovery/_opcache/src/lib/vendor
system_settings/_opcache/src/lib/vendor
notify/_opcache/src/vendor
deploy_repository/_opcache/src/vendor
cmdb/_opcache/src/lib/vendor
tools/_opcache/src/vendor"
list=$(echo ${vendor_list})
cd ${easyops_base}
for p in ${list}
do
    # 再次确认
    echo ${p} |grep '_opcache'|grep 'vendor'
    if [ $? -ne 0 ];then
        continue
    fi
    if [ -d ${p} ];then
        component=$(echo ${p} |awk -F '/' '{print $1}')
        mkdir -p "/tmp/vendor_deleted"
        mv ${p} "/tmp/vendor_deleted/"${component}.$(date +%s).$RANDOM
    fi
done

if [[ -d /usr/local/easyops/php ]]; then
    easyops restart /usr/local/easyops/php
fi

exit 0
