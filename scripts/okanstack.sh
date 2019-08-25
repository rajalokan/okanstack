# /////////////////////// OpenStack Functions /////////////////////////////////

function bootstrap_openstack_vm {
    _display_inputs
    _boot
    # _add_floating_ip
    # _assign_instance_ip
    # _add_to_ssh_config
    # _verify_ssh
    # _preconfigure_instance ${SERVER_NAME}
}

function _display_inputs {
    OS_TYPE=${__OS_TYPE:-"ubuntu"}
    # Set INSTANCE_NAME
    APPEND_ALOK=${__APPEND_ALOK:-"true"}
    SERVER_NAME=${__SERVER_NAME:-""}
    if [[ -z ${SERVER_NAME} ]]; then
        _error "Insufficient values. Please provide variable '__SERVER_NAME'"
        _error "Exiting....."
        return
    fi
    if [[ ${APPEND_ALOK} == "true" ]]; then
        INSTANCE_NAME="alok-${__SERVER_NAME}"
    elif [[ ${APPEND_ALOK} == "false" ]]; then
        INSTANCE_NAME=${__SERVER_NAME}
    fi
    # Set IMAGE
    [[ ${OS_TYPE} == "ubuntu" ]] && IMAGE="ubuntu-16.04" || IMAGE="centos7.4-1802"
    # Set NETWORK
    NETWORK=${__NETWORK_NAME:-"alok"}
    # Set FLAVOR
    FLAVOR=${__FLAVOR:-"m1.small"}
    # Set Security Group
    SEC_GROUP=${__SECGRP_NAME:-"default"}
    # Set Key
    KEY_NAME=${__KEY_NAME:-"alok_cloud"}
    # Whether to add public key or not
    ADD_PUBLIC_IP=${__ADD_PUBLIC_IP:-"true"}
    # public IP
    PUBLIC_IP=${__PUBLIC_IP:-""}
    # Set ssh user
    [[ ${OS_TYPE} == "ubuntu" ]] && SSH_USER="ubuntu" || SSH_USER="centos"

    info_block "Configuration of new VM will be:"
    _log "Name            : ${INSTANCE_NAME}"
    _log "Image           : ${IMAGE}"
    _log "Network         : ${NETWORK}"
    _log "Flavor          : ${FLAVOR}"
    _log "SecGroup        : ${SEC_GROUP}"
    _log "Key             : ${KEY_NAME}"
    _log "ADD_PUBLIC_IP   : ${ADD_PUBLIC_IP}"
    _log "IP              : ${PUBLIC_IP}"
    _log "User            : ${SSH_USER}"
}

function _boot {
    info_block "Booting new ${SERVER_NAME} VM"
    echo "openstack server create --image ${IMAGE} --flavor ${FLAVOR} --security-group ${SEC_GROUP} --key-name ${KEY_NAME} --network ${NETWORK} ${INSTANCE_NAME}"
    openstack server create --image ${IMAGE} --flavor ${FLAVOR} --security-group ${SEC_GROUP} --key-name ${KEY_NAME} --network ${NETWORK} ${INSTANCE_NAME}
    if [ $? -eq 0 ]; then
        _log "VM booted. Waiting for its status to turn ACTIVE"
        for i in {1..5}; do [[ $(openstack server show --insecure ${INSTANCE_NAME} -f value -c status) == "ACTIVE" ]] && break || sleep 5; done
        _list_servers ${INSTANCE_NAME}
    fi
}

function _add_floating_ip {
    if [[ ! -z ${PUBLIC_IP} ]]; then
        _log "Adding floating ip ${PUBLIC_IP} to ${INSTANCE_NAME}"
        openstack server add floating ip ${INSTANCE_NAME} ${PUBLIC_IP}
    elif [[ ${ADD_PUBLIC_IP} = "true" ]]; then
        PUBLIC_IP=$(openstack floating ip list --status DOWN -f value -c "Floating IP Address" | head -n 1)
        _log "Adding floating ip ${PUBLIC_IP} to ${INSTANCE_NAME}"
        openstack server add floating ip --insecure ${INSTANCE_NAME} ${PUBLIC_IP}
    fi
    _list_servers ${INSTANCE_NAME}
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
    info_block "Configuring ${SERVER_NAME} for ssh"
    HOST="${SERVER_NAME}"
    [[ ${KEY_NAME} == "alok_cloud" ]] && SSH_KEY="alokcloud" || SSH_KEY="alokaptira"
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
}

function _verify_ssh {
    ssherr="port 22: Connection refused"
    until $(ssh ${SERVER_NAME} exit); do
        error=$(ssh ${SERVER_NAME} exit 2>&1)
        if [[ $error == *$ssherr* ]]; then
            _log "server not setup for ssh yet. Sleeping for 5 sec and trying again"
            sleep 5
        else
            ssh-keygen -f "/home/${USER}/.ssh/known_hosts" -R ${INSTANCE_IP}; \
        fi
    done
    _log "SSH for ${SERVER_NAME} successful"
}

function _list_servers {
    _log "Listing servers"
    if [[ -z ${APPEND_ALOK} ]]; then
        openstack server list | grep alok
    else
        openstack server list | grep $1
    fi
}

function _preconfigure_instance {
    info_block "Preconfiguring ${SERVER_NAME}"
    SERVER_NAME=${1:-}
    ssh -T ${SERVER_NAME} << EOF
        url="https://raw.githubusercontent.com/rajalokan/okanstack/master/sclib.sh"
        sudo apt install -y wget || sudo yum install -y wget
        [[ -f /tmp/sclib.sh ]] || wget -q  $url -O /tmp/sclib.sh
        source /tmp/sclib.sh

        preconfigure ${SERVER_NAME}
EOF
    _log "Successfully preconfigured ${SERVER_NAME}"
}
