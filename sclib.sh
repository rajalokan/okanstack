#!/usr/bin/env bash

## Vars ----------------------------------------------------------------------
# PIP_INSTALL_OPTIONS=${PIP_INSTALL_OPTIONS:-'pip==9.0.1 setuptools==33.1.1 wheel==0.29.0 '}
PIP_INSTALL_OPTIONS=${PIP_INSTALL_OPTIONS:-'pip==9.0.1'}

function is_sclib_imported {
    [[ 0 ]]
}

function print_info {
  RED='\033[0;33m'
  NC='\033[0m' # No Color
  # PROC_NAME="- [ $@ ] -"
  PROC_NAME="${RED}- [ $@ ] -${NC}"
  # printf "\n%s%s\n" "$PROC_NAME" "${LINE:${#PROC_NAME}}"
  printf "$PROC_NAME\n"
}

function info_block {
  echo "${LINE}"
  print_info "$@"
  echo "${LINE}"
}

function _log {
  RED='\033[0;35m'
  NC='\033[0m' # No Color
  printf "${RED}- $@${NC}\n"
}

function _error {
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${RED}$@${NC}\n"
}

function GetanotherVersion {
 echo "Not Implemented"
}

function _source_file {
  if [[ ! -z $1 ]]; then
    source "${CURRENT_DIR}/../${1}"
  fi
}

function get_pip {

  # check if pip is already installed
  if [ "$(which pip)" ]; then

    # make sure that the right pip base packages are installed
    # If this fails retry with --isolated to bypass the repo server because the repo server will not have
    # been updated at this point to include any newer pip packages.
    sudo -H pip install --upgrade ${PIP_INSTALL_OPTIONS} || sudo -H pip install --upgrade --isolated ${PIP_INSTALL_OPTIONS}

    # Ensure that our shell knows about the new pip
    hash -r pip

  # when pip is not installed, install it
  else

    # If GET_PIP_URL is set, then just use it
    if [ -n "${GET_PIP_URL:-}" ]; then
      curl --silent ${GET_PIP_URL} > /opt/get-pip.py
      if head -n 1 /opt/get-pip.py | grep python; then
        python /opt/get-pip.py ${PIP_INSTALL_OPTIONS}
        return
      fi
    fi

    # Try getting pip from bootstrap.pypa.io as a primary source
    curl --silent https://bootstrap.pypa.io/get-pip.py > /opt/get-pip.py
    if head -n 1 /opt/get-pip.py | grep python; then
      sudo -H python /opt/get-pip.py ${PIP_INSTALL_OPTIONS}
      return
    fi

    # Try the get-pip.py from the github repository as a primary source
    curl --silent https://raw.githubusercontent.com/pypa/get-pip/master/get-pip.py > /opt/get-pip.py
    if head -n 1 /opt/get-pip.py | grep python; then
      sudo -H python /opt/get-pip.py ${PIP_INSTALL_OPTIONS}
      return
    fi

    echo "A suitable download location for get-pip.py could not be found."
    exit_fail
  fi
}

