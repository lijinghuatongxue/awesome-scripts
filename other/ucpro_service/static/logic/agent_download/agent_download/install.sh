#!/bin/sh
cur_path=$(dirname $(which $0))
if [ $# -lt 4 ];then
    echo "usage install_path app_name version auto_start"
    exit 1
fi
install_path=$1
app_name=$2
version=$3
auto_start=$4
# python组件做特殊处理
if [[ $app_name =~ ^python.* ]];then
    mkdir -p ${install_path}
    cp -rf $cur_path/main/* ${install_path}
    echo "###code=0&msg=ok###"
    exit 0
fi
# 其他组件安装之前必须要有python
if [[ ! $app_name =~ ^python.* ]] && [[ ! -f /usr/local/easyops/python/bin/python ]];then
    echo "python not find "
    exit 2
fi

if [[ -d ${install_path} ]];then
    mv ${install_path} ${install_path}.`date +%Y%m%d%H%M%S`
    [[ "${app_name}" != "" ]] && rm -fr /usr/local/easyops/pkg/conf/${app_name}
fi
/usr/local/easyops/python/bin/python $cur_path/install.py --installPath=${install_path} --packageId=${app_name} --versionName=${version} --versionId=${version}  --withConfig=false --autoStart=${auto_start}

