#! /bin/bash -e

# Install wget
sudo apt install -y wget || sudo yum install -y wget
#
# setup okanstack
if [[ ! -f /tmp/okanstack.sh ]]; then
    wget -q https://raw.githubusercontent.com/rajalokan/okanstack/master/okanstack.sh -O /tmp/okanstack.sh
fi
source /tmp/okanstack.sh
#
# Preconfigure the instance
# preconfigure k8sworker2

# Variables
DOCKER_GPG_KEY_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_APT_URL="https://download.docker.com/linux/ubuntu"
#
K8S_GPG_KEY_URL="https://packages.cloud.google.com/apt/doc/apt-key.gpg"
K8S_APT_URL="https://apt.kubernetes.io"
#
KUBELET_VERSION="1.13.5-00"
KUBEADM_VERSION="1.13.5-00"
KUBECTL_VERSION="1.13.5-00"

# Disable swap
sudo swapoff -a

# Install docker
curl -fsSL ${DOCKER_GPG_KEY_URL} | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] ${DOCKER_APT_URL} $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce
sudo apt-mark hold docker-ce

# Install kubectl, kubeadm & kubelet
curl -fsSL ${K8S_GPG_KEY_URL} | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb ${K8S_APT_URL} kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y kubectl=${KUBECTL_VERSION} kubeadm=${KUBEADM_VERSION} kubelet=${KUBELET_VERSION}
sudo apt-mark hold kubectl kubeadm kubelet


echo "This is worker"
sudo apt-get install -y sshpass
sshpass -p "vagrant" scp -o StrictHostKeyChecking=no vagrant@192.168.33.11:/etc/kubeadm_join_cmd.sh .
sudo sh ./kubeadm_join_cmd.sh


# Turn on iptable bridge
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
