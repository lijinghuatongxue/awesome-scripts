#!/bin/bash

cd /usr/local/easyops/mysql

# 如果启动失败 则尝试以恢复模式启动然后进行重启 
./bin/mysqld_safe --defaults-file=./etc/my.cnf --user=easyops --innodb-force-recovery=1 >/dev/null 2>log/${app_folder}.err &
sleep 5
ps -fC mysqld |grep "mysql/bin/mysqld" >/dev/null 2>&1
# 如果这样启动也是失败的话就真的没法了 或者说尚未找到合适的方法
if [ $? -ne 0 ];then
    echo "start error, exit 1"
    exit 1
fi

# 如果以恢复模式启动则要先停掉
./bin/mysqladmin shutdown -h 127.0.0.1 > /dev/null 2>&1 # 先停止
sleep 5
ps -fC mysqld | grep "mysql/bin/mysqld" | awk '{print $2}' | xargs kill > /dev/null 2>&1  # 停不掉就kill掉
sleep 5
ps -fC mysqld |grep "mysql/bin/mysqld" >/dev/null 2>&1
if [ $? -eq 0 ];then
    echo "start error, exit 2"  # 因为以恢复模式启动了但没有停掉 导致mysql无法写入 这里上层是启动操作 是以start error
    exit 2
fi

echo "Recover ok! Please restart your mysql manually."

exit 0;

