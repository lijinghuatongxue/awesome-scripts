#!/bin/bash

print_usage() {
  echo "Usage:"
  echo "    ./change_pkg_org_license.sh -o [org] -l [license_path] pkg_path   对pkg_path路径所在的包设置org或license."
  exit 0
}

# Parse options to the `start.sh` command
while getopts "ho:l:" opt; do
  case ${opt} in
    h )
      print_usage
      ;;
    o )
      org=$OPTARG
      ;;
    l )
      license=$OPTARG
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))

pkg_path=$1
if [[ ${pkg_path}X == X ]]; then
    echo "pkg_path必须传入"
    print_usage
fi

if [[ ! -f ${pkg_path} ]]; then
    echo "${pkg_path}不存在"
    exit 1
fi

if [[ ${org}X == X && ${license}X == X ]]; then
    echo "org和license两个参数必须使用至少一个!"
    print_usage
fi

if [[ ${license}X != X && ! -f ${license} ]]; then
    echo "license路径 ${license} 不存在"
    exit 1
fi

set -e

pkg_dir=$(dirname $pkg_path)
pkg_name=$(basename $pkg_path)
pkg_basename=$(basename $pkg_name .tar.gz)
pkg_org=$(echo ${pkg_basename} | awk -F '-' '{print $3}')

set +e 

if [[ ${pkg_org}X == X ]]; then
    echo "传入压缩包的文件名格式不符合规范，应该为easyops-private-[org]-[ts].tar.gz"
    exit 1
fi

set -e
cd $pkg_dir
echo "正在解压包"
tar -zxf $pkg_name
set +e 

if [[ ${license}X != X ]]; then
    /bin/cp -f ${license} ./${pkg_basename}/conf/license.lic
fi

if [[ ${org}X != X ]]; then
    echo '{"org": '${org}'}' > ./${pkg_basename}/data/org.json
    pkg_org=${org}
fi

set -e
ts=$(date +%s)
new_pkgname="easyops-private-${pkg_org}-${ts}.tar.gz"
new_pkgbasename="easyops-private-${pkg_org}-${ts}"
mv ${pkg_basename} ${new_pkgbasename}

echo "替换完成，正在打包"
tar -zcf ${new_pkgname} ${new_pkgbasename}
rm -rf ${new_pkgbasename}
echo "替换成功！新的部署包路径：${pkg_dir}/${new_pkgname}"

