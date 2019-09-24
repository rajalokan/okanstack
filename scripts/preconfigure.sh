#!/usr/bin/env bash


function configure_hosts {
    GetOSVersion
    SERVER_NAME=${1:-"playbox"}
    sudo hostname ${SERVER_NAME}
    grep -q ${SERVER_NAME} /etc/hosts || sudo sed -i "2i127.0.1.1  ${SERVER_NAME}" /etc/hosts
}

function install_default_packages {
    if [[ ${os_VENDOR,,} == "ubuntu" ]]; then
        sudo apt update
        sudo apt -y upgrade
        sudo apt install -y bash-completion
    elif [[ ${os_VENDOR,,} == "centos" ]]; then
        sudo yum install -y epel-release bash-completion
    fi
}

function setup_bash() {
    GetOSVersion
    bash_url="$base_url/files/bash"
    # Fetch bashrc & profile
    if is_ubuntu; then
        wget -q "$bash_url/ubuntu/18.04/bashrc" -O ~/.bashrc
        wget -q "$bash_url/ubuntu/18.04/profile" -O ~/.profile
    elif is_fedora; then
        wget -q "$bash_url/centos/bashrc" -O ~/.bashrc
        wget -q "$bash_url/centos/bash_profile" -O ~/.bash_profile
    else
        exit_distro_not_supported "Installing packages"
    fi
    # copy bashrc_okan
    wget -q "$bash_url/bashrc_okan" -O ~/.bashrc_okan
    # copy bash_aliases
    wget -q "$bash_url/bash_aliases" -O ~/.bash_aliases

    # Pureline
    wget -q "$bash_url/pureline" -O ~/.pureline
    wget -q "$bash_url/pureline.conf" -O ~/.pureline.conf
}

function setup_vim() {
    is_package_installed vim || install_package vim
}

function setup_git() {
    is_package_installed git || install_package git
    # base_url="https://raw.githubusercontent.com/rajalokan/ansible-role-dotfiles/master/files/git"
    # wget -q "$base_url/gitconfig" -O ~/.gitconfig
    # wget -q "$base_url/gitignore" -O ~/.gitignore
}

function setup_tmux() {
    is_package_installed tmux || install_package tmux
    base_url="https://raw.githubusercontent.com/rajalokan/ansible-role-dotfiles/master/files/tmux"
    wget -q "$file_path/tmux.conf" -O ~/.tmux.conf
}
