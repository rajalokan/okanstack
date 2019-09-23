#!/bin/bash

# Setup Proxy
OSTYPE=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
OSTYPE=${OSTYPE%\"}
OSTYPE=${OSTYPE#\"}


if [[ $# -le 1 ]]; then
    echo "Only one or less arguments provided. Probably GITHUB_TOKEN is not set. Exiting"
    exit 0
fi

GITHUB_TOKEN=$1
HOST_IP=$2


# Fail silently and exit if can't find HOST_IP
if [[ -z ${HOST_IP} ]]; then
    echo "Host IP not provided. Exiting.."
    exit 0
fi

# echo ${GITHUB_TOKEN}
if [[ -z ${GITHUB_TOKEN} ]]; then
    echo "Github token not provided. Exiting.."
    exit 0
fi


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

# Install basic packages
sudo apt install -y wget > /dev/null 2>&1 \
    || sudo yum install -y wget > /dev/null 2>&1

# Fetch latest okanstack.sh if not present
if [[ ! -f ${HOME}/.okanstack.sh ]]; then
    OKANSTACK_URL="https://${GITHUB_TOKEN}@raw.githubusercontent.com/rajalokan/okanstack/master/okanstack.sh"
    wget -q -O ${HOME}/.okanstack.sh ${OKANSTACK_URL}
fi

# Source and run preconfigure
source ${HOME}/.okanstack.sh && ostack_preconfigure
