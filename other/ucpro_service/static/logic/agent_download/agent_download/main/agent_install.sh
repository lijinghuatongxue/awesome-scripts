#!/bin/sh

# 支持从命令行获得参数
org=$1
proxy_ip=$2
tag=$3
install_base=$4

# 页面请求时，动态填入参数
# 下面注释不要删掉，在请求时填入，正则匹配
# 填入的参数:org,server_ip,proxy_ip,agent_pub,gateway_pub
# load config
# source ./proxy_config.sh

# sed需要utf-8编码,不然会出错
locale -a|egrep -i 'en_US.utf8|en_US.utf-8'
if [[ $? -eq 0 ]];then
    export LC_ALL=en_US.UTF-8
fi

default_install_base="/usr/local/easyops"
tmp_path="/tmp"
cluster_type="private"
download_host="download.easyops-only.com"
if [ -z "${install_base}" ]; then
    install_base="${default_install_base}"
else
    install_base="${install_base}/easyops"
fi
agent_base=${install_base}/agent
all_server_ip=

echo_step() {
    echo
    echo "**********************************************************"
    echo  $1
}

echo_error() {
    #printf "Error: \033[31m $1 \033[0m\n"
    printf "Error: $1 \n"
    echo
}

# 检查参数，初始化基本环境
env_init(){
    if [ ! -d ${agent_base} ]; then
        pkg_action="install"
    else
        pkg_action="upgrade"
    fi

    [ ! -d "${install_base}" ] && mkdir -p ${install_base}
    cd ${install_base}
    if [ $? -ne 0 ]; then
        echo_error "not found and can not create ${install_base}, exit"
        exit 1
    fi

    # check para
    [ "${proxy_ip}X" != "X" ] && server_ip="${proxy_ip}"
    if [ "${server_ip}X" = "X" -o "${org}X" = "X" ]; then
        echo_error "not found server_ip or org in environment variable"
        echo "Example: $0 org server_ip tag"
        exit 1
    fi

    echo "org: ${org}, server_ip: ${server_ip}, proxy_ip: ${proxy_ip}"
}


write_python2_script(){
cat > ${tmp_path}/easyops_download.py <<EOF
import sys
import urllib2
import os


def main():
    headers = {"host": host_header}
    request = urllib2.Request(url, headers=headers)
    response = urllib2.urlopen(request)
    content = response.read()
    try:
        f = open(os.path.join(install_base, package), "wb")
        f.write(content)
        f.close()
    except:
        print "download failed"
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print "usage: python %s  install_base host_header url package" % (sys.argv[0])
        sys.exit(1)
    install_base = sys.argv[1]
    host_header = sys.argv[2]
    url = sys.argv[3]
    package = sys.argv[4]
    main()
EOF

}

write_python3_script(){
cat > ${tmp_path}/easyops_download.py <<EOF
import sys
import urllib.request
import os


def main():
    headers = {"host": host_header}
    request = urllib.request.Request(url, headers=headers)
    response = urllib.request.urlopen(request)
    content = response.read()
    try:
        f = open(os.path.join(install_base, package), "wb")
        f.write(content)
        f.close()
    except:
        print("download failed")
        sys.exit(1)


if __name__ == '__main__':
    if len(sys.argv) < 5:
        print("usage: python %s  install_base host_header url package" % (sys.argv[0]))
        sys.exit(1)
    install_base = sys.argv[1]
    host_header = sys.argv[2]
    url = sys.argv[3]
    package = sys.argv[4]
    main()
EOF

}

write_perl_script(){
cat > ${tmp_path}/easyops_download.pl <<EOF
use HTTP::Response;
use LWP::UserAgent;

my \$ua = LWP::UserAgent->new;
my \$file_base = \$ARGV[0];
my \$host = \$ARGV[1];
my \$url = \$ARGV[2];
my \$filename = \$ARGV[3];

@header = (
  'host'=> \$host
);

\$request = HTTP::Request->new(GET=>"\$url");
\$request->header(@header);

\$filename = \$file_base."/".\$filename;

open my \$fh, ">", \$filename;
\$res = \$ua->request(\$request, sub {
    my (\$data, \$response, \$protocol) = @_;
    print \$fh \$data;
});
close \$fh;

EOF

}

