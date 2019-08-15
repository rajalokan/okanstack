#!/usr/bin/env bash


function install_docker_centos {
    _log "Installing Docker"
    # Add the Docker repo and install Docker --------------------------------------
    sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    sudo yum install -y docker-ce
    #
    # Set the cgroup driver for Docker to systemd
    sudo sed -i '/^ExecStart/ s/$/ --exec-opt native.cgroupdriver=systemd/' /usr/lib/systemd/system/docker.service
    #
    # reload systemd, enable and start Docker
    sudo systemctl daemon-reload
    sudo systemctl enable docker --now
}
