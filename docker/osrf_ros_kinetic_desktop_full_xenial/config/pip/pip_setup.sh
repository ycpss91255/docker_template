#!/usr/bin/env bash

set -eux -o pipefail

function main() {
    local -r _script_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    local -ar _pip_cmd=(python -m pip)
    # local -ar _pip_cmd=(python3 -m pip)

    # ${_pip_cmd[@]} install --upgrade --force-reinstall pip
    ${_pip_cmd[@]} install -r "${_script_path}/requirements.txt"
}

main
