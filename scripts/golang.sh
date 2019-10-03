#!/usr/bin/env bash

function install_golang_ubuntu {
    _install_golang
}

function install_golang_centos {
    _install_golang
}

function _install_golang() {
    VERSION="1.13"
    OS="linux"
    ARCH="amd64"
    wget -q https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz
    sudo tar -C /usr/local -xzf go$VERSION.$OS-$ARCH.tar.gz
}
