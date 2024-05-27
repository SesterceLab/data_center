# How to install NFS and Slurm and TEST slurm

## 1. Preparation Hardware 
In this example, I created 5 virtual machines.
 - 2 machines as master node 192.168.100.155(main), 192.168.100.207(opt) 
- 2 worker nodes(192.168.100.148 worker1, 192.168.100.156 worker2) 
- 1 storage node(192.168.100.141)  
All machines with ubuntu_20.04 system with default user.
```bash
sudo apt-get upgrade && sudo apt-get update
```
## 2. Install NFS_server on storage node and NFS_client on master and worker nodes. 
###  1. On storage node
```bash
sudo apt install nfs-server nfs-kernel-server -y
```
Check nfs_server is running
```bash
sudo systemctl status nfs-server
```
Make a storage location for NFS_server  
```bash
sudo mkdir /storage
```
This storage location can be mouted hard disk  
Change ownership of this position, for this example, i give permission to default slurm user, this user will be used for slurm.  
```bash
sudo chown zhb:zhb  /storage
```
Adding line /etc/exports with 
```bash
sudo nano /etc/exports
```
```bash
/storage 192.168.100.155(rw,no_subtree_check,sync,no_root_squash,anonuid=999999,anongid=999999) 192.168.100.207(rw,no_subtree_check,sync,no_root_squash,anonuid=999999,anongid=999999) 192.168.100.148(rw,no_subtree_check,sync,no_root_squash,anonuid=999999,anongid=999999) 192.168.100.156(rw,no_subtree_check,sync,no_root_squash,anonuid=999999,anongid=999999)
```
Give premission to all 192.168.100.xxx subnet
```bash
/storage 192.168.100.0/24(rw,no_subtree_check,sync,no_root_squash,anonuid=999999,anongid=999999)
```
Note the format is /storage+space+ip()then space +nextip()...  
Restart NFS-server
```
sudo systemctl restart nfs-kernel-server.service
```
Check ufs status for allowing incoming connections from other nodes. 
should allow port 2049
### 2. On master nodes and worker nodes
Edit /etc/hosts file, add storage IP address
```bash
192.168.100.208 storage
192.168.100.177 master2
192.168.100.197 worker1
192.168.100.211 master1
192.168.100.179 worker2
```
We can delete the 127.0.1.1 line.
We can also put one host file in /storage folder, and copy this file to all machines, when we setup nfs share storage.

Install nfs-client 
```bash
sudo apt install nfs-common -y
```
make postion /storage and give ownership to user slurm the same as storage node.
```bash
sudo mkdir /storage
sudo chown hbz:hbz /storage
```
Mount /storage
```bash
sudo mount storage:/storage /storage
```
To make the drive mount upon restarts for the worker nodes, add this to fstab   
```bash
echo storage:/storage /storage nfs auto,timeo=14,intr 0 0 | sudo tee -a /etc/fstab
```
Test: change to slurm user, each machine should be able to read and write the files in /storage folder.

## 3. Install slurm dependencies and munge
Allow SSH connection between master nodes and workers.  
### 1. On master nodes
```bash
ssh-keygen 
ssh-copy-id hbz@worker1 
ssh-copy-id hbz@worker2
```
### 2. Install slurm and munge on all master nodes and worker nodes. 
```bash
 sudo apt install slurm-wlm slurm-client munge
``` 
Copy munge key of master1 to /storage 
```bash
sudo cp /etc/munge/munge.key /storage/
```
Replace the munge key for master2 and worker nodes. 
```bash
sudo cp /storage/munge.key /etc/munge/munge.key
```
Change premission and ownership of the munge key
```bash
sudo chmod 400 /etc/munge/munge.key
sudo chown munge:munge /etc/munge/munge.key

```

Restart munge service for master nodes and worker nodes
```bash
sudo systemctl enable munge
sudo systemctl restart munge
```
### 3. Generate Slurm configuration file. 
We can go to this website to generate a configuration file: https://slurm.schedmd.com/configurator.html
CPU information and memory information can be found using:
```bash
sudo slurmd -C
```
Or
```bash
lscpu
free -m
```
For our case: 
- SlurmctldHost: master1 
- BackupController: master2
- NodeName: worker[1-2]
- CPUs: #It is recommended to leave it blank.
- Sockets: 2 
- CoresPerSocket: 1
- ThreadsPerCore: 2
- RealMemory: 3919 #(optional)  

