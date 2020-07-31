#!/bin/bash
# translate old env file to new easy_env

deploy_path=/usr/local/easyops/deploy_init
easy_env_file=${deploy_path}/easy_env.ini
old_env_file=${deploy_path}/env.config
ens_client_config=/usr/local/easyops/ens_client/conf/client.yaml

[[ -f easy_env_file ]] && exit 0

function get_old_config() {
    item=$1
    result=$(grep "$item" ${old_env_file} |tail -1 |awk -F'=' '{print $2}')
    echo $result
}

function get_ens_by_name() {
    item=$1
    result=$(/usr/local/easyops/ens_client/tools/get_all_service.py $item)
    if [[ $? -ne 0 ]]; then
	echo ""
    else
	result=$(echo "$result" |awk '{print $2}')
	echo $result
    fi
}

function get_ens_by_number() {
    item=$1
    result=""
    for i in {1..10}
    do
	ens_name="${item}.${i}"
	each=$(get_ens_by_name $ens_name)
	[[ $each"X" == "X" ]] && break
	result="${result} ${each}"
    done
    echo $result
}


function replace_nodes() {
    section=$1
    all_nodes=$2
    i=1
    for each_node in $(echo ${all_nodes})
    do
	node_key="node.${i}"
	echo "${node_key}=${each_node}"
	/usr/local/easyops/python/bin/python ./tools/set_env.py ${section} ${node_key} ${each_node}
	i=$(($i+1))
    done
}


cp -f ./easy_env.sample.ini ./easy_env.ini


# get from old env.config
local_ip=$(get_old_config local_ip)
inner_ip=$(get_old_config inner_ip)
org=$(get_old_config org)
grafana_password=$(get_old_config grafana_password)
mongodb_data=$(get_old_config config_mongodb_data |sed 's/\"//g' |tr ' ' '\n' |awk -F":" '{print $1}' |tr '\n' ' ' |sed 's/.$//')
mongodb_arbiter=$(get_old_config config_mongodb_arbiter |sed 's/\"//g'|awk -F":" {'print $1'})
if [[ ${mongodb_data}"X" == "X" ]]; then
    mongodb_data=127.0.0.1
    mongodb_primary=127.0.0.1
else
    mongodb_primary=$(echo $mongodb_data |awk '{print $1}')
fi


# get from ens by name
mysql_master=$(get_ens_by_name config.mysql.master)
if [[ "${mysql_master}X" == "X" ]]; then
    echo "could not get name service config.mysql.master"
    exit 255
fi
redis_master=$(get_ens_by_name config.redis.master)
[[ $redis_master"X" == "X" ]] && redis_master=127.0.0.1
storm_nimbus_nodes=$(get_ens_by_name logic.storm.nimbus)
if [[ $storm_nimbus_nodes"X" == "X" ]]; then
    storm_nimbus_nodes=$(get_ens_by_name config.storm.nimbus)
fi

influxdb_master=$(get_ens_by_name data.influxdb.master)

# get from ens by number
zookeeper_nodes=$(get_ens_by_number config.zookeeper)
kafka_nodes=$(get_ens_by_number config.kafka)
es_nodes=$(get_ens_by_number config.elasticsearch)
rabbitmq_nodes=$(get_ens_by_number config.rabbitmq)

[[ $zookeeper_nodes"X" == "X" ]] && echo "name server is unnormal" && exit 1

# get ens_root from ens_client config
ens_root_nodes=$(/usr/local/easyops/python/bin/python ./tools/get_ens_root.py)

zk_count=$(echo "${zookeeper_nodes}" |tr ' ' '\n' |wc -l)
[[ $zk_count -gt 1 ]] && is_cluster=true || is_cluster=false

echo "replace is_cluster"
/usr/local/easyops/python/bin/python ./tools/set_env.py DEFAULT is_cluster "${is_cluster}"

echo "replace org inner_ip local_ip"
/usr/local/easyops/python/bin/python ./tools/set_env.py common org "${org}"
/usr/local/easyops/python/bin/python ./tools/set_env.py common inner_ip "${inner_ip}"
/usr/local/easyops/python/bin/python ./tools/set_env.py common local_ip "${local_ip}"

echo "replace grafana password"
/usr/local/easyops/python/bin/python ./tools/set_env.py grafana password "${grafana_password}"

echo "replace mongodb"
/usr/local/easyops/python/bin/python ./tools/set_env.py mongodb data_ip "${mongodb_data}"
/usr/local/easyops/python/bin/python ./tools/set_env.py mongodb arbiter_ip "${mongodb_arbiter}"
/usr/local/easyops/python/bin/python ./tools/set_env.py mongodb primary_node "${mongodb_primary}"

echo "replace mysql"
/usr/local/easyops/python/bin/python ./tools/set_env.py mysql master "${mysql_master}"

echo "replace redis"
/usr/local/easyops/python/bin/python ./tools/set_env.py redis config.redis.master "${redis_master}"

echo "replace storm_number"
replace_nodes storm_nimbus "$storm_nimbus_nodes"

echo "replace zookeeper"
replace_nodes zookeeper "$zookeeper_nodes"

echo "replace kafka"
replace_nodes kafka "$kafka_nodes"

echo "replace es"
replace_nodes elasticsearch "$es_nodes"

echo "replace rabbitmq"
replace_nodes rabbitmq "$rabbitmq_nodes"

echo "replace ens_root"
replace_nodes ens_root "$ens_root_nodes"

echo "replace influxdb"
replace_nodes influxdb "$influxdb_master"

echo "translate old env file to new easy_env, please check it"
