function install_ansible {
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
