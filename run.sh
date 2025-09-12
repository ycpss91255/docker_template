#!/usr/bin/env bash

# Get dependent parameters
# TODO: update get_param.sh
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

xhost +SI:localuser:${user} >/dev/null
# xhost +local:root

docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -e DISPLAY="${DISPLAY}" \
    -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
    -v /dev:/dev \
    -v "${WS_PATH}":/home/"${user}"/work \
    -it --name "${CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"

# TODO: Replace -v /dev:/dev with --device=host_device:/container_device

    # -v /etc/timezone:/etc/timezone:ro \
    # -v /etc/localtime:/etc/localtime:ro \
