#!/bin/sh

# Setup Proxy
OSTYPE=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
OSTYPE=${OSTYPE%\"}
OSTYPE=${OSTYPE#\"}

if [[ ${OSTYPE} == "Ubuntu" ]]; then
    sudo bash -c 'cat > /etc/apt/apt.conf.d/01proxy << EOF
Acquire::HTTP::Proxy "http://192.168.2.184:3142";
Acquire::HTTPS::Proxy "false";
EOF'
else
    if grep -q "proxy=.*" /etc/yum.conf; then
        # Update yum config
        sudo sed -ie '/^\[main\]$/,/^\[/ s/^proxy=.*/proxy=http:\/\/192.168.2.184:3142/g' /etc/yum.conf
    else
        # If not present add line proxy=
        sudo sed -ie '/^distro.*/a proxy=http://192.168.2.184:3142' /etc/yum.conf
    fi
fi

# Configure Instance
sudo apt install -y wget || sudo yum install -y wget

# if [[ ! -f /tmp/okanstack.sh ]]; then
#     wget -q https://raw.githubusercontent.com/rajalokan/okanstack/master/okanstack.sh -O /tmp/okanstack.sh
# fi
source /tmp/okanstack.sh

# Preconfigure the instance
