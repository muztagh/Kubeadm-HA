# Update HOST0, HOST1, and HOST2 with the IPs or resolvable names of your hosts
export HOST0=192.168.1.156
export HOST1=192.168.1.157
export HOST2=192.168.1.158

# Create temp directories to store files that will end up on other hosts.
mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("infra0" "infra1" "infra2")

for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1beta1"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: ${NAMES[0]}=https://${ETCDHOSTS[0]}:2380,${NAMES[1]}=https://${ETCDHOSTS[1]}:2380,${NAMES[2]}=https://${ETCDHOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
EOF
done

rm -rf  /vagrant/output/*
mkdir /vagrant/output/${HOST2}
mkdir /vagrant/output/${HOST1}
cp /tmp/${HOST1}/kubeadmcfg.yaml /vagrant/output/${HOST1}/kubeadmcfg.yaml
cp /tmp/${HOST2}/kubeadmcfg.yaml /vagrant/output/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-ca
kubeadm init phase certs etcd-server --config=/vagrant/output/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/vagrant/output/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/vagrant/output/${HOST2}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/vagrant/output/${HOST2}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /vagrant/output/${HOST2}/
# cleanup non-reusable certificates
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/vagrant/output/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/vagrant/output/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/vagrant/output/${HOST1}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/vagrant/output/${HOST1}/kubeadmcfg.yaml
cp -R /etc/kubernetes/pki /vagrant/output/${HOST1}/
find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

kubeadm init phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
find /vagrant/output/${HOST2} -name ca.key -type f -delete
find /vagrant/output/${HOST1} -name ca.key -type f -delete

kubeadm init phase etcd local --config=/tmp/${HOST0}/kubeadmcfg.yaml