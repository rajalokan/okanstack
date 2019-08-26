#!/usr/bin/env bash
function bootstrap_minikube_ubuntu {
    _bootstrap_minikube
}
function bootstrap_minikube_centos {
    _bootstrap_minikube
}

function _bootstrap_minikube {
    _log "Bootstrapping Minikube"

    # Install docker runtime container
    install docker

    # Install kubectl
    _log "Installing kubectl"
    curl -q -Lo kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl 2>/dev/null
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/

    # Install minikube
    _log "Installing Minikube"
    curl -q -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 2>/dev/null
    chmod +x minikube
    sudo mv minikube /usr/local/bin/

    # Setup minikube
    echo "127.0.0.1 minikube minikube." | sudo tee -a /etc/hosts
    mkdir -p $HOME/.minikube
    mkdir -p $HOME/.kube
    touch $HOME/.kube/config

    export KUBECONFIG=$HOME/.kube/config
    sudo chown -R $USER:$USER $HOME/.kube
    sudo chown -R $USER:$USER $HOME/.minikube

    export MINIKUBE_WANTUPDATENOTIFICATION=false
    export MINIKUBE_WANTREPORTERRORPROMPT=false
    export MINIKUBE_HOME=$HOME
    export CHANGE_MINIKUBE_NONE_USER=true


    # export MINIKUBE_HOME=$HOME/.minikube

    # Fix in kubeadm
    echo '1' | sudo tee /proc/sys/net/bridge/bridge-nf-call-iptables
    sudo swapoff -a

    # Start minikube
    _log "Starting Minikube"
    sudo -E minikube start --vm-driver none

    # sudo -E minikube addons enable dashboard

    # minikube status

    #statements
}
