#!/usr/bin/env bash

function bootstrap_minikube_centos {
    _log "Bootstrapping Minikube"
    # Install docker runtime container
    install docker

    # Install kubectl
    _log "Installing kubectl"
    sudo bash -c 'cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF'
    sudo yum install -y kubectl

    # Install minikube
    _log "Installing Minikube"
    curl -L https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 -o /tmp/minikube-linux-amd64
    sudo install /tmp/minikube-linux-amd64 /usr/bin/minikube

    # Start minikube
    _log "Starting Minikube"
    export MINIKUBE_HOME=$HOME/.minikube
    export CHANGE_MINIKUBE_NONE_USER=true
    mkdir -p $HOME/.kube || true
    touch $HOME/.kube/config
    export KUBECONFIG=$HOME/.kube/config

    # Fix in kubeadm
    echo '1' | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables

    # Start minikube
    sudo -E minikube start --vm-driver=none
    # sudo -E minikube addons enable dashboard

    minikube status
}
