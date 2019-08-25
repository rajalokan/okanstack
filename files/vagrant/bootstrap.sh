#!/bin/bash

# Setup Proxy
OSTYPE=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
OSTYPE=${OSTYPE%\"}
OSTYPE=${OSTYPE#\"}

HOST_IP=$1
# Fail silently and exit if can't find HOST_IP
[[ -z ${HOST_IP} ]] && exit 0

if [[ ${OSTYPE} = "Ubuntu" ]]; then
    sudo tee /etc/apt/apt.conf.d/01proxy > /dev/null << EOF
Acquire::HTTP::Proxy "http://${HOST_IP}:3142";
Acquire::HTTPS::Proxy "false";
EOF
elif [[ ${OSTYPE} = "CentOS" ]]; then
    if grep -q "proxy=.*" /etc/yum.conf; then
        # Update yum config
        sudo sed -ie "/^\[main\]$/,/^\[/ s/^proxy=.*/proxy=http:\/\/${HOST_IP}:3142/g" /etc/yum.conf
    else
        # If not present add line proxy=
        sudo sed -ie "/^distro.*/a proxy=http://${HOST_IP}:3142" /etc/yum.conf
    fi
fi

# Configure Instance
sudo apt install -y wget > /dev/null 2>&1 \
    || sudo yum install -y wget > /dev/null 2>&1

if [[ ! -f /tmp/okanstack.sh ]]; then
    wget -q https://raw.githubusercontent.com/rajalokan/okanstack/master/okanstack.sh -O /tmp/okanstack.sh
fi
source /tmp/okanstack.sh && okanstack_preconfigure_vm
