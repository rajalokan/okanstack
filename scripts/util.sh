# //////////////////////////// Helper Functions ///////////////////////////////

function get_public_ip {
    _log $(curl -s https://ipinfo.io/ip)
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

# get pip
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
      curl --silent ${GET_PIP_URL} > /tmp/get-pip.py
      if head -n 1 /tmp/get-pip.py | grep python; then
        python /tmp/get-pip.py ${PIP_INSTALL_OPTIONS}
        return
      fi
    fi

    # Try getting pip from bootstrap.pypa.io as a primary source
    curl --silent https://bootstrap.pypa.io/get-pip.py > /tmp/get-pip.py
    if head -n 1 /tmp/get-pip.py | grep python; then
      sudo -H python /tmp/get-pip.py ${PIP_INSTALL_OPTIONS}
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
