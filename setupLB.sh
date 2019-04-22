timedatectl set-timezone America/New_York

sed -i "s/enabled=1/enabled=0/g" /etc/yum/pluginconf.d/fastestmirror.conf
yum clean all
# yum -y update
yum install -y wget curl conntrack-tools vim net-tools telnet tcpdump bind-utils socat ntp kmod ceph-common dos2unix haproxy


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

rm -rf /etc/haproxy/haproxy.cfg
cp /vagrant/haproxy/haproxy.cfg /etc/haproxy/haproxy.cfg
# need to run this command, otherwise haproxy can't bind socket 
setsebool -P haproxy_connect_any=1
systemctl restart haproxy
systemctl enable haproxy

# enable password authentication
sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/ChallengeResponseAuthentication no/ChallengeResponseAuthentication yes/g' /etc/ssh/sshd_config 
systemctl restart sshd