Othe configurations:
- MpiDefault=none # allow all MPIs
- ProctrackType=proctrack/cgroup
- SlurmUser=slurm
- SwitchType=switch/none
- TaskPlugin=task/affinity  
Database configuration:
- AccountingStoragePort=6819
  AccountingStorageType=accounting_storage/slurmdbd
- AccountingStorageUser=slurm
The configuration slurm.conf  is here in the repository.  .  
We create the configuration file slurm.conf at /storage

```bash
nano slurm.conf
```
Copy the configuration. On all machines change ownership of the slurm.conf to slurm
```bash
sudo chown zhb:zhb /etc/munge/munge.key
```
On all machines, copy the slurm.conf to /etc/slurm-llnl/
```bash
sudo cp /storage/slurm.conf /etc/slurm-llnl/
```

For master nodes:  

```bash
sudo mkdir -p /var/spool/slurmctld
sudo chown slurm:slurm /var/spool/slurmctld/
```
After this, if you start slurmctld, it will tell you that you didn't configure database.

### 4. Install mysql database for slurm accounting
Install mysql-server
```bash
sudo apt install mysql-server libmysqlclient-dev
```
Configuration of mysql-server  
Copy my.cnf to /etc/mysql/
```bash
sudo cp /storage/my.conf /etc/mysql/my.conf
```
Open a mysql terminal by:
```bash
sudo mysql -u root
```
In mysql terminal  
```bash
CREATE DATABASE slurm_acct_db;
CREATE USER 'hbz'@'localhost';
ALTER USER 'hbz'@'localhost' IDENTIFIED BY '1234';
GRANT ALL ON slurm_acct_db.* TO 'hbz'@'localhost';
FLUSH PRIVILEGES;
quit;
```
```bash
sudo systemctl restart mysql
```

Install slurmdbd
```bash
sudo apt-get -y install slurmdbd
```
Add a /opt/slurm/log/slurmdbd.log  
Give permission to to slurm:slurm
```bash
sudo mkdir -p /opt/slurm/log 
sudo touch /opt/slurm/log/slurmdbd.log
sudo chown hbz:hbz /opt/slurm/log/slurmdbd.log
sudo chown hbz:hbz /run/slurmdbd.pid
```
After slurmdbd is running, add cluster name to database
```bash
sudo sacctmgr add cluster cluster
```

### 4. start slurmctld, slurmdbd at master node
On master node  
For slurm scheduler:
```bash
sudo systemctl enable munge
sudo systemctl start munge
sudo systemctl enable slurmctld
sudo systemctl start slurmctld
```
For slurm database
```bash
sudo systemctl enable slurmdbd
sduo systemctl start slrumdbd
```
add the cluster name to database 
```bash
sacctmgr add cluster cluster 
```

### 5. Start slurmd for compute node
On all compute nodes, copy cgroup.conf to /etc/slurm-llns
```bash
sudo copy /storage/cgroup.conf /etc/slurm-llns
```

```bash 
sudo systemctl enable slurmd
sudo systemctl restart slurmd

```


## Debug tools 

```bash
 sudo slurmctld -D
 sudo slurmdbd -D -vvv
 sudo slurmd -D
```

## Create folders for slurmd

```bash# Ensure the log file has the correct permissions
sudo touch /var/log/slurmd.log
sudo chown slurm:slurm /var/log/slurmd.log
sudo chmod 0644 /var/log/slurmd.log

# Ensure the spool directory has the correct permissions
sudo mkdir -p /var/spool/slurmd
sudo chown -R slurm:slurm /var/spool/slurmd
sudo chmod 0755 /var/spool/slurmd

# Install hwloc if not already installed
sudo apt-get install hwloc
```


## 3.Test cluster parallel computation with tensorflow
Install parallel computation mpich module

```bash
sudo apt-get install mpich
```
