#!/bin/bash

GREEN=$'\e[0;32m'
RED=$'\e[0;31m'
NC=$'\e[0m'
sudo apt purge zabbix-agent
wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu20.04_all.deb
sudo apt update
sudo apt -y install zabbix-agent
rm zabbix-release_6.4-1+ubuntu20.04_all.deb
systemctl enable zabbix-agent
sudo service zabbix-agent restart
sudo mkdir -p /etc/zabbix/zabbix_agentd.conf.d
sudo sh -c "openssl rand -hex 32 > /etc/zabbix/zabbix_agentd.psk"
sudo rm -f /etc/zabbix/zabbix_agentd.conf
sudo cp ./zabbix_agentd.conf /etc/zabbix/
chmod +x ./zxgpu.sh
sudo ./zxgpu.sh
sudo sevice zabbix-agent restart
sudo systemctl status zabbix-agent
echo "${GREEN}Remember the following key for zabbix server psk-encryption, psk-indentity gpuserver${NC}"
cat /etc/zabbix/zabbix_agentd.psk
echo "${GREEN}Finished!${NC}"
