#!/usr/bin/env bash

# To do: Install plugins

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

enable_32bit() {
    sudo dpkg --add-architecture i386
    sudo apt-get update
}

install_prereqs() {
    sudo apt install -y lib32tinfo5 lib32z1 libncurses5:i386 libbz2-1.0:i386 lib32gcc1 lib32stdc++6 libtinfo5:i386 libcurl3-gnutls:i386
}

dl_client() {
    mkdir "${tf_dir}"
    cd "${tf_dir}"
    wget https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz
    tar -xzvf steamcmd_linux.tar.gz
    rm steamcmd_linux.tar.gz
}

dl_server() {
    "${tf_dir}"/steamcmd.sh +login anonymous +force_install_dir "${tf_dir}"/server +app_update 232250 +quit
    mv "${HOME}"/Steam "${tf_dir}"
}

dl_metamod() {
    archive=$(basename "${metamod_archive}")
    cd "${tf_dir}"/server/tf/
    wget "${metamod_archive}"
    tar -xzvf "${archive}"
    rm "${archive}"
    cd -
}

dl_sourcemod() {
    archive=$(basename "${sourcemod_archive}")
    cd "${tf_dir}"/server/tf/
    wget "${sourcemod_archive}"
    tar -xzvf "${archive}"
    rm "${archive}"
    cd -
}

main() {
    tf_dir="${HOME}/tf2"
    metamod_archive="https://mms.alliedmods.net/mmsdrop/1.10/mmsource-1.10.7-git971-linux.tar.gz"
    sourcemod_archive="https://sm.alliedmods.net/smdrop/1.10/sourcemod-1.10.0-git6488-linux.tar.gz"
    _debug "${FUNCNAME[0]}" "Enabling 32-bit packages"
    enable_32bit

    _debug "${FUNCNAME[0]}" "Installing prerequisites"
    install_prereqs

    _debug "${FUNCNAME[0]}" "Downloading SteamCMD client"
    dl_client

    _debug "${FUNCNAME[0]}" "Downloading TF2 server"
    dl_server

    _debug "${FUNCNAME[0]}" "Downloading Metamod:Source"
    dl_metamod

    _debug "${FUNCNAME[0]}" "Downloading Sourcemod"
    dl_sourcemod
}

main "${@}"