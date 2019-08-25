#!/usr/bin/env bash


function setup_bash() {
    GetOSVersion
    if is_ubuntu; then
        # Fetch bashrc & profile
        file_path="$base_url/ubuntu/$os_RELEASE"
        wget -q "$file_path/bashrc" -O ~/.bashrc
        wget -q "$file_path/profile" -O ~/.profile
    elif is_fedora; then
        # Fetch bashrc & bash_profile
        file_path="$base_url/centos"
        wget -q "$file_path/bashrc" -O ~/.bashrc
        wget -q "$file_path/bash_profile" -O ~/.bash_profile
    else
        exit_distro_not_supported "Installing packages"
    fi
    # copy bashrc_okan
    wget -q "$base_url/bashrc_okan" -O ~/.bashrc_okan
    # copy bash_aliases
    wget -q "$base_url/bash_aliases" -O ~/.bash_aliases

    # Pureline
    pureline_url="https://raw.githubusercontent.com/chris-marsh/pureline/master/pureline"
    wget -q $pureline_url -O ~/.pureline
    wget -q "$base_url/pureline.conf" -O ~/.pureline.conf
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
