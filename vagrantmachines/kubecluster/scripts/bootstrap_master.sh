#! /bin/bash -e

# ctx logger info "Bootstrapping k8s master node"

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
# preconfigure k8smaster

# Variables
DOCKER_GPG_KEY_URL="https://download.docker.com/linux/ubuntu/gpg"
DOCKER_APT_URL="https://download.docker.com/linux/ubuntu"
DOCKER_CE_VERSION="18.06.1~ce~3-0~ubuntu"
#
K8S_GPG_KEY_URL="https://packages.cloud.google.com/apt/doc/apt-key.gpg"
K8S_APT_URL="https://apt.kubernetes.io"
#
KUBELET_VERSION="1.13.5-00"
KUBEADM_VERSION="1.13.5-00"
KUBECTL_VERSION="1.13.5-00"
#
POD_NETWORK_CIDR="10.244.0.0/16"
#
KUBE_FLANNEL_URL="https://raw.githubusercontent.com/coreos/flannel/bc79dd1505b0c8681ece4de4c0d86c5cd2643275/Documentation/kube-flannel.yml"

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Install docker
curl -fsSL ${DOCKER_GPG_KEY_URL} | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] ${DOCKER_APT_URL} $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce=${DOCKER_CE_VERSION}
sudo apt-mark hold docker-ce

# Install kubectl, kubeadm & kubelet
curl -fsSL ${K8S_GPG_KEY_URL} | sudo apt-key add -
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb ${K8S_APT_URL} kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y kubectl=${KUBECTL_VERSION} kubeadm=${KUBEADM_VERSION} kubelet=${KUBELET_VERSION}
sudo apt-mark hold kubectl kubeadm kubelet

# find private ip of this box and hostname
PRIVATE_IPADDR=$(ip route | tail -n 1 | cut -d' ' -f9)
HOST_NAME=$(hostname -s)
# Bootstrap kubeadm to initialize the cluster using the IP range for Flannel and for Private IP Address
sudo kubeadm init --apiserver-advertise-address=${PRIVATE_IPADDR} --apiserver-cert-extra-sans=${PRIVATE_IPADDR}  --node-name ${HOST_NAME} --pod-network-cidr=${POD_NETWORK_CIDR}
#
mkdir -p ${HOME}/.kube
sudo cp /etc/kubernetes/admin.conf ${HOME}/.kube/config
sudo chown $(id -u):$(id -g) ${HOME}/.kube/config
#
kubectl version

sudo kubeadm token create --print-join-command | sudo tee /etc/kubeadm_join_cmd.sh
sudo chmod +x /etc/kubeadm_join_cmd.sh

# required for setting up password less ssh between guest VMs
sudo sed -i "/^[^#]*PasswordAuthentication[[:space:]]no/c\PasswordAuthentication yes" /etc/ssh/sshd_config
sudo service sshd restart

# Turn on iptable bridge
echo "net.bridge.bridge-nf-call-iptables=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
#
# Add flannel networking
kubectl apply -f ${KUBE_FLANNEL_URL}