do_download() {
    download_ip=$1
    dst_pkg=$2
    timeout=$3

    if [ "$method" = "curl" ];then
        if [ ${os} = "unix" ];then
            curl -L --output ${install_base}/${dst_pkg} --connect-timeout ${timeout}  --header "Host:${download_host}" http://${download_ip}/${dst_pkg}
        else
            curl -L --output ${install_base}/${dst_pkg} --connect-timeout ${timeout} --retry 2 --header "Host:${download_host}" http://${download_ip}/${dst_pkg}
        fi
    elif [ "$method" = "wget" ]; then
        wget -q -O ${install_base}/${dst_pkg} --header="Host:${download_host}" http://${download_ip}/${dst_pkg}
    elif [ "$method" = "python" ]; then
        python ${tmp_path}/easyops_download.py ${install_base} ${download_host} http://${download_ip}/${dst_pkg} ${dst_pkg}
    elif [ "$method" = "perl" ]; then
        perl ${tmp_path}/easyops_download.pl ${install_base} ${download_host} http://${download_ip}/${dst_pkg} ${dst_pkg}
    fi
}

get_download_method(){
    method=""
    # curl
    command -v curl > /dev/null 2>&1
    [ $? -eq 0 ] && method="curl"

    # wget
    if [ -z "${method}" ]; then
        command -v wget > /dev/null 2>&1
        [ $? -eq 0 ] && method="wget"
    fi

    # 部分unix系统上带python，但没python2二进制命令
    # python
    if [ -z "${method}" ]; then
        command -v python > /dev/null 2>&1
        if [ $? -eq 0 ];then
            method="python"
            version=`python --version 2>&1|awk '{print $2}'|awk -F. '{print $1}'`
            if [ "${version}" = "3" ];then
                write_python3_script
            else
                write_python2_script
            fi
        fi
    fi
    #perl
    if [ -z "${method}" ]; then
        command -v perl > /dev/null 2>&1
        if [ $? -eq 0 ];then
            method="perl"
            write_perl_script
        fi
    fi

    if [ -z "${method}" ]; then
        echo_error  "download method not found"
        exit 2
    fi
}


get_pkg_list(){
    # server的python
    if [ -f "${default_install_base}/etc/easyops.lic" ];then
        python_pkg="python_linux.tar.gz"
    else
        # agent的python
        arch=`uname -a|grep -i "x86_64"`
        if test "${arch}" != "";then
        	python_pkg="python_linux_agent.tar.gz"
        else
        	python_pkg="python_linux_agent_32.tar.gz"
        fi
    fi

    linux_flag=`uname -a |grep -i "linux"`
    aix_flag=`uname -a |grep -i "aix"`
    sun_flag=`uname -a |grep -i "SunOs"`
    hp_flag=`uname -a |grep -i "HP-UX"`
    if [ ! -z "${linux_flag}" ];then
        os="linux"
    	agent_pkg="agent.tar.gz"
    elif [ ! -z "${aix_flag}" -o ! -z "${sun_flag}" -o ! -z "${hp_flag}" ];then
        os="unix"
    	agent_pkg="agent_unix.tar.gz"
    else
        os="linux"
    	agent_pkg="agent.tar.gz"
    fi

    if [ "${os}" = "unix" ];then
        if [ ! -z "${aix_flag}" ];then
    	    python_pkg="python_aix.tar.gz"
    	else
    	    echo "no python2 environments,please install python2 first"
    	    exit 3
    	fi
    fi
    [ -f ${install_base}/${agent_pkg} ] && rm -rf ${install_base}/${agent_pkg}
    [ -f ${install_base}/${python_pkg} ] && rm -rf ${install_base}/${python_pkg}

    plugin_pkg="collector_plugins.tar.gz"
    [ -f ${install_base}/${plugin_pkg} ] && rm -rf ${install_base}/${plugin_pkg}
}

download_pkg(){
    server_addr=$1
    echo "agent: http://${server_addr}/${agent_pkg}"
    do_download ${server_addr} ${agent_pkg} 60
    if [ $? -ne 0 ]; then
        echo_error "failed to download ${agent_pkg}, exit"
        return 1
    fi

    echo "python: http://${server_addr}/${python_pkg}"
    do_download ${server_addr} ${python_pkg} 180
    if [ $? -ne 0 ]; then
        echo_error "failed to download ${python_pkg}, exit"
        return 1
    fi

    echo "plugins: http://${server_addr}/${plugin_pkg}"
    do_download ${server_addr} ${plugin_pkg} 60
    if [ $? -ne 0 ]; then
        echo_error "failed to download ${plugin_pkg}, exit"
        return 1
    fi
}

