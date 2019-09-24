#!/usr/bin/env bash

# #########################  Variables ########################################
PIP_INSTALL_OPTIONS=${PIP_INSTALL_OPTIONS:-'pip==9.0.1'}
base_url="https://raw.githubusercontent.com/rajalokan/okanstack/master"
pureline_url="https://raw.githubusercontent.com/chris-marsh/pureline/master/pureline"
TOP_DIR=$(cd $(dirname "${BASH_SOURCE[0]}") && pwd)
base_okanstack_url="https://raw.githubusercontent.com/rajalokan/okanstack/master/files/bash"


# #########################  Sclib Functions ##################################
function is_sclib_imported {
    [[ 0 ]]
}

# ############################### OSTACK ######################################
# Bootstrap
function ostack_bootstrap {
    source "$TOP_DIR/.okanstack/scripts/$1.sh"
    if is_ubuntu; then
        bootstrap_${1}_ubuntu
    elif is_fedora; then
        bootstrap_${1}_centos
    else
        exit_distro_not_supported "Bootstrapping $1"
    fi
}

# Install
function ostack_install {
    _log "Installing $1"
    source "$TOP_DIR/.okanstack/scripts/$1.sh"
    if is_ubuntu; then
        install_${1}_ubuntu
    elif is_fedora; then
        install_${1}_centos
    else
        exit_distro_not_supported "Installing $1"
    fi
}

function ostack_preconfigure {
    source "$TOP_DIR/.okanstack/scripts/preconfigure.sh"

    is_package_installed wget || install_package wget

    configure_hosts
    install_default_packages

    _log "Setting up Bash"
    setup_bash

    _log "Setting up Vim"
    # setup_vim

    _log "Setting up git"
    # setup_git
}

# ############################# Init ##########################################
function ostack_init {
    # Clone okanstack git repo
    if [[ ! -d $TOP_DIR/.okanstack ]]; then
        # Ensure git is installed
        sudo apt install -y git > /dev/null 2>&1 || sudo yum install -y git > /dev/null 2>&1
        git clone https://github.com/rajalokan/okanstack.git ${TOP_DIR}/.okanstack > /dev/null 2>&1
    fi
    source "$TOP_DIR/.okanstack/scripts/core.sh"
    source "$TOP_DIR/.okanstack/scripts/log.sh"
}

ostack_init

# ################################ END ########################################
