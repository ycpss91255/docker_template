#!/usr/bin/env bash

function main() {
    local -r _username="${1:-"$USER"}"
    local -r _rpm_url="https://github.com/tmux-plugins/tpm"
    local -r _tpm_dir="${HOME}/.tmux/plugins/tpm"
    local -r _tmux_conf="${HOME}/.config/tmux/tmux.conf"
    local -r _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

    git clone --depth 1 "${_rpm_url}" "${_tpm_dir}" && \
    mkdir -p "${_tmux_conf%/*}" && \
    cp -f "${_script_path}/tmux.conf" "${_tmux_conf}"
    "${_tpm_dir}"/scripts/install_plugins.sh
}

main
