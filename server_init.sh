#!/usr/bin/env bash

# To do: Give specified/select groups sudo
# To do: Run ufw_rules.sh 

# Exit on command fail
set -e
# Don't conceal errors in pipes
set -o pipefail
# Exit if there are unset variables
set -u

debug_mode=0
_debug() {
    # _debug "${FUNCNAME[0]}" ""
    if (( "${debug_mode}" == 0 )); then
        printf "[DEBUG] $(date +%T) %s - %s\n" "${1}" "${2}"
    fi
}

add_user() {
    user="${1}"
    _debug "${FUNCNAME[0]}" "Adding user: ${user}"
    sudo adduser "${user}"
}

add_groups() {
    group="${1}"
    _debug "${FUNCNAME[0]}" "Adding group: ${group}"
    sudo addgroup "${group}"
}

change_sshd_config() {
    _debug "${FUNCNAME[0]}" "Disabling SSH password based authentication"
    # Disable password authentication
    sudo sed -i "/PasswordAuthentication yes/c\PasswordAuthentication no" /etc/ssh/
    _debug "${FUNCNAME[0]}" "Changing SSH port to ${ssh_port}"
    sudo sed -i "/#Port 22/c\Port ${ssh_port}" /etc/ssh/sshd_config
    _debug "${FUNCNAME[0]}" "Restarting ssh service"
    sudo service ssh restart
}

disable_account() {
    account="${1}"
    _debug "${FUNCNAME[0]}" "Expiring ${account} user password"
    sudo passwd -l "${account}"
    _debug "${FUNCNAME[0]}" "Changing ${account} user shell to /usr/sbin/nologin"
    sudo usermod --shell /usr/sbin/nologin "${account}"
}

aws_check() {
    curl http://169.254.169.254/latest/meta-data/instance-id/ -m 1
    rc="${?}"
    if [[ "${rc}" -gt 0 ]]; then
        _debug "${FUNCNAME[0]}" "Server is not an EC2 instance"
        is_aws="1"
    else
        _debug "${FUNCNAME[0]}" "Serber is an AWS instance"
        is_aws="0"
    fi
}

main() {
    new_hostame="cpt2.rsa.tf"
    declare -a new_users
    declare -a new_groups
    new_users+=( russ ant )
    new_groups+=( rsatf )
    declare -a expire_accounts
    expire_accounts+=( ubuntu root )
    ssh_port=42976
    is_aws=""
    
    # Add users listed in array "${new_users}"
    for user in "${new_users[@]}"; do
        add_user "${user}"
    done

    # Add groups listed in "${new_groups}"
    for group in "${new_groups[@]}"; do
        add_groups "${group}"
    done

    # Add each user in "${new_users}" to each group in "${new_groups}"
    for user in "${new_users[@]}"; do
        for group in "${new_groups[@]}"; do
            _debug "${FUNCNAME[0]}" "Adding user ${user} to group ${group}"
            sudo usermod -aG "${group}" "${user}"
        done
    done

    # Disable specified accounts
    for account in "${expire_accounts[@]}"; do
        disable_account "${account}"
    done

}

main "${@}"