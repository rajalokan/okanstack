#!/bin/sh

OSTYPE=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
OSTYPE=${OSTYPE%\"}
OSTYPE=${OSTYPE#\"}


if [ ${OSTYPE} == "Ubuntu" ]; then
    sudo bash -c 'cat > /etc/apt/apt.conf.d/01proxy << EOF
Acquire::HTTP::Proxy "http://192.168.2.184:3142";
Acquire::HTTPS::Proxy "false";
EOF'
else
    echo "Redhat system"
fi
