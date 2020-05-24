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

# NativeVotes - https://github.com/powerlord/sourcemod-nativevotes
# nativevotes.smx
# nativevotes_nominations.smx
# nativevotes_rockthevote.smx
# nativevotes_mapchooser.smx
# disabledmgemod.smx
# soap_tf2dm.smx
# soap_tournament.smx

tf2-comp-fixes() {
    # https://github.com/ldesgoui/tf2-comp-fixes
    cd "${tf_home}"
    wget https://github.com/peace-maker/DHooks2/releases/download/v2.2.0-detours10/dhooks-2.2.0-detours10.zip
    unzip -o dhooks-2.2.0-detours10.zip
    rm dhooks-2.2.0-detours10.zip
    wget https://github.com/ldesgoui/tf2-comp-fixes/releases/download/v1.8.0/tf2-comp-fixes.zip
    unzip -o tf2-comp-fixes.zip
    rm tf2-comp-fixes.zip
}

f2-plugins-updated() {
    # https://github.com/stephanieLGBT/f2-plugins-updated
    # Does not install/compile STV related plugins
    cd "${tf_home}"
    wget https://github.com/stephanieLGBT/f2-plugins-updated/archive/master.zip
    unzip -o master.zip
    rm master.zip
    find f2-plugins-updated-master/ -type f -name "*.smx" ! -name "*stv*" -exec mv {} "${smx_dir}" \;
    # # Copy includes needed for compilation
    # cp -rv f2-plugins-updated-master/scripting/include/ "${script_dir}"
    # # Download smlib
    # wget https://raw.githubusercontent.com/bcserv/smlib/master/scripting/include/smlib.inc -P "${script_dir}"/include/
    # declare -a f2_plugins
    # mapfile -t f2_plugins < <(find . -type f -name "*.sp" ! -name "*stv*" -exec basename {} \;)
    # find . -type f -name "*.sp" ! -name "*stv*" -exec mv {} "${script_dir}" \;
    # for plugin in "${f2_plugins[@]}"; do
    #     compile_plugin "${plugin}"
    # done
    rm -rf f2-plugins-updated-master
}

plugin_pause() {
    # https://www.reddit.com/r/truetf2/comments/9us0yi/updated_pause_plugin_from_rglgg_to_fix_medics/
    cd "${tf_home}"
    # wget https://cdn.discordapp.com/attachments/326573943555096576/509457006462238731/pause.sp
    # mv pause.sp "${script_dir}"
    # compile_plugin pause.sp
    wget https://cdn.discordapp.com/attachments/480167194987331584/508842853389041665/pause.smx
    mv pause.smx "${script_dir}"
}

plugin_swapteam() {
    # https://forums.alliedmods.net/showthread.php?t=95968
    cd "${tf_home}"
    curl "https://forums.alliedmods.net/attachment.php?attachmentid=110181&d=1348956706" --output swapteam.zip
    unzip -o swapteam.zip
    # mv sourcemod/scripting/swapteam.sp "${script_dir}"
    mv sourcemod/plugins/swapteam.smx "${smx_dir}"
    rm swapteam.zip
    rm -rf sourcemod/
    # compile_plugin swapteam.sp
}

plugin_afk() {
    # https://www.teamfortress.tv/13598/medicstats-sourcemod-plugin/
    cd "${tf_home}"
    wget http://sourcemod.krus.dk/afk.zip
    unzip -o afk.zip
    mv afk.smx "${smx_dir}"
    rm afk.zip
}

compile_plugin() {
    # Assumes that the plugin.sp file already exists in "${script_dir}"
    _debug "${FUNCNAME[0]}" "Compiling plugin ${1}"
    plugin="${1%.*}"
    cd "${script_dir}"
    ./compile.sh "${plugin}".sp
    mv compiled/"${plugin}".smx ../plugins/
    cd -
}


disable_plugins() {
    declare -a to_disable
    to_disable=( funcommands.smx  nextmap.smx funvotes.smx )
    cd "${smx_dir}"
    for plugin in "${to_disable[@]}"; do
        _debug "${FUNCNAME[0]}" "Disabling ${plugin}"
        mv "${plugin}" disabled/
    done
}

main() {
    tf_home="/home/steam/tf2/server/tf"
    script_dir="${tf_home}/addons/sourcemod/scripting"
    smx_dir="${tf_home}/addons/sourcemod/plugins"

    _debug "${FUNCNAME[0]}" "Installing tf2-comp-fixes from https://github.com/ldesgoui/tf2-comp-fixes"
    tf2-comp-fixes

    _debug "${FUNCNAME[0]}" "Installing f2-plugins-updated from https://github.com/stephanieLGBT/f2-plugins-updated"
    f2-plugins-updated

    _debug "${FUNCNAME[0]}" "Installing pause.smx"
    plugin_pause

    _debug "${FUNCNAME[0]}" "Installing swapteam.smx"
    plugin_swapteam

    _debug "${FUNCNAME[0]}" "Installing afk.smx"
    plugin_afk

    _debug "${FUNCNAME[0]}" "Disabling listed plugins"
    disable_plugins
}

main "${@}"