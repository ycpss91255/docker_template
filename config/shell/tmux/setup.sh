#!/usr/bin/env bash

set -x -eu -o pipefail

function check_deps() {
    local -r _deps=("tmux" "git")
    local _dep=""

    for _dep in "${_deps[@]}"; do
        if ! command -v "${_dep}" &> /dev/null; then
            printf "Error: %s is not installed." "${_dep}" >&2
            return 1
        fi
    done
    return 0
}

function main() {
    local -r _rpm_url="https://github.com/tmux-plugins/tpm"
    local -r _tpm_dir="${HOME}/.tmux/plugins/tpm"
    local -r _tmux_conf="${HOME}/.config/tmux/tmux.conf"
    local -r _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

    export TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins"

    rm -rf -- "${_tpm_dir}"
    git clone --depth 1 "${_rpm_url}" "${_tpm_dir}"

    mkdir -p -- "${_tmux_conf%/*}"
    cp -f "${_script_path}/tmux.conf" "${_tmux_conf}"
    "${_tpm_dir}/scripts/install_plugins.sh"
}

if check_deps; then
    main
else
    printf "Error: Missing dependencies." >&2
    exit 1
fi
