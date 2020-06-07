#!/usr/bin/env bash

# Exit on command fail
set -e
# Don't conceal errors in pipes
set -o pipefail
# Exit if there are unset variables
set -u

script_path="$( cd "$(dirname "$0")" ; pwd -P )"


debug_mode="0"

_debug() {
    # _debug "${FUNCNAME[0]}" ""
    if (( "${debug_mode}" == 0 )); then
        printf "[DEBUG] $(date +%T) %s - %s\n" "${1}" "${2}"
    fi
}

_getopts() {
    # The leading colon turns on silent error reporting
    # The trailing colon checks for a parameter
    if [[ -z "${1}" ]]; then
        _help
    fi
    while getopts ":u:s:c:w:n:m:h" opt; do
        case "${opt}" in
            u)
                log_uploader="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Uploader ID set to: ${log_uploader}"
                ;;
            s)
                log_sleep="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Sleep between tries set to: ${log_sleep}"
                ;;
            c)
                log_count="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Log count set to: ${log_count}"
                ;;
            w)
                webhook_url="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Webhook URL set to: ${webhook_url}"
                ;;
            n)
                webhook_username="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Webhook Username set to: ${webhook_username}"
                ;;
            m)
                announce_message="${OPTARG}"
                _debug "${FUNCNAME[0]}" "Announcement message set to: ${announce_message}"
                ;;
            h)
                _help
                exit 0
                ;;
            \?)
                printf "Invalid option: -$OPTARG\n" >&2
                _usage
                exit 1
                ;;
            :)
                printf "Option -$OPTARG requires an argument.\n" >&2
                _usage
                exit 1
                ;;
            *)
                _help
                exit 1
                ;;
        esac
    done
    shift $((OPTIND -1))
    
    if [[ -z "${log_uploader}" ]]; then
        _debug "${FUNCNAME[0]}" "Error: An uploader (-u) must be specified."
        exit 1
    fi
}

_usage() {
    printf "%s\n" "Usage: $0 -u <SteamID64> [-s <seconds>] [-c <count>]"
}

_help() {
    _usage
    printf "%s\n" "Help:"
    printf "%s\n" "-u   -   The uploaders SteamID64 you wish to watch"
    printf "%s\n" "-m   -   The announcement message to display"
    printf "%s\n" "-s   -   The number of seconds to wait between retries when polling logs.tf"
    printf "%s\n" "-c   -   The number of logs to return on each retry"
    printf "%s\n" "-w   -   The webhook url to use"
    printf "%s\n" "-n   -   The username to be used when posting using the webhook"
    printf "%s\n" "-h   -   This help"
}

get_result() {
    curl -s "http://logs.tf/api/v1/log?uploader=${log_uploader}&limit=${log_count}"
}

process_result() {
    export success=$(echo ${result} | jq ".success")
    export results=$(echo ${result} | jq ".results")
    parameters=$(echo ${result} | jq ".parameters")
    export uploader=$(echo ${parameters} | jq -r ".uploader")
    mapfile -t all_logs < <(echo ${result} | jq -c ".logs[]")
}

process_logs() {
    # Need to use a C-style loop to iterate through the array in reverse
    for (( i=${#all_logs[@]}-1 ; i>=0 ; i-- )) ; do
        log_game=$(echo "${all_logs[i]}" | jq -r ".title")
        log_map=$(echo "${all_logs[i]}" | jq -r ".map")
        log_date=$(echo "${all_logs[i]}" | jq ".date")
        log_id=$(echo "${all_logs[i]}" | jq ".id")
        if (( "${ref_time}" < "${log_date}" )); then
            # New log file parsed by logs.tf
            announce_game "${log_game}" "${log_map}" "${log_id}"
            ref_time="${log_date}"
        else
            # Not a new log
            continue
        fi
    done
}

announce_game() {
    game="${1}"
    map="${2}"
    id="${3}"
    log_url="http://logs.tf/${id}#${log_uploader}"
    _debug "${FUNCNAME[0]}" "New game: ${game} on ${map} has been processed: http://logs.tf/${id}#${log_uploader}"
    "${script_path}"/discord.sh \
        --webhook-url="${webhook_url}" \
        --username "${webhook_username}" \
        --avatar "https://i.imgur.com/tqmHxHZ.png" \
        --text "${announce_message}" \
        --title "${map}" \
        --description "${game}" \
        --color "0x008000" \
        --url "${log_url}" \
        --author "logs.tf" \
        --author-url "http://logs.tf" \
        --thumbnail "http://logs.tf/assets/img/logo-top.png" \
        --timestamp
}

main () {
    log_uploader="76561198003234706"
    log_sleep="60"
    log_count="5"
    webhook_url="https://discord.com/api/webhooks/715826334986665984/LPE_HJTlo3sUpGdm8nfRc0kXBByXziSAyX9LJdkSVUyaonTOgEKWoK0_nJB1oZKy9J0e"
    webhook_username="Miss Pauling"
    announce_message="Whoops, this message wasn't changed!"

    set +u
    _getopts "${@}"
    set -u

    declare -a all_logs

    ref_time=$(date +%s)

    # No do-while loops in bash so call the code once before the loop :(
    result=$(get_result)
    process_result
    process_logs
    while sleep "${log_sleep}"; do
        result=$(get_result)
        process_result
        process_logs
        _debug "${FUNCNAME[0]}" "No new logs found, sleeping."
    done
}

main "${@}"
