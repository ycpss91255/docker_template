#!/usr/bin/env bash

# Get dependent parameters
FILE_PATH="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

source "${FILE_PATH}/get_param.sh"

if [ -z "${SSH_CONNECTION}" ]; then
    xhost "+SI:localuser:${user}" >/dev/null
    # xhost "+SI:localuser:root" >/dev/null
    # xhost +local:root
fi

XSOCK="/tmp/.X11-unix"
XAUTH="/tmp/.docker.xauth"

rm -f "${XAUTH}" && touch "${XAUTH}" && chmod 600 "${XAUTH}"

if command -v xauth >/dev/null 2>&1; then
  xauth nlist "$DISPLAY" | sed -e 's/^..../ffff/' | xauth -f "$XAUTH" nmerge - >/dev/null 2>&1 || true
else
  echo "xauth not found on remote host. Install it: sudo apt-get update && sudo apt-get install -y xauth"
fi

if ! xauth -f "$XAUTH" list | grep -q . ; then
  echo "WARN: no Xauthority cookie exported for DISPLAY=$DISPLAY; GUI apps may fail."
fi

docker run --rm \
    --privileged \
    --network=host \
    --ipc=host \
    --gpus all \
    -e DISPLAY="${DISPLAY}" \
    -e XAUTHORITY="${XAUTH}" \
    -e QT_X11_NO_MITSHM=1 \
    -v "${XSOCK}":"/tmp/.X11-unix:rw" \
    -v "${XAUTH}":"${XAUTH}:ro" \
    -v /dev:/dev \
    -v "${ws_path}":"/home/${user}/work" \
    -it --name "${container}" "${docker_hub_user}"/"${image}"

rm -f "${XAUTH}"

if [ -z "${SSH_CONNECTION}" ]; then
    xhost "-SI:localuser:${user}" >/dev/null
fi

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
