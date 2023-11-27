#!/usr/bin/env bash

# Get dependent parameters
source "$(dirname "$(readlink -f "${0}")")/get_param.sh"

docker run --rm \
    --network=host \
    --ipc=host \
    ${GPU_FLAG} \
    -v /tmp/.Xauthority:/home/"${user}"/.Xauthority \
    -e XAUTHORITY=/home/"${user}"/.Xauthority \
    -e DISPLAY="${DISPLAY}" \
    -e QT_X11_NO_MITSHM=1 \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v /etc/timezone:/etc/timezone:ro \
    -v /etc/localtime:/etc/localtime:ro \
    -v "${WS_PATH}":/home/"${user}"/work \
    --device /dev/video0:/dev/video0 \
    --device /dev/video1:/dev/video1 \
    -it --name "${CONTAINER}" "${DOCKER_HUB_USER}"/"${IMAGE}"

    # --privileged \
    # -v /dev:/dev \
    # todo: use --device chang -v /dev:/dev
    # --device using third(other) options

