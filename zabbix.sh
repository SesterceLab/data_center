#!/bin/bash
GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
apt update
apt install zabbix-agent
rm zabbix-release_6.4-1+ubuntu20.04_all.deb
systemctl restart zabbix-agent
sh -c "openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk"
echo "${GREEN}Remember the following key for zabbix server psk-encryption, psk-indentity gpuserver${NC}"
cat /etc/zabbix/zabbix_agentd.psk
echo "${GREEN}Success!${NC}"