# 1. 网络相关

## 1.1 获取网卡名称

### 1.1.1 awk+sed+grep

```bash
$ cat /proc/net/dev | awk '{i++; if(i>2){print $1}}' | sed 's/^[\t]*//g' | sed 's/[:]*$//g' | grep -v ^#

vethefd80b1
veth5f8f27bb
docker0
veth2c5ef152
vethb97e4fcc
cni0
ens160
lo
veth150cd062
flannel.1
```

>     (1) /proc/net/dev是给用户读取或更改网络适配器及统计信息的方法;
>     (2) awk '{i++; if(i>2){print $1}}'命令是从第二行开始循环获取第一列数据;
>     (3) sed 's/^[\t]*//g'命令为去除行首的空格;
>     (4) sed 's/[:]*$//g'命令为去除行尾的":"字符.

### 1.1.2 grep + awk

```bash
$ ifconfig | grep  "flags" | awk '{print $1}' | awk -F ":" '{print $1}'
cni0
docker0
ens160
flannel.1
lo
veth150cd062
veth2c5ef152
veth5f8f27bb
vethb97e4fcc
vethefd80b1
```

### 1.1.3 /sys/class/net

```bash
$ ls /sys/class/net
cni0  docker0  ens160  flannel.1  lo  veth150cd062  veth2c5ef152  veth5f8f27bb  vethb97e4fcc  vethefd80b1
```

## 1.2 获取ip

### 1.2.1 grep + awk + tr

```bash
$ ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:"
192.168.0.128
```

### 1.2.2 grep+awk

```bash
$ ip addr | awk '/^[0-9]+: / {}; /inet.*global/ {print gensub(/(.*)\/(.*)/, "\\1", "g", $2)}'
192.168.0.128
```

### 1.2.3 grep+awk

```bash
$ ip addr |grep "inet\b"|awk '{print $2}'
127.0.0.1/8
192.168.0.171/24
172.17.0.1/16
10.244.0.0/32
10.244.0.1/24
```

## 1.3 端口与进程

### 1.3.1 根据端口杀进程

####  kill + lsof

```bash
$ kill `lsof -i:8080 |awk '{print $2}' |grep -v [A-Z]`
```

#### kill + netstat

```bash
$ kill `netstat -lntup |grep -w 8080 |awk -F '[/ | ]+' '{print $7}'`    #请务必使用-w参数，只过滤完全符合的端口
```

###  1.3.2 根据用户杀进程

#### kill + ps -u

```bash
$ kill `ps -u www |awk '{print $1}' |grep -v [A-Z]`
```

#### killall -u

```bash
$ killall -u www     #killall -u 杀死www用户的进程
```

####  kill + pgrep

```bash
$ pgrep -u  www |xargs kill
```

#### pkill -u

```bash
$ pkill -u www
```

### 1.3.3 根据服务名字杀进程

#### kill + pidof

```bash
$ kill `pidof -s mysqld`
```

#### pkill

```bash
$ pkill -o mysqld
```

#### kill + ps

```bash
$ ps -ef |grep -w mysqld |awk '{print $2}'|xargs kill
```

### 附赠

#### 根据文件杀死进程

```bash
$ pkill -f sprintbootdemo.jar
```

## 1.4 tcp 状态

### 1.4.1 netstat + awk + uniq + sort

```bash
$ netstat -n |grep ^tcp |awk '{print $6}' |sort |uniq  -c| sort -n -k 1 -r
  580 ESTABLISHED
     62 TIME_WAIT
     38 FIN_WAIT2
     16 FIN_WAIT1
      4 LAST_ACK
      3 CLOSE_WAIT
```

### 1.4.2 netstat+awk

```bash
$ netstat -n | awk '/^tcp/ {++S[$NF]} END {for(a in S) print a,S[a]}'
FIN_WAIT_1 2
FIN_WAIT_2 1
CLOSE_WAIT 11
TIME_WAIT 10
ESTABLISHED 42
```

## 1.5 多姿势获取端口信息

### 1.5.1 netstat

#### 某刻的请求总数

```bash
$ port="80" && netstat -natu|awk '{print $4}'|awk -F ":" '{print $2}'|grep ${port}
```

#### 特定tcp状态下某刻的请求总数

```bash
FIN_WAIT_1 
FIN_WAIT_2 
CLOSE_WAIT 
TIME_WAIT 
ESTABLISHED 
=================
$ port="80" && netstat -natu |grep ESTABLISHED |awk '{print $4}'|awk -F ":" '{print $2}'|grep ${port}
```





# 2. 字符处理、统计

## 2.1 log分析姿势大全 cli

nginx log

### 2.1.1 根据访问IP统计UV

```bash
$ awk '{print $1}'  access.log|sort | uniq -c |wc -l
```

### 2.1.2 统计访问URL统计PV

```bash
$ awk '{print $7}' access.log|wc -l
```

### 3.1.3 查询访问最频繁的URL

```bash
$ awk '{print $7}' access.log|sort | uniq -c |sort -n -k 1 -r|more
```

### 3.1.4 查询访问最频繁的IP

```bash
$ awk '{print $1}' access.log|sort | uniq -c |sort -n -k 1 -r|more
```

### 3.1.5 根据时间段统计查看日志

```bash
$ cat  access.log| sed -n '/14\/Mar\/2015:21/,/14\/Mar\/2015:22/p'|more
```

## 2.2 三剑客

### 2.2.1 awk



### 2.2.2 sed



### 2.2.3 grep





# 3.循环

## 3.1 for



## 3.2 while



# 4. 交互

## 4.1 read



## 4.2 expect(免交互)



# 5. 异常处理

## 5.1 避免雪崩



## 5.2 条件控制



# 6. 输出重定向问题

## 6.1 标准输出



## 6.2 日志收集

# 7. 关于各类数据采集

## 7.1 系统信息采集



# 8. 各类一件安装环境



# 9. 如何变得炫酷

