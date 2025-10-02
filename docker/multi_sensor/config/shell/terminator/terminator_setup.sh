#!/usr/bin/env bash

set -eux -o pipefail

function check_deps() {
    local -r _deps=("terminator")
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
    local -r _username="${1:-"$USER"}"
    local -r _usergroup="${2:-"$(id -gn "${_username}")"}"
    local -r _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

    mkdir -p -- "${HOME}/.config/terminator"
    cp -r "${_script_path}/config" "${HOME}/.config/terminator/config"
    chown -R "${_username}":"${_usergroup}" "${HOME}/.config/terminator"
}

if check_deps; then
    main
else
    printf "Error: Missing dependencies." >&2
    exit 1
fi
