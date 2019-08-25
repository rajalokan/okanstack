#!/usr/bin/env bash

function install_docker_ubuntu {
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce=18.06.1~ce~3-0~ubuntu
    sudo apt-mark hold docker-ce

    sudo groupadd docker
    sudo usermod -aG docker $USER
}

function install_docker_centos {
    _log "Installing Docker"
    # Add the Docker repo and install Docker ----------------------------------
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce

    # Set the cgroup driver for Docker to systemd
    sudo sed -i '/^ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/' /usr/lib/systemd/system/docker.service

    # reload systemd, enable and start Docker
    sudo systemctl daemon-reload
    sudo systemctl enable docker --now

    sudo groupadd docker
    sudo usermod -aG docker $USER
}
