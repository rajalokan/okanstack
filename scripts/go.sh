#!/usr/bin/env bash

function install_go_ubuntu {
    _install_go
}

function install_go_centos {
    _install_go
}

function _install_go() {
    VERSION="1.13"
    OS="linux"
    ARCH="amd64"
    wget -q https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
    sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
}
