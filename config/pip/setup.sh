#!/usr/bin/env bash

set -eux -o pipefail

file_dir=$(dirname "$(readlink -f "${0}")")

export PIP_BREAK_SYSTEM_PACKAGES=1

# python3 -m pip install --break-system-packages -r ./pip/requirements.txt
pip install -r "${file_dir}"/requirements.txt