# ==============================================================================
# GetOSVersion
function GetOSVersion {

    # Figure out which vendor we are
    if [[ -x "`which sw_vers 2>/dev/null`" ]]; then
        # OS/X
        os_VENDOR=`sw_vers -productName`
        os_RELEASE=`sw_vers -productVersion`
        os_UPDATE=${os_RELEASE##*.}
        os_RELEASE=${os_RELEASE%.*}
        os_PACKAGE=""
        if [[ "$os_RELEASE" =~ "10.7" ]]; then
            os_CODENAME="lion"
        elif [[ "$os_RELEASE" =~ "10.6" ]]; then
            os_CODENAME="snow leopard"
        elif [[ "$os_RELEASE" =~ "10.5" ]]; then
            os_CODENAME="leopard"
        elif [[ "$os_RELEASE" =~ "10.4" ]]; then
            os_CODENAME="tiger"
        elif [[ "$os_RELEASE" =~ "10.3" ]]; then
            os_CODENAME="panther"
        else
            os_CODENAME=""
        fi
    elif [[ -x $(which lsb_release 2>/dev/null) ]]; then
        os_VENDOR=$(lsb_release -i -s)
        os_RELEASE=$(lsb_release -r -s)
        os_UPDATE=""
        os_PACKAGE="rpm"
        if [[ "Debian,Ubuntu,LinuxMint" =~ $os_VENDOR ]]; then
            os_PACKAGE="deb"
        elif [[ "SUSE LINUX" =~ $os_VENDOR ]]; then
            lsb_release -d -s | grep -q openSUSE
            if [[ $? -eq 0 ]]; then
                os_VENDOR="openSUSE"
            fi
        elif [[ $os_VENDOR == "openSUSE project" ]]; then
            os_VENDOR="openSUSE"
        elif [[ $os_VENDOR =~ Red.*Hat ]]; then
            os_VENDOR="Red Hat"
        fi
        os_CODENAME=$(lsb_release -c -s)
    elif [[ -r /etc/redhat-release ]]; then
        # Red Hat Enterprise Linux Server release 5.5 (Tikanga)
        # Red Hat Enterprise Linux Server release 7.0 Beta (Maipo)
        # CentOS release 5.5 (Final)
        # CentOS Linux release 6.0 (Final)
        # Fedora release 16 (Verne)
        # XenServer release 6.2.0-70446c (xenenterprise)
        # Oracle Linux release 7
        # CloudLinux release 7.1
        os_CODENAME=""
        for r in "Red Hat" CentOS Fedora XenServer CloudLinux; do
            os_VENDOR=$r
            if [[ -n "`grep \"$r\" /etc/redhat-release`" ]]; then
                ver=`sed -e 's/^.* \([0-9].*\) (\(.*\)).*$/\1\|\2/' /etc/redhat-release`
                os_CODENAME=${ver#*|}
                os_RELEASE=${ver%|*}
                os_UPDATE=${os_RELEASE##*.}
                os_RELEASE=${os_RELEASE%.*}
                break
            fi
            os_VENDOR=""
        done
        if [ "$os_VENDOR" = "Red Hat" ] && [[ -r /etc/oracle-release ]]; then
            os_VENDOR=OracleLinux
        fi
        os_PACKAGE="rpm"
    elif [[ -r /etc/SuSE-release ]]; then
        for r in openSUSE "SUSE Linux"; do
            if [[ "$r" = "SUSE Linux" ]]; then
                os_VENDOR="SUSE LINUX"
            else
                os_VENDOR=$r
            fi

            if [[ -n "`grep \"$r\" /etc/SuSE-release`" ]]; then
                os_CODENAME=`grep "CODENAME = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_RELEASE=`grep "VERSION = " /etc/SuSE-release | sed 's:.* = ::g'`
                os_UPDATE=`grep "PATCHLEVEL = " /etc/SuSE-release | sed 's:.* = ::g'`
                break
            fi
            os_VENDOR=""
        done
        os_PACKAGE="rpm"
    # If lsb_release is not installed, we should be able to detect Debian OS
    elif [[ -f /etc/debian_version ]] && [[ $(cat /proc/version) =~ "Debian" ]]; then
        os_VENDOR="Debian"
        os_PACKAGE="deb"
        os_CODENAME=$(awk '/VERSION=/' /etc/os-release | sed 's/VERSION=//' | sed -r 's/\"|\(|\)//g' | awk '{print $2}')
        os_RELEASE=$(awk '/VERSION_ID=/' /etc/os-release | sed 's/VERSION_ID=//' | sed 's/\"//g')
    fi
    export os_VENDOR os_RELEASE os_UPDATE os_PACKAGE os_CODENAME
}

# Distro-agnostic function to tell if a package is installed
# is_package_installed package [package ...]
function is_package_installed {
    if [[ -z "$@" ]]; then
        return 1
    fi

    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi

    if [[ "$os_PACKAGE" = "deb" ]]; then
        dpkg -s "$@" > /dev/null 2> /dev/null
    elif [[ "$os_PACKAGE" = "rpm" ]]; then
        rpm --quiet -q "$@"
    else
        exit_distro_not_supported "finding if a package is installed"
    fi
}

# Determine if current distribution is a Fedora-based distribution
# (Fedora, RHEL, CentOS, etc).
# is_fedora
function is_fedora {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "Fedora" ] || [ "$os_VENDOR" = "Red Hat" ] || \
        [ "$os_VENDOR" = "CentOS" ] || [ "$os_VENDOR" = "OracleLinux" ] || \
        [ "$os_VENDOR" = "CloudLinux" ]
}


# Determine if current distribution is a SUSE-based distribution
# (openSUSE, SLE).
# is_suse
function is_suse {
    if [[ -z "$os_VENDOR" ]]; then
        GetOSVersion
    fi

    [ "$os_VENDOR" = "openSUSE" ] || [ "$os_VENDOR" = "SUSE LINUX" ]
}

# Determine if current distribution is an Ubuntu-based distribution
# It will also detect non-Ubuntu but Debian-based distros
# is_ubuntu
function is_ubuntu {
    if [[ -z "$os_PACKAGE" ]]; then
        GetOSVersion
    fi
    [ "$os_PACKAGE" = "deb" ]
}


# Wrapper for ``yum`` to set proxy environment variables
# Uses globals ``OFFLINE``, ``*_proxy``, ``YUM``
# yum_install package [package ...]
function yum_install {
    [[ "$OFFLINE" = "True" ]] && return
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"

    # The manual check for missing packages is because yum -y assumes
    # missing packages are OK.  See
    # https://bugzilla.redhat.com/show_bug.cgi?id=965567
    $sudo http_proxy="${http_proxy:-}" https_proxy="${https_proxy:-}" \
        no_proxy="${no_proxy:-}" \
        ${YUM:-yum} install -y "$@" 2>&1 | \
        awk '
            BEGIN { fail=0 }
            /No package/ { fail=1 }
            { print }
            END { exit fail }' || \
                die $LINENO "Missing packages detected"

    # also ensure we catch a yum failure
    if [[ ${PIPESTATUS[0]} != 0 ]]; then
        die $LINENO "${YUM:-yum} install failure"
    fi
}

# Wrapper for ``apt-get`` to set cache and proxy environment variables
# Uses globals ``OFFLINE``, ``*_proxy``
# apt_get operation package [package ...]
function apt_get {
    local xtrace=$(set +o | grep xtrace)
    set +o xtrace
    [[ "$OFFLINE" = "True" || -z "$@" ]] && return
    local sudo="sudo"
    [[ "$(id -u)" = "0" ]] && sudo="env"
    $xtrace
    $sudo DEBIAN_FRONTEND=noninteractive \
        http_proxy=${http_proxy:-} https_proxy=${https_proxy:-} \
        no_proxy=${no_proxy:-} \
        apt-get --option "Dpkg::Options::=--force-confold" --assume-yes "$@"
}

# Distro-agnostic package installer
# Uses globals ``NO_UPDATE_REPOS``, ``REPOS_UPDATED``, ``RETRY_UPDATE``
# install_package package [package ...]
function update_package_repo {
    NO_UPDATE_REPOS=${NO_UPDATE_REPOS:-False}
    REPOS_UPDATED=${REPOS_UPDATED:-False}
    RETRY_UPDATE=${RETRY_UPDATE:-False}

    if [[ "$NO_UPDATE_REPOS" = "True" ]]; then
        return 0
    fi

    if is_ubuntu; then
        local xtrace=$(set +o | grep xtrace)
        set +o xtrace
        if [[ "$REPOS_UPDATED" != "True" || "$RETRY_UPDATE" = "True" ]]; then
            # if there are transient errors pulling the updates, that's fine.
            # It may be secondary repositories that we don't really care about.
	    apt_get update  || /bin/true
            REPOS_UPDATED=True
        fi
        $xtrace
    fi
}

function real_install_package {
    if is_ubuntu; then
        apt_get install "$@"
    elif is_fedora; then
        yum_install "$@"
    elif is_suse; then
        zypper_install "$@"
    else
        exit_distro_not_supported "installing packages"
    fi
}

# Distro-agnostic package installer
# install_package package [package ...]
function install_package {
    # update_package_repo
    _log "Installing package $@"
    real_install_package $@ || RETRY_UPDATE=True update_package_repo && real_install_package $@
}

function backup_if_present(){
    if [ -L $1 ]; then
        _log "Deleting link $1"
        rm $1
    elif [[ -f $1 ]] || [[ -d $2 ]]; then
        _log "Backing up $1 to $1.bak.$(date +"%d_%m_%Y_%H%M%S")"
        mv $1 $1.bak.$(date +"%d_%m_%Y_%H%M%S")
    fi
}

function run_ansible_role {
    role=$1
    [[ -z $3 ]] && TAGS="" || TAGS="--tags $3"
    _log "Running ansible role $1"

    ansible_roles_path="${HOME}/.ansible/roles"
    mkdir -p ${ansible_roles_path}

    role_path="${ansible_roles_path}/$1"
    role_repo="https://github.com/rajalokan/ansible-role-$1"

    # Ensure git is installed
    is_package_installed git || install_package git

    if [[ ! -d ${role_path} ]]; then
        git clone ${role_repo} ${role_path}
    fi

    # Ensure latest ansible is installed
    is_package_installed ansible || _install_ansible

    pushd ${role_path} >/dev/null
        ansible-playbook -i "localhost," -c local ${TAGS} playbook.yaml
    popd
}

function _install_ansible {
    if ! is_package_installed ansible; then
        if is_ubuntu; then
            sudo apt-add-repository -y ppa:ansible/ansible
            sudo apt update
        else
            sudo yum install -y epel-release
        fi
        install_package ansible
    fi
}

# ==============================================================================
# Bootstrapping a new VM
# ==============================================================================

function boot_vm {
    _display_inputs
    _boot
    _add_floating_ip
    _assign_instance_ip
    _add_to_ssh_config
    _verify_ssh
    _preconfigure_vm
}

function _display_inputs {
    APPEND_ALOK=${APPEND_ALOK:-}
    [[ -z ${APPEND_ALOK} ]] &&  INSTANCE_NAME="alok-${SERVER_NAME}" || INSTANCE_NAME="${SERVER_NAME}"
    NETWORK=${NETWORK:-"alok_net"}
    FLAVOR=${FLAVOR:-"m1.small"}
    SEC_GROUP=${SEC_GROUP:-"alok-secgrp"}
    KEY_NAME=${KEY_NAME:-"alok_cloud"}
    OS_TYPE=${OS_TYPE:-"ubuntu"}
    ADD_PUBLIC_IP=${ADD_PUBLIC_IP:-"false"}

    [[ ${OS_TYPE} == "ubuntu" ]] && SSH_USER="ubuntu" || SSH_USER="centos"
    [[ ${OS_TYPE} == "ubuntu" ]] && IMAGE="ubuntu-16.04" || IMAGE="centos7.4-1802"
    info_block "Configuration of new VM will be:"
    _log "Name            : ${INSTANCE_NAME}"
    _log "Image           : ${IMAGE}"
    _log "Network         : ${NETWORK}"
    _log "Flavor          : ${FLAVOR}"
    _log "SecGroup        : ${SEC_GROUP}"
    _log "Key             : ${KEY_NAME}"
    _log "IP              : ${PUBLIC_IP}"
    _log "ADD_PUBLIC_IP   : ${ADD_PUBLIC_IP}"
    _log "User            : ${SSH_USER}"
}

function _boot {
    info_block "Booting new VM ${SERVER_NAME}"
    openstack server create --insecure \
      --image ${IMAGE} \
      --flavor ${FLAVOR} \
      --security-group ${SEC_GROUP} \
      --key-name ${KEY_NAME} \
      --network ${NETWORK} \
      ${INSTANCE_NAME}
    _log "VM booted. Waiting for its status to turn ACTIVE"
    for i in {1..5}; do [[ $(openstack server show --insecure ${INSTANCE_NAME} -f value -c status) == "ACTIVE" ]] && break || sleep 5; done
    _list_servers
}

function _add_floating_ip {
    if [[ ! -z ${PUBLIC_IP} ]]; then
        _log "Adding floating ip ${PUBLIC_IP} to ${INSTANCE_NAME}"
        openstack server add floating ip --insecure ${INSTANCE_NAME} ${PUBLIC_IP}
    elif [[ ${ADD_PUBLIC_IP} = "true" ]]; then
        PUBLIC_IP=$(openstack floating ip list --insecure --status DOWN -f value -c "Floating IP Address" | head -n 1)
        _log "Adding floating ip ${PUBLIC_IP} to ${INSTANCE_NAME}"
        openstack server add floating ip --insecure ${INSTANCE_NAME} ${PUBLIC_IP}
    fi
    _list_servers
}

function _assign_instance_ip {
    if [[ -z ${PUBLIC_IP} ]]; then
      INSTANCE_IP=$(openstack server show --insecure -f 'value' -c 'addresses' ${INSTANCE_NAME} | cut -d'=' -f2)
    else
      INSTANCE_IP=${PUBLIC_IP}
    fi
    _log "New Instance IP is : ${INSTANCE_IP}"
}

function _add_to_ssh_config {
    HOST="${SERVER_NAME}"
    [[ ${KEY_NAME} == "alok_cloud" ]] && SSH_KEY="cloud" || SSH_KEY="alokaptira"
    host_string="Host ${HOST}"

    read -d '' new_host_string <<- EOM
Host ${HOST}
  HostName ${INSTANCE_IP}
  User ${SSH_USER}
  IdentityFile ~/.ssh/${SSH_KEY}.pem
EOM
    search=`grep "${host_string}" ~/.ssh/config`
    if [[ ${search} = ${host_string} ]]; then
        sed -i "/${host_string}/,+3 d" ~/.ssh/config
        echo "$new_host_string" >> ~/.ssh/config
    else
        echo "$new_host_string" >> ~/.ssh/config
    fi
    _log "SSH configuration updated"
    cat ~/.ssh/config
}

function _verify_ssh {
    ssh ${SERVER_NAME} exit \
      && [ $? == 0 ] \
        && _log "Success" \
        || {
          ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R ${INSTANCE_IP}; \
          ssh ${SERVER_NAME} exit && _log "Success after adding correct host key." || _error "Failed"; \
        }
}

function _list_servers {
    _log "Listing servers"
    if [[ -z ${APPEND_ALOK} ]]; then
        openstack server list --insecure | grep alok
    else
        openstack server list --insecure
    fi
}

function _preconfigure_instance {
    GetOSVersion
    SERVER_NAME=${1:-}
    sudo hostname ${SERVER_NAME}
    grep -q ${SERVER_NAME} /etc/hosts || sudo sed -i "2i127.0.1.1  ${SERVER_NAME}" /etc/hosts

    if [[ ${os_VENDOR,,} == "ubuntu" ]]; then
        sudo apt update
    elif [[ ${os_VENDOR,,} == "centos" ]]; then
        sudo yum install -y epel-release
        sudo yum install -y wget vim bash-completion
    fi
}
