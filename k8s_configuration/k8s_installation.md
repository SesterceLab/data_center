# Find out how Kubernetes works 


## install docker on matser and nodes
https://docs.docker.com/engine/install/ubuntu/
 1. remove old version
 ```shell
 sudo apt-get remove docker docker-engine docker.io containerd runc  
```
2. Set up the repository  
```shell
sudo apt-get update  
sudo apt-get install \
    ca-certificates \
    curl \
    gnupg
```
```shell
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

3. install

```shell
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

## Install kubectl kubeadm kubelet on master and nodes 
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/ 
```shell
sudo apt-get update

sudo apt-get install -y apt-transport-https ca-certificates curl
```
#sudo mkdir /etc/apt/ keyrings

```shell
sudo curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

```shell
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
#on wsl
#sudo apt install containerd
```

##  create cluster using kubeadm with docker-runtime 
#disable swap required by kubeadm 
swapoff -a                 # Disable all devices marked as swap in /etc/fstab
sed -e '/swap/ s/^#*/#/' -i /etc/fstab   # Comment the correct mounting point
sed -i '/swap/d' /etc/fstab
systemctl mask swap.target               # Completely disabled
reboot

#
#IPv4 iptalbes
```shell
cat> /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables=1
net.bridge.bridge-nf-call-iptalbes=1
EOF
```
#hosts on master
```shell
cat >> /etc/hosts <<EOF
192.168.1.202 linux #master
192.168.122.9 vir1 #node
...

````




#start docker runtime

https://github.com/Mirantis/cri-dockerd


```shell
git clone https://github.com/Mirantis/cri-dockerd.git
###Install GO###
wget https://storage.googleapis.com/golang/getgo/installer_linux
chmod +x ./installer_linux
./installer_linux
source ~/.bash_profile

cd cri-dockerd
mkdir bin
go build -o bin/cri-dockerd
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket


```


#stop firewall 
sudo ufw disable

# kubeadm reset 

```shell
kubeadm reset --cri-socket=unix:///var/run/cri-dockerd.sock
```

# system init 







# kubeadm init with docker-run time 

```shell
kubeadm init --cri-socket=unix:///var/run/cri-dockerd.sock
```
```shell
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

```
after that we can use
```shell
systemctl restart kubelet
```

```shell
  export KUBECONFIG=/etc/kubernetes/admin.conf
````
this will change after each init, add the following to nodes
```shell
kubeadm --cri-socket=unix:///var/run/cri-dockerd.sock join 192.168.0.24:6443 --token ctoda6.k0zvxdrp0xi9e1mb --discovery-token-ca-cert-hash sha256:710c75b101d76800accb32cb24f7ede03bdbee1d236a439f13b5bb5d7b62c45e

````

## apply CNI networks


open below file location(if exists, either create) and paste below data

vim /run/flannel/subnet.env

```shell
FLANNEL_NETWORK=10.244.0.0/16
FLANNEL_SUBNET=10.244.0.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=true
```

```shell
kubectl patch nodes linux --patch '{"spec": {"podCIDR":"10.244.0.0/16"}}'

```


```shell 
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```


![Image](https://user-images.githubusercontent.com/98951927/233794386-9b6194a1-7a48-465b-9b04-9e0204df5fe9.png)


# delpoy docker image 

```shell
kubectl create deployment jupyter --image=jupyter/minimal-notebook --dry-run=client -o yaml > jupyter.yaml
kubectl create deployment jupyter --image=jupyter/scipy-notebook--dry-run=client -o yaml > jupyter.yaml


kubectl apply -f jupyter.yaml
```

# run pod 
```shell
kubectl exec -it  jupyter-6f449f4cbb-kvrdq  -- bash
```

# expose port 

```shell
kubectl expose deployment jupyter --port=8888 --target-port=8888 --type=NodePort
```

# visit 
```shell
kubectl get svc
```
visit using one of the nodeip+port

#test
```shell
import platform
print("="*40, "System Information", "="*40)
uname = platform.uname()
print(f"System: {uname.system}")
print(f"Node Name: {uname.node}")
print(f"Release: {uname.release}")
print(f"Version: {uname.version}")
print(f"Machine: {uname.machine}")
print(f"Processor: {uname.processor}")

```

# kubernetes Web UI
https://www.youtube.com/watch?v=CICS57XbS9A&t=177s
#
```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml
```
```
kubectl create serviceaccount admin-user -n kubernetes-dashboard
kubectl create clusterrolebinding dashboard-admin -n kubernetes-dashboard --clusterrole=cluster-admin --serviceaccount= kubernetes-dashboard:admin-user
kubectl -n kubernetes-dashboard create token admin-user
https://192.168.122.3:32628/
```


# ingress configuration

```shell
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.0/deploy/static/provider/cloud/deploy.yaml

```

# kubeapi
set a kube-admin token for using kube-api

```shell
kubectl create namespace syspodadmin
```
```shell
kubectl create serviceaccount myservice -n syspodadmin
```
```shell
kubectl create clusterrolebinding syspodadmin --clusterrole=cluster-admin --serviceaccount syspodadmin:myservice
```
Create token for connection
```shell
kubectl create token myservice -n syspodadmin
```






# known problems 
coredns not started : https://stackoverflow.com/questions/40534837/kubernetes-installation-and-kube-dns-open-run-flannel-subnet-env-no-such-file
#problem cni0 ip already in use
sudo ip link delete cni0 type bridge

pv 
https://www.datree.io/resources/kubernetes-troubleshooting-fixing-persistentvolumeclaims-error

https://grafana.com/docs/grafana/latest/setup-grafana/installation/kubernetes/

#monitor
https://devopscube.com/setup-prometheus-monitoring-on-kubernetes/

#IP route problem
https://www.youtube.com/watch?v=yxyYxj3-JE8&list=PLmOn9nNkQxJHYUm2zkuf9_7XJJT8kzAph&index=6

# ingress problem
```shell
    kubectl get ValidatingWebhookConfiguration -o yaml > ./validating-backup.yaml

    kubectl delete ValidatingWebhookConfiguration <name of the resource>
```
# not ready problem
after add subnet.env
and apply flannel.yaml, this can be solved