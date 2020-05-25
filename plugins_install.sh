#!/usr/bin/env bash

# To do: Install plugins

# Exit on command fail
set -e
# Don't conceal errors in pipes
set -o pipefail
# Exit if there are unset variables
set -u

# To do:
# Install ->
# NativeVotes - https://github.com/powerlord/sourcemod-nativevotes
# nativevotes.smx
# nativevotes_nominations.smx
# nativevotes_rockthevote.smx
# nativevotes_mapchooser.smx
# disabledmgemod.smx
# soap_tf2dm.smx
# soap_tournament.smx

debug_mode=0
_debug() {
    # _debug "${FUNCNAME[0]}" ""
    if (( "${debug_mode}" == 0 )); then
        printf "[DEBUG] $(date +%T) %s - %s\n" "${1}" "${2}"
    fi
}

continue_mode=1
_continue() {
    if (( "${continue_mode}" == 0 )); then
        read -n 1 -r -s -p $'Press enter to continue...\n'
    fi
}

extension_dhooks() {
    # https://github.com/peace-maker/DHooks2/releases
    cd "${tf_home}"
    wget https://github.com/peace-maker/DHooks2/releases/download/v2.2.0-detours10/dhooks-2.2.0-detours10-sm110.zip
    unzip -o dhooks-2.2.0-detours10-sm110.zip
    rm dhooks-2.2.0-detours10-sm110.zip
}

plugin_updater() {
    # https://forums.alliedmods.net/showthread.php?t=169095
    cd "${tf_home}"
    wget https://bitbucket.org/GoD_Tony/updater/get/v1.2.2.tar.gz
    tar -xzvf v1.2.2.tar.gz -C "${script_dir}" --strip-components 1
    rm v1.2.2.tar.gz
    # compile_plugin updater.sp
    cd "${smx_dir}"
    wget -O updater.smx https://bitbucket.org/GoD_Tony/updater/downloads/updater.smx
}

plugin_logstf() {
    cd "${smx_dir}"
    wget http://sourcemod.krus.dk/logstf.zip
    unzip logstf.zip
    chmod 740 logstf.smx
    rm logstf.zip
}

tf2-comp-fixes() {
    # https://github.com/ldesgoui/tf2-comp-fixes
    cd "${tf_home}"
    wget https://github.com/ldesgoui/tf2-comp-fixes/releases/download/v1.8.0/tf2-comp-fixes.zip
    unzip -o tf2-comp-fixes.zip
    rm tf2-comp-fixes.zip
    compile_plugin tf2-comp-fixes.sp
}

f2-plugins-updated() {
    # https://github.com/stephanieLGBT/f2-plugins-updated
    # Does not install/compile STV related plugins
    cd "${tf_home}"
    wget https://github.com/stephanieLGBT/f2-plugins-updated/archive/master.zip
    unzip -o master.zip
    rm master.zip
    # Copy includes needed for compilation
    cp -rv f2-plugins-updated-master/scripting/include/* "${script_dir}"/include/
    cp -rv f2-plugins-updated-master/extensions/* "${ext_dir}"
    # Download smlib
    wget -O "${script_dir}"/include/smlib.inc https://raw.githubusercontent.com/bcserv/smlib/master/scripting/include/smlib.inc
    declare -a f2_plugins
    mapfile -t f2_plugins < <(find f2-plugins-updated-master -type f -name "*.sp" ! -name "*stv*" -exec basename {} \;)
    find f2-plugins-updated-master -type f -name "*.sp" ! -name "*stv*" -exec mv {} "${script_dir}" \;
    for plugin in "${f2_plugins[@]}"; do
        compile_plugin "${plugin}" || true
    done
    rm -rf f2-plugins-updated-master
}

plugin_pause() {
    # https://www.reddit.com/r/truetf2/comments/9us0yi/updated_pause_plugin_from_rglgg_to_fix_medics/
    cd "${tf_home}"
    wget -O pause.sp https://cdn.discordapp.com/attachments/326573943555096576/509457006462238731/pause.sp
    mv pause.sp "${script_dir}"
    compile_plugin pause.sp
    # wget -O pause.smx https://cdn.discordapp.com/attachments/480167194987331584/508842853389041665/pause.smx
    # mv pause.smx "${smx_dir}"
}

plugin_swapteam() {
    # https://forums.alliedmods.net/showthread.php?t=95968
    cd "${tf_home}"
    curl "https://forums.alliedmods.net/attachment.php?attachmentid=110181&d=1348956706" --output swapteam.zip
    unzip -o swapteam.zip
    mv sourcemod/scripting/swapteam.sp "${script_dir}"
    # mv sourcemod/plugins/swapteam.smx "${smx_dir}"
    rm swapteam.zip
    rm -rf sourcemod/
    compile_plugin swapteam.sp
}

plugin_afk() {
    # https://www.teamfortress.tv/13598/medicstats-sourcemod-plugin/
    cd "${tf_home}"
    wget http://sourcemod.krus.dk/afk.zip
    unzip -o afk.zip
    mv afk.smx "${smx_dir}"
    chmod 740 "${smx_dir}"/afk.smx
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
    to_disable=( funcommands.smx  nextmap.smx funvotes.smx curl_self_test.smx )
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
    ext_dir="${tf_home}/addons/sourcemod/extensions"

    _debug "${FUNCNAME[0]}" "Installing DHooks from https://github.com/peace-maker/DHooks2/releases"
    extension_dhooks
    _continue

    _debug "${FUNCNAME[0]}" "Installing Updater from https://forums.alliedmods.net/showthread.php?t=169095"
    plugin_updater
    _continue

    _debug "${FUNCNAME[0]}" "Installing tf2-comp-fixes from https://github.com/ldesgoui/tf2-comp-fixes"
    tf2-comp-fixes
    _continue

    _debug "${FUNCNAME[0]}" "Installing f2-plugins-updated from https://github.com/stephanieLGBT/f2-plugins-updated"
    f2-plugins-updated
    _continue

    _debug "${FUNCNAME[0]}" "Installing logstf.smx"
    plugin_logstf
    _continue

    _debug "${FUNCNAME[0]}" "Installing pause.smx"
    plugin_pause
    _continue

    _debug "${FUNCNAME[0]}" "Installing swapteam.smx"
    plugin_swapteam
    _continue

    _debug "${FUNCNAME[0]}" "Installing afk.smx"
    plugin_afk
    _continue

    _debug "${FUNCNAME[0]}" "Disabling listed plugins"
    disable_plugins || true
    _continue
}

main "${@}"