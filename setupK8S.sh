#!/usr/bin/env bash
# change time zone
cp /usr/share/zoneinfo/America/New_York /etc/localtime
timedatectl set-timezone America/New_York
# rm /etc/yum.repos.d/CentOS-Base.repo
# cp /vagrant/yum/*.* /etc/yum.repos.d/
# mv /etc/yum.repos.d/CentOS7-Base-163.repo /etc/yum.repos.d/CentOS-Base.repo
# using socat to port forward in helm tiller
# install  kmod and ceph-common for rook

sed -i "s/enabled=1/enabled=0/g" /etc/yum/pluginconf.d/fastestmirror.conf
yum clean all
yum clean metadata
yum update
yum install -y wget curl conntrack-tools vim net-tools telnet tcpdump bind-utils socat ntp kmod ceph-common dos2unix
# kubernetes_release="/vagrant/kubernetes-server-linux-amd64.tar.gz"
# # # Download Kubernetes
# if [[ $(hostname) == "node1" ]] && [[ ! -f "$kubernetes_release" ]]; then
#     wget https://storage.googleapis.com/kubernetes-release/release/v1.14.0/kubernetes-server-linux-amd64.tar.gz -P /vagrant/
# fi

echo 'set nameserver'
echo "nameserver 8.8.8.8">/etc/resolv.conf
cat /etc/resolv.conf

echo 'disable swap'
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# enable ntp to sync time
echo 'sync time'
systemctl start ntpd
systemctl enable ntpd

echo 'enable iptable kernel parameter'
cat >> /etc/sysctl.conf <<EOF
net.ipv4.ip_forward=1
EOF
sysctl -p

# Install Kueadm, Kubelet and kubectl

cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kube*
EOF

# Set SELinux in permissive mode (effectively disabling it)
echo 'disable selinux'

sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

echo 'Install kubeadm, kubelet and kubectl'
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

systemctl enable --now kubelet

# enable password authentication
echo "enable password authentication"
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config 
systemctl restart sshd

# Install docker CE
echo "Install docker"
yum install -y yum-utils device-mapper-persistent-data lvm2
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io
systemctl start docker
systemctl enable docker.service

# Fix ip tables issue in RHEL/CentOS 7
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system

if [[ $2 = 'Master' ]]
then
    if [[ $1 -eq 1 ]]
    then
        echo "setup first master node"
        # Get join command and save in file
        mkdir -p  /etc/kubernetes/pki/etcd/
        cp /vagrant/output/192.168.1.157/pki/etcd/ca.crt /etc/kubernetes/pki/etcd/
        cp /vagrant/output/192.168.1.157/pki/apiserver-etcd-client.crt /etc/kubernetes/pki/
        cp /vagrant/output/192.168.1.157/pki/apiserver-etcd-client.key /etc/kubernetes/pki/
        kubeadm init --config=/vagrant/kubernetes/kubeadm-config.yaml --experimental-upload-certs | tee /var/tmp/output.txt
        rm -rf  /vagrant/joincommand
        
        mkdir /vagrant/joincommand
        cat /var/tmp/output.txt | head -65 | tail -3 | tee /vagrant/joincommand/joinmaster.sh
        cat /var/tmp/output.txt | head -74 | tail -2 | tee /vagrant/joincommand/joinworker.sh

        mkdir ~/.kube
        cp /etc/kubernetes/admin.conf ~/.kube/config
        kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
        kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml
    else
        echo "setup other master node"
        /vagrant/joincommand/joinmaster.sh
    fi
elif [[ $2 = 'ETCD' ]]
then
   echo "setup ETCD clusters"
    if [[ $1 -eq 1 ]]
    then
        echo -e "setup first etcd node \e[32mGreen"
        /vagrant/kubernetes/kubelet-etcd.sh
        /vagrant/kubernetes/etcd.sh
    else
        FirstEtcdHost="192.168.1.156"
        echo -e "setup other etcd nodes \e[32mGreen"
        /vagrant/kubernetes/kubelet-etcd.sh
        cd /vagrant/output/$3
        # chown -R root:root pki
        mkdir /etc/kubernetes/pki
        cp -r pki/* /etc/kubernetes/pki
        kubeadm init phase etcd local --config=/vagrant/output/$3/kubeadmcfg.yaml
    fi
else
    echo "setup worker node"
    /vagrant/joincommand/joinworker.sh
fi
