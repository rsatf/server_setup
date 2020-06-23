#!/usr/bin/env bash

# This is what the below firewall rules will look like if run in "extended" mode (-f)
# to                                  action              from
# --                                  ------              ----
# 42976/tcp (OpenSSH)                 allow in            anywhere
# 80,443/tcp (Nginx Full)             allow in            anywhere
# 127.0.0.1 587 (Postfix Submission)  allow in            127.0.0.1
# 4380/udp (Valve)                    allow in            anywhere
# 27000:27100 udp (Valve)             allow in            anywhere
# 27000:27100 tcp (Valve)             allow in            anywhere
# 30000:30020 tcp (Valve)             allow in            anywhere
# 40000:40020 tcp (Valve)             allow in            anywhere
# 51840/udp (Valve undocumented port) allow out           anywhere


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

_getopts() {
    while getopts "seh" arg; do
    case "${arg}" in
        s)
            exec_simple=0
            ;;
        e)
            exec_extended=0
            ;;
        h | *)
            _help
            ;;
    esac
    done
    shift $((OPTIND-1))
}

_usage() {
    printf "%s\n" "Usage: ./$0 [-s] [-e] [-h]"
}

_help() {
    _usage
    printf "%s\t%s\n" "-s" "Simplified mode - Applies the least amount of firewall rules needed for peripheral games servers"
    printf "%s\t%s\n" "-e" "Extended mode - Applies extra firewall rules needed for extra services such as Nginx for FastDL"
    printf "%s\t%s\n" "-h" "Displays this help :)"
    exit 0
}

simple_rules() {
    # Block all incoming to close unused ports
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    # Allow our bespoke OpenSSH port
    _debug "${FUNCNAME[0]}" "Enabling OpenSSH on port ${ssh_port}"
    sudo ufw allow "${ssh_port}"/tcp comment "OpenSSH"

    # Allow all possible 'valid' valve ports
    _debug "${FUNCNAME[0]}" "Enabling UDP port 4380 for Valve"
    sudo ufw allow 4380/udp comment "Valve"
    _debug "${FUNCNAME[0]}" "Enabling TCP port range 27000:27100 for Valve"
    sudo ufw allow 27000:27100/tcp comment "Valve"
    _debug "${FUNCNAME[0]}" "Enabling UDP port range 27000:27100 for Valve"
    sudo ufw allow 27000:27100/udp comment "Valve"
    _debug "${FUNCNAME[0]}" "Enabling TCP port range 30000:30020 for Valve"
    sudo ufw allow 30000:30020/tcp comment "Valve Steam Port"
    _debug "${FUNCNAME[0]}" "Enabling UDP port range 30000:30020 for Valve"
    sudo ufw allow 30000:30020/udp comment "Valve Steam Port"
    _debug "${FUNCNAME[0]}" "Enabling TCP port range 40000:40020 for Valve"
    sudo ufw allow 40000:40020/tcp comment "Valve Client Port"
    _debug "${FUNCNAME[0]}" "Enabling UDP port range 40000:40020 for Valve"
    sudo ufw allow 40000:40020/udp comment "Valve Client Port"
    _debug "${FUNCNAME[0]}" "Enabling UDP port 52840 for Valve"
    sudo ufw allow out 51840/udp comment "Valve undocumented port"
}

extended_rules() {
    # Allow Nginx for website/FastDL
    _debug "${FUNCNAME[0]}" "Enabling ports 80 and 443 for Nginx"
    sudo ufw allow 80,443/tcp comment "Nginx Full"
    
    # Allow Postfix
    _debug "${FUNCNAME[0]}" "Enabling Skibas random Postfix Submission port requirement xD"
    sudo ufw allow from 127.0.0.1 to any port 587 comment "Postfix Submission"
}

main () {
    ssh_port=42976
    exec_simple=""
    exec_extended=""
    _getopts "${@}"

    if [[ -z "${exec_simple}" ]] && [[ -z "${exec_extended}" ]]; then
        _debug "${FUNCNAME[0]}" "No option passed to the script, running in simple mode"
        exec_simple="0"
        exec_extended="1"
    elif [[ -n "${exec_simple}" ]] && [[ -n "${exec_extended}" ]]; then
        _debug "${FUNCNAME[0]}" "Both -s and -e passed to she script, running in extended mode"
        exec_simple="1"
        exec_extended="0"
    fi

    printf "Simple: %s\n" "${exec_simple}"
    printf "Extended: %s\n" "${exec_extended}"

    _debug "${FUNCNAME[0]}" "Ensuring efw is disabled"
    sudo ufw disable

    if [[ -n "${exec_simple}" ]] && [[ "${exec_simple}" -eq 0 ]]; then
        _debug "${FUNCNAME[0]}" "Applying simple ufw rules"
        simple_rules
    fi

    if [[ -n "${exec_extended}" ]] && [[ "${exec_extended}" -eq 0 ]]; then
        _debug "${FUNCNAME[0]}" "Applying extended ufw rules"
        simple_rules
        extended_rules
    fi

    _debug "${FUNCNAME[0]}" "Enabling ufw to apply new rules, remember to connect to SSH on ${ssh_port} if not already"
    sudo ufw enable

    _debug "${FUNCNAME[0]}" "Checking current ufw rules"
    sudo ufw status verbose
}

main "${@}"