split_server_ip(){
if [ -z "${all_server_ip}" ]; then

    if [ ! -z "${aix_flag}" ];then
        IFS=","
        set -A all_server_ip ${server_ip}
    else
        all_server_ip=$(echo -e ${server_ip//,/\\n} | awk 'BEGIN{srand();}{print rand()" "$0}' | sort -k1 -n |awk '{print $2}')
    fi
fi
}

download_from_server(){
    # Traversal all server_ip
   echo "server_ip: ${server_ip}"
   if [ "$cluster_type" = "private" ]; then
        # aix下载
        if [ ! -z "${aix_flag}" ];then
            while :
            do
                len=${#all_server_ip[@]}
                if [ $len -lt "1" ]; then
                    break
                fi
                index=$(($RANDOM%$len))
                download_pkg ${all_server_ip[$index]}
                if [ $? -eq 0 ];then
                    is_success=0
                    break
                fi
                unset all_server_ip[$index]
                set -A all_server_ip ${all_server_ip[@]}
            done
            split_server_ip
        else
            # linux下载
            for ip in ${all_server_ip}
            do
                download_pkg $ip
                if [ $? -eq 0 ];then
                    is_success=0
                    break
                fi
            done
        fi
    else
        # 公网下载
        download_pkg ${download_host}
        if [ $? -ne 0 ];then
            is_success=1
        else
            is_success=0
        fi
    fi

    if [ ${is_success} -ne 0 ]; then
        echo_error "failed to download agent.tar.gz, exit"
        exit 1
    fi
    echo "download success"
}

untar(){
    tar_name=$1
    dst_name=$2
    if [ ${os} = "unix" ];then
        if [[ ${dst_name} = "python" && -d python ]];then
            rm -rf python_back && mv python python_back
            mkdir python
        fi
        gzip -df ${tar_name}
        [ $? -ne 0 ] && echo_error "gzip decompress ${tar_name} error, please retry or contact with easyops" && exit 1
        len=`printf ${tar_name}|wc -c|xargs`
        len=`expr ${len} - 3`
        #t_name=${tar_name:0:${len}-3}
        #slibclean
        t_name=`echo ${tar_name}|cut -c1-${len}`
        tar -xf ${t_name}
        if [ ${dst_name} == "agent/easy_collector/plugins" ]; then
            mv plugins/* ${dst_name}/
        fi
        [ $? -ne 0 ] && echo_error "tar decompress ${tar_name} error, please retry or contact with easyops" && exit 1
    else
        tar -xf ${tar_name} -C ${dst_name} --strip-components 1
        [ $? -ne 0 ] && echo_error "decompress ${tar_name} error, please retry or contact with easyops" && exit 1
    fi
}

untar_pkg(){
    # install & run
    cd ${install_base}
    # python
    # 不清除Python，防止依赖进程挂掉
    [ ! -d python ] && mkdir python
    chmod 755 python
    if test ! -e /usr/local/easyops/deploy_init/env.config ;then
        untar ${python_pkg} python
    else
        printf "\033[32mignore python decompress\033[0m, because env.config file exist show that it may be a easyops server\n"
    fi

    # agent
    [ ! -d agent ] && mkdir agent
    chmod 755 agent
    untar ${agent_pkg} agent

    # easy_collector/plugins
    easy_collector_path="agent/easy_collector"
    plugin_path="${easy_collector_path}/plugins"
#    if [ ! -d "${plugin_path}/easy_checks" ]; then
    rm -rf ${plugin_path}
    rm -rf "${easy_collector_path}/easy_checks"
    rm -rf "${easy_collector_path}/lib"
    rm -f "${easy_collector_path}/easy_collector.py"
    mkdir -p ${plugin_path}
    chmod 755 ${plugin_path}
    untar ${plugin_pkg} ${plugin_path}
#    fi
}

check_download(){
    echo "check download files "
    # 检测下载包完整性
    if [ "${os}" = "unix" ];then
        gzip -l ${install_base}/${agent_pkg}  > /dev/null
    else
        tar -tf ${install_base}/${agent_pkg} > /dev/null
    fi
    [ $? -ne 0 ] && echo_error "download agent failed, please retry or contact with easyops" && exit 1

    if [ "${os}" = "unix" ];then
        gzip -l ${install_base}/${python_pkg} > /dev/null
    else
        tar -tf ${install_base}/${python_pkg} > /dev/null
    fi
    [ $? -ne 0 ] && echo_error "download ${python_pkg} failed, please retry or contact with easyops" && exit 1

     if [ "${os}" = "unix" ];then
        gzip -l ${install_base}/${plugin_pkg} > /dev/null
    else
        tar -tf ${install_base}/${plugin_pkg} > /dev/null
    fi
    [ $? -ne 0 ] && echo_error "download ${plugin_pkg} failed, please retry or contact with easyops" && exit 1
}

do_upgrade() {
    # 清理admin和init.xml
    cd ${install_base}
    backup_agent=${install_base}/agent.`date '+%Y%m%d%H%M%S'`
    if [ ! -z "${aix_flag}" ];then
        find ${install_base}  -name "agent.20*"  -prune  -mtime -3 -type d | xargs -i rm -rf {}/log/
        find ${install_base}  -name "agent.20*"  -prune  -mtime -3 -type d | xargs -i rm -rf {}/cache/
        find ${install_base}  -name "agent.20*"  -prune  -mtime -3 -type d | xargs -i rm -rf {}/tmp/
    else
        find ${install_base} -maxdepth 1  -mtime -3 -type d -name "agent.20*" | xargs -i rm -rf {}/log/
        find ${install_base} -maxdepth 1  -mtime -3 -type d -name "agent.20*" | xargs -i rm -rf {}/cache/
        find ${install_base} -maxdepth 1  -mtime -3 -type d -name "agent.20*" | xargs -i rm -rf {}/tmp/
    fi

    if [ -d agent ];then
        echo "backup and stop old version first"
        cp -rf agent ${backup_agent} >/dev/null 2>&1
        # 原启动方式
        cd ${install_base}/agent
        if [ -f init.xml ]; then
            ./admin/stop.sh all >/dev/null 2>&1
            # 对于2.10版本前的，直接删除
            rm -rf ${install_base}/agent
        fi
        # 新的启动方式
        command -v easyops > /dev/null 2>&1
        if [ $? -eq 0 ]; then
            easyops stop >/dev/null 2>&1
        fi
        # 这里不要去删除agent，因为里面有用户配置数据
        cd ${install_base}
        if [ ! -z "${aix_flag}" ];then
            find  ${install_base} -name "agent.20*" -prune  -mtime +3 -type d  |xargs rm -rf
        else
            find  ${install_base} -maxdepth 1 -mtime +3 -type d -name "agent.20*" |xargs rm -rf
        fi
    fi
}

do_replace_init() {
    # install & run
    cd ${install_base}
    untar_pkg

    cd ${install_base}/agent
    # 割接接口采集
    #./deploy/migrate_topo_collector.py > ./log/migrate_topo.log 2>&1
    [ -d collector_agent ] && rm -rf collector_agent

    # 替换crontab的添加方式
    rm -rf ${install_base}/agent/pkg/script/crontab.py*

    topo_file=${install_base}/agent/easy_collector/data/topo/topo.json
    [ -f ${topo_file} ] && rm -f ${topo_file}

    total_server_ip=""
    for each_server_ip in ${all_server_ip}
    do
        only_ip=`echo ${each_server_ip} |awk -F':' '{print $1}'`
        if [ -z "${total_server_ip}" ]; then
            total_server_ip=${only_ip}
        else
            total_server_ip="${total_server_ip},${only_ip}"
        fi
    done

    replace_paths="./bin/easyops_resource_limit.sh ./bin/monitor.sh ./bin/restart_limit.sh ./deploy/check_status.sh ./deploy/crontab.sh ./deploy/limit_cpu.sh ./deploy/migrate_topo_collector.py ./easyAgent/libs/deviceBaseInfo.sh ./deploy/start_script.sh ./deploy/stop_script.sh ./deploy/uninstall_postscript.sh"

    if [ "${os}" = "linux" ];then
        #使用新版配置conf/conf.yaml
        old_conf="./easyAgent/conf/conf.yaml"
        if [ -f ${old_conf} ];then
            mv ${old_conf} ${old_conf}.old.`date +%Y%m%d%H%M%S`
        fi
        if [ ! -f ./conf/conf.yaml ];then
            cp ./conf/conf.sample.yaml ./conf/conf.yaml
        fi
        mkdir -p $(dirname ${old_conf})
        ln -snf ../../conf/conf.yaml  ${old_conf}
        ln -snf ../easyAgent/conf/sysconf.ini conf/

        # sed -i unix不支持
        sed -i "s/__SERVERIP__/${total_server_ip}/g" "./conf/conf.yaml"
        sed -i "s/__ORGID__/${org}/g" "./conf/conf.yaml"
        sed -i "s/__TAG__/${tag}/g" "./conf/conf.yaml"
        echo -n "$gateway_pub" > ./easyAgent/conf/gateway.pub

        replace_file=`echo ${replace_paths} |tr " " "\n"`
        for file_path in ${replace_file};do
            sed -i "s:__custom__install_path__:${install_base}:g" "${file_path}"
        done
    else
        if [ ! -f ./easyAgent/conf/conf.yaml ];then
            cp ./easyAgent/conf/conf.sample.yaml ./easyAgent/conf/conf.yaml
        fi
        # sed -i unix不支持
        sed  "s/__SERVERIP__/${total_server_ip}/g" "./easyAgent/conf/conf.yaml" > "./easyAgent/conf/t_conf.yaml"
        mv "./easyAgent/conf/t_conf.yaml" "./easyAgent/conf/conf.yaml"
        sed  "s/__ORGID__/${org}/g" "./easyAgent/conf/conf.yaml" > "./easyAgent/conf/t_conf.yaml"
        mv "./easyAgent/conf/t_conf.yaml" "./easyAgent/conf/conf.yaml"
        sed  "s/__TAG__/${tag}/g" "./easyAgent/conf/conf.yaml" > "./easyAgent/conf/t_conf.yaml"
        mv "./easyAgent/conf/t_conf.yaml" "./easyAgent/conf/conf.yaml"
        echo  "$gateway_pub" > ./easyAgent/conf/gateway.pub

        IFS=" "
        set -A replace_file ${replace_paths}
        for file_path in "${replace_file[@]}";
        do
            rm -rf ${tmp_path}/sed_tmp_file
            sed  "s:__custom__install_path__:${install_base}:g" ${file_path}  > ${tmp_path}/sed_tmp_file
            mv  -f ${tmp_path}/sed_tmp_file  ${file_path}
        done
    fi

    # 废弃原有的软链路径，在某些系统/usr/local/bin并不默认存在于PATH中
    unlink /usr/local/bin/easyops > /dev/null 2>&1
    easyops_bin="/usr/bin/easyops"
    [ -f "${easyops_bin}" ] && rm -f ${easyops_bin}
    # aix的python需要修改环境变量
    mv ${tmp_bin_path} ${easyops_bin}

    chmod a+x ${easyops_bin}
    ${easyops_bin} init > /dev/null
}

# solaris 下，cat内容切后台后会有异常，因此提前生成
gen_easyops_bin(){
    tmp_bin_path="${tmp_path}/easyops_bin"
    aix_flag=`uname -a |grep -i aix`
    if [[ ! -z "$aix_flag" ]]; then
        cat > ${tmp_bin_path} <<EOF
#!/bin/sh
export EASYOPS_BASE_PATH=${install_base}
export LIBPATH=${install_base}/python/dependency:\${LIBPATH}
export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/lib:/lib64:/usr/lib:/usr/lib64:${install_base}/python/dependency:${install_base}/python/lib

${install_base}/python/bin/python ${install_base}/agent/pkg/script/easyops.py  \$*
EOF
    else
        cat > ${tmp_bin_path} <<EOF
#!/bin/sh
export EASYOPS_BASE_PATH=${install_base}

if [[ "${install_base}" != "/usr/local/easyops" ]]; then
    export LIBPATH=\${LIBPATH}:${install_base}/python/dependency
    export LD_LIBRARY_PATH=\${LD_LIBRARY_PATH}:/lib:/lib64:/usr/lib:/usr/lib64:${install_base}/python/dependency:${install_base}/python/lib
fi
${install_base}/python/bin/python ${install_base}/agent/pkg/script/easyops.py  \$*
EOF
    fi
}

install(){
    gen_easyops_bin
    if [ ${pkg_action} = 'install' ]; then
        do_replace_init
        ${easyops_bin} restart
    else
        do_upgrade >/dev/null && do_replace_init >/dev/null && ${easyops_bin} restart >/dev/null &
    fi

    if [ $? -ne 0 ]; then
        echo
        #printf "agent install \033[31mfailed\033[0m, please try again\n"
        printf "agent install failed, please try again\n"
        echo
    else
        echo
        #printf "we support '\033[32measyops\033[0m' command to start|stop|restart agent, enjoy it\n"
        printf "we support 'easyops' command to start|stop|restart agent, enjoy it\n"
        echo "tips: you should execute 'cd ${install_base}/agent' first"
    fi


}

# ************ main **************
echo_step "1. start to ${pkg_action} ..."
sysumask=$(umask)
umask 0022
env_init
echo_step "2. start to download ..."
get_pkg_list
get_download_method
split_server_ip
download_from_server
check_download
umask $sysumask
# 3. 执行安装或升级
echo_step "3. execute ${pkg_action} and restart agent, agent will interrupt for a while."
install





