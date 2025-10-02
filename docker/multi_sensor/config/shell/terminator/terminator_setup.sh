#!/usr/bin/env bash

function main() {
    local -r _username="${1:-"$USER"}"
    local -r _usergroup="${2:-"$(id -gn "${_username}")"}"
    local -r _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

    mkdir -p /home/"${_username}"/.config/terminator
    cp -r "${_script_path}"/config /home/"${_username}"/.config/terminator/config
    chown -R "${_username}":"${_usergroup}" /home/"${_username}"/.config/terminator
}

main
