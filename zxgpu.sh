#!/bin/bash
cd /etc/zabbix/
if ! grep -q gpu.discovery "/etc/zabbix/zabbix_agentd.conf"; then
 echo 'UserParameter=gpu.number,/usr/bin/nvidia-smi -L | /usr/bin/wc -l
UserParameter=gpu.discovery,/etc/zabbix/scripts/get_gpus_info.sh
UserParameter=gpu.fanspeed[*],nvidia-smi --query-gpu=fan.speed --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.power[*],nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.temp[*],nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.utilization[*],nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.name[*],nvidia-smi --query-gpu=gpu_name --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.memfree[*],nvidia-smi --query-gpu=memory.free --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.memused[*],nvidia-smi --query-gpu=memory.used --format=csv,noheader,nounits -i $1 | tr -d "\n"
UserParameter=gpu.memtotal[*],nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits -i $1 | tr -d "\n"'>> zabbix_agentd.conf 
echo 'UserParameter=gpu.utilization.dec.min[*],nvidia-smi -q -d UTILIZATION -i $1 | grep -A 5  DEC | grep Min | tr -s' "'" "'" '| cut -d' "'" "'" '-f 4' >> zabbix_agentd.conf 
echo 'UserParameter=gpu.utilization.dec.max[*],nvidia-smi -q -d UTILIZATION -i $1 | grep -A 5  DEC | grep Max | tr -s' "'" "'" '| cut -d' "'" "'" '-f 4' >> zabbix_agentd.conf 
echo 'UserParameter=gpu.utilization.enc.min[*],nvidia-smi -q -d UTILIZATION -i $1 | grep -A 5  ENC | grep Min | tr -s' "'" "'" '| cut -d' "'" "'" '-f 4' >> zabbix_agentd.conf 
echo 'UserParameter=gpu.utilization.enc.max[*],nvidia-smi -q -d UTILIZATION -i $1 | grep -A 5  ENC | grep Max | tr -s' "'" "'" '| cut -d' "'" "'" '-f 4' >> zabbix_agentd.conf 
fi
mkdir -p /etc/zabbix/scripts
cd /etc/zabbix/scripts

if [ ! -f /etc/zabbix/scripts/get_gpus_info.sh ]
then
	echo '#!/bin/bash
result=$(/usr/bin/nvidia-smi -L)
first=1
echo "{"
echo "\"data\":["
while IFS= read -r line
do
 if (( "$first" != "1" ))
 then
   echo ,
 fi
 index=$(echo -n $line | cut -d ":" -f 1 | cut -d " " -f 2)
 gpuuuid=$(echo -n $line | cut -d ":" -f 3 | tr -d ")" | tr -d " ")
 echo -n {"\"{#GPUINDEX}"\":\"$index"\", \"{#GPUUUID}"\":\"$gpuuuid\"}
 if (( "$first" == "1" ))
 then
#    echo ,
   first=0
 fi
done < <(printf "%s\n" "$result")
echo
echo "]"
echo "}"' >> get_gpus_info.sh

fi
chmod +x /etc/zabbix/scripts/get_gpus_info.sh
service zabbix-agent restart