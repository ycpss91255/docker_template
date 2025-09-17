#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck disable=SC1091
source "${FILE_PATH}/get_param.sh"


# shellcheck disable=SC2154
xhost "+SI:localuser:${user}" >/dev/null
# xhost +local:root

# shellcheck disable=SC2154
# shellcheck disable=SC2086
docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    ${gpu_flag} \
    -e DISPLAY="${DISPLAY}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v /dev:/dev \
    -v "${ws_path}":"/home/${user}/work" \
    -it --name "${container}" "${docker_hub_user}"/"${image}"

# docker run --rm \
#     --privileged \
#     --network=host \
#     --ipc=host \
#     ${GPU_FLAG} \
#     -v /tmp/.Xauthority:/home/"${user}"/.Xauthority \
#     -e XAUTHORITY=/home/"${user}"/.Xauthority \
#     -e DISPLAY="${DISPLAY}" \
#     -e QT_X11_NO_MITSHM=1 \
#     -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
#     -v /etc/timezone:/etc/timezone:ro \
#     -v /etc/localtime:/etc/localtime:ro \
#     -v /dev:/dev \
#     -v "${WS_PATH}":/home/"${user}"/work \
#     -it --name "${CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"
