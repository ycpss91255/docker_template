#!/usr/bin/env bash

FILE_DIR=$(dirname "$(readlink -f "${0}")")
USER_NAME=${1:-"$USER"}

# download tmux plugin manager
# copy and modify tmux config file
git clone --depth 1 https://github.com/tmux-plugins/tpm /home/"${USER_NAME}"/.tmux/plugins/tpm \
&& sed "s|~|/home/${USER_NAME}|g" "${FILE_DIR}"/tmux.conf > /home/"${USER_NAME}"/.tmux.conf \
&& /home/"${USER_NAME}"/.tmux/plugins/tpm/scripts/install_plugins.sh
