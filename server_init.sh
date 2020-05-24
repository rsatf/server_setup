#!/usr/bin/env bash

# Exit on command fail
set -e
# Don't conceal errors in pipes
set -o pipefail
# Exit if there are unset variables
set -u

script_dir="$(dirname "${BASH_SOURCE[0]}")"

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
    sudo adduser --disabled-password --gecos "" "${user}"
}

add_groups() {
    group="${1}"
    _debug "${FUNCNAME[0]}" "Adding group: ${group}"
    sudo addgroup "${group}"
}

change_sshd_config() {
    _debug "${FUNCNAME[0]}" "Disabling SSH password based authentication"
    # Disable password authentication
    sudo sed -i "/PasswordAuthentication yes/c\PasswordAuthentication no" /etc/ssh/sshd_config
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
    curl -s http://169.254.169.254/latest/meta-data/instance-id/ -m 1 > /dev/null
    rc="${?}"
    if [[ "${rc}" -gt 0 ]]; then
        _debug "${FUNCNAME[0]}" "Server is not an AWS EC2 instance"
        is_aws="1"
    else
        _debug "${FUNCNAME[0]}" "Server is an AWS EC2 instance"
        is_aws="0"
    fi
}

change_hostname() {
    sudo hostnamectl set-hostname "${new_hostname}"
    printf "127.0.1.1\t%s\n" "${new_hostname}" | sudo tee -a /etc/hosts
}

add_key_to_users() {
    for user in "${new_users[@]}"; do
        sudo mkdir /home/"${user}"/.ssh
        sudo chmod 700 /home/"${user}"/.ssh
        sudo touch /home/"${user}"/.ssh/authorized_keys
        sudo chmod 600 /home/"${user}"/.ssh/authorized_keys
        sudo chown -R "${user}":"${user}" /home/"${user}"/.ssh
        cat ~/.ssh/authorized_keys | sudo tee -a /home/"${user}"/.ssh/authorized_keys > /dev/null
    done
}

main() {
    # The new hostname of this server will be a subdomain of rsa.tf: ${new_hostname}.rsa.tf
    new_hostname="cpt2"
    declare -a new_users
    declare -a new_groups
    new_users+=( russ ant )
    new_groups+=( rsatf )
    declare -a expire_accounts
    expire_accounts+=( ubuntu root )
    ssh_port=42976
    is_aws=""

    _debug "${FUNCNAME[0]}" "Installing apt packages"
    sudo apt install -y unzip
    
    _debug "${FUNCNAME[0]}" "Changing server hostname to ${new_hostname}"
    change_hostname

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

    # Add each group in "${new_groups}" to sudoers
    printf "%s\n" "# sudo groups added by ${0} script" | sudo EDITOR='tee -a' visudo > /dev/null
    for group in "${new_groups[@]}"; do
        printf "%s\tALL=(ALL)\tNOPASSWD:ALL\n" "%${group}" | sudo EDITOR='tee -a' visudo
    done

    _debug "${FUNCNAME[0]}" "Adding current users authorized_keys to all new users"
    add_key_to_users

    # Disable specified accounts
    for account in "${expire_accounts[@]}"; do
        disable_account "${account}"
    done

    _debug "${FUNCNAME[0]}" "Checking if server is an AWS EC2 instance"
    aws_check

    if [[ -f "${script_dir}"/ufw_rules.sh ]]; then
        if [[ "${is_aws}" -eq 0 ]]; then
            "${script_dir}"/ufw_rules.sh -s
            _debug "${FUNCNAME[0]}" "REMINDER: Don't forget to add the new ssh port to your Security Groups!"
        else
            "${script_dir}"/ufw_rules.sh -e
        fi
    else
        _debug "${FUNCNAME[0]}" "ufw_rules.sh was not found to be run"
    fi

    _debug "${FUNCNAME[0]}" "Changing SSH config, this may drop your connection."
    change_sshd_config

    _debug "${FUNCNAME[0]}" "Script complete."
}

main "${@}"